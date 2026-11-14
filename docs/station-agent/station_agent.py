#!/usr/bin/env python3
"""
iHunter station agent — a tiny, token-protected HTTP control endpoint for the
Raspberry Pi pentest station. The iHunter "Station Control" panel calls it.

Design & safety:
- Fixed action set (no generic "run any command" endpoint). For an interactive
  shell, use SSH (Termius/Blink) — not this agent.
- Token required on every request (X-Station-Token header).
- Parameterized commands use argument lists (no shell), so inputs can't inject.
- Intended to listen ONLY on the Pi's private hotspot. Do not expose to the internet.
- Authorized use only: your own lab / written-scope engagements.

Env vars:
  STATION_TOKEN  shared secret (REQUIRED; refuses to start with the default)
  STATION_WIFI   Wi-Fi interface for monitor mode (default: wlan1)
  STATION_PORT   listen port (default: 8777)
  STATION_BIND   bind address (default: 0.0.0.0)
"""
import os
import re
import glob
import json
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

TOKEN = os.environ.get("STATION_TOKEN", "change-me")
WIFI = os.environ.get("STATION_WIFI", "wlan1")
PORT = int(os.environ.get("STATION_PORT", "8777"))
BIND = os.environ.get("STATION_BIND", "0.0.0.0")
FLIPPER_DEV = os.environ.get("FLIPPER_DEV", "/dev/ttyACM0")

TARGET_RE = re.compile(r"^[A-Za-z0-9_.:-]{1,255}$")  # host/IP only, no shell metachars
FPATH_RE = re.compile(r"^/[A-Za-z0-9_./-]{0,128}$")   # Flipper storage path


def run(cmd, timeout=25):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return (p.returncode == 0, (p.stdout + p.stderr).strip())
    except Exception as e:  # noqa: BLE001
        return (False, str(e))


def monitor_iface():
    for name in os.listdir("/sys/class/net"):
        ok, out = run(["iw", "dev", name, "info"], timeout=5)
        if ok and "type monitor" in out:
            return name
    cand = WIFI + "mon"
    return cand if os.path.exists("/sys/class/net/" + cand) else None


def status():
    temp = None
    ok, t = run(["cat", "/sys/class/thermal/thermal_zone0/temp"], timeout=5)
    if ok and t.isdigit():
        temp = round(int(t) / 1000.0, 1)
    return {
        "hostname": run(["hostname"], timeout=5)[1],
        "uptime": run(["uptime", "-p"], timeout=5)[1],
        "cpu_temp_c": temp,
        "monitor_iface": monitor_iface(),
        "wifi_iface": WIFI,
    }


def interfaces():
    return {"interfaces": run(["ip", "-br", "addr"])[1]}


def services():
    return {
        "ssh": run(["systemctl", "is-active", "ssh"], timeout=5)[1],
        "monitor_active": monitor_iface() is not None,
    }


def monitor_start():
    run(["airmon-ng", "check", "kill"], timeout=20)
    ok, out = run(["airmon-ng", "start", WIFI], timeout=25)
    return {"ok": ok, "iface": monitor_iface(), "output": out}


def monitor_stop():
    mon = monitor_iface() or (WIFI + "mon")
    ok, out = run(["airmon-ng", "stop", mon], timeout=20)
    return {"ok": ok, "output": out}


def scan_aps(seconds=8):
    mon = monitor_iface()
    if not mon:
        return {"error": "monitor mode not active — start it first"}
    for f in glob.glob("/tmp/ihunter_scan*"):
        try:
            os.remove(f)
        except OSError:
            pass
    run(["timeout", str(seconds), "airodump-ng", "--output-format", "csv",
         "-w", "/tmp/ihunter_scan", mon], timeout=seconds + 10)
    aps = []
    files = glob.glob("/tmp/ihunter_scan*.csv")
    if files:
        with open(files[0], "r", errors="ignore") as fh:
            for line in fh:
                if line.startswith("Station MAC") or line.strip() == "":
                    break
                parts = [c.strip() for c in line.split(",")]
                if len(parts) >= 14 and TARGET_RE.match(parts[0] or ""):
                    aps.append({
                        "bssid": parts[0],
                        "channel": parts[3],
                        "power": parts[8],
                        "essid": parts[13],
                    })
    return {"access_points": aps, "count": len(aps)}


