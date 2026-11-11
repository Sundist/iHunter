# iHunter Station Agent

A tiny token-protected HTTP control endpoint for the Raspberry Pi pentest
station. The iHunter **Station Control** screen calls it to run one-tap actions
(status, monitor mode on/off, AP scan, nmap). For an interactive shell, use SSH.

> Authorized use only — your own lab / written-scope engagements. Run the agent
> **only on the Pi's private hotspot**, never exposed to the internet.

## What it exposes
| Method | Path | Action |
|--------|------|--------|
| GET | `/status` | hostname, uptime, CPU temp, monitor iface |
| GET | `/interfaces` | `ip -br addr` |
| GET | `/services` | ssh active?, monitor active? |
| GET | `/scan/aps` | ~8 s airodump snapshot → AP list |
| GET | `/nmap?target=HOST` | `nmap -sV -T4 --top-ports 100 HOST` |
| POST | `/monitor/start` | `airmon-ng start wlan1` |
| POST | `/monitor/stop` | `airmon-ng stop wlan1mon` |

There is **no** generic command endpoint by design. Inputs are validated and run
without a shell, so they can't inject.

## Install on the Pi
```bash
sudo mkdir -p /opt/ihunter
sudo cp station_agent.py /opt/ihunter/
```
Generate a strong token:
```bash
openssl rand -hex 24
```
Put it in the service file, then install the unit:
```bash
sudo cp ihunter-station.service /etc/systemd/system/
sudo nano /etc/systemd/system/ihunter-station.service   # set STATION_TOKEN
sudo systemctl daemon-reload && sudo systemctl enable --now ihunter-station
```
Check it:
```bash
systemctl status ihunter-station
curl -s -H "X-Station-Token: YOUR_TOKEN" http://127.0.0.1:8777/status
```

## Connect from iHunter
1. Join the Pi's hotspot (`pentest-pi`) from the iPhone.
2. Open iHunter → **Station Control**.
3. Host `10.42.0.1`, Port `8777`, paste the token.
4. Tap **Status** — you should see the Pi's info.

## Requirements on the Pi
`python3` (stdlib only), plus `aircrack-ng` and `nmap` for those actions.
Monitor actions need the Alfa adapter and the RTL8812AU driver (see the main
setup guide, Phase 3).