def nmap(target):
    if not TARGET_RE.match(target or ""):
        return {"error": "invalid target"}
    ok, out = run(["nmap", "-sV", "-T4", "--top-ports", "100", target], timeout=120)
    return {"ok": ok, "target": target, "output": out}


def flipper_cmd(cmd, timeout=4):
    """Send one command to the Flipper CLI over USB serial and return output.
    Needs the Flipper connected to the Pi and python3-serial installed."""
    try:
        import serial  # pyserial
    except ImportError:
        return (False, "pyserial missing: sudo apt install -y python3-serial")
    import time
    try:
        ser = serial.Serial(FLIPPER_DEV, 230400, timeout=0.3)
    except Exception as e:  # noqa: BLE001
        return (False, f"cannot open {FLIPPER_DEV}: {e}")
    try:
        ser.reset_input_buffer()
        ser.write((cmd + "\r\n").encode())
        time.sleep(0.2)
        out = b""
        deadline = time.time() + timeout
        while time.time() < deadline:
            chunk = ser.read(512)
            if chunk:
                out += chunk
            elif out:
                break
        text = out.decode(errors="ignore")
        # Drop the echoed command line and the trailing ">" prompt.
        lines = [ln for ln in text.splitlines() if ln.strip() not in ("", ">", cmd)]
        return (True, "\n".join(lines).strip())
    finally:
        ser.close()


def flipper_info():
    ok, out = flipper_cmd("device_info", timeout=4)
    return {"ok": ok, "output": out}


def flipper_battery():
    ok, out = flipper_cmd("power info", timeout=4)
    return {"ok": ok, "output": out}


def flipper_storage(path):
    if not FPATH_RE.match(path or ""):
        return {"error": "invalid path"}
    ok, out = flipper_cmd("storage list " + path, timeout=5)
    return {"ok": ok, "path": path, "output": out}


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, obj):
        body = json.dumps(obj, indent=2).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _authed(self):
        return self.headers.get("X-Station-Token", "") == TOKEN

    def log_message(self, *a):  # quieter logs
        pass

    def do_GET(self):
        if not self._authed():
            return self._send(401, {"error": "bad or missing token"})
        u = urlparse(self.path)
        q = parse_qs(u.query)
        routes = {
            "/status": status,
            "/interfaces": interfaces,
            "/services": services,
            "/scan/aps": scan_aps,
        }
        if u.path == "/nmap":
            return self._send(200, nmap((q.get("target") or [""])[0]))
        if u.path == "/flipper/storage":
            return self._send(200, flipper_storage((q.get("path") or ["/ext"])[0]))
        if u.path == "/flipper/info":
            return self._send(200, flipper_info())
        if u.path == "/flipper/battery":
            return self._send(200, flipper_battery())
        fn = routes.get(u.path)
        return self._send(200, fn()) if fn else self._send(404, {"error": "not found"})

    def do_POST(self):
        if not self._authed():
            return self._send(401, {"error": "bad or missing token"})
        actions = {"/monitor/start": monitor_start, "/monitor/stop": monitor_stop}
        fn = actions.get(urlparse(self.path).path)
        return self._send(200, fn()) if fn else self._send(404, {"error": "not found"})


if __name__ == "__main__":
    if TOKEN == "change-me":
        raise SystemExit("Refusing to start: set STATION_TOKEN to a real secret.")
    print(f"iHunter station agent on {BIND}:{PORT} (wifi={WIFI})")
    ThreadingHTTPServer((BIND, PORT), Handler).serve_forever()
