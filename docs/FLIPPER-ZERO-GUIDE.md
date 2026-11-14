# Flipper Zero — Step-by-Step Guide (station module)

The Flipper is the **physical / RF module** of the station: RFID, NFC, Sub-GHz,
infrared, iButton, GPIO and BadUSB. It pairs with the **iPhone** over Bluetooth
and with the **Pi** over USB serial.

> **Authorized use only.** Read, save, emulate and replay only **your own** cards,
> fobs, remotes and devices, or targets in a written-scope engagement. Cloning
> someone else's access credential or jamming/replaying others' signals is illegal.
> Many Sub-GHz transmits are region-restricted — stay within your local RF law.

Legend: 📱 = iPhone · 🍓 = Pi (USB serial) · 💻 = desktop (qFlipper)

---

## PHASE F1 — First boot & firmware
**F1.1** Charge the Flipper; on first boot set date/time.
**F1.2** 💻 Install **qFlipper** (desktop) — the easiest updater — or update over the 📱 app.
**F1.3** Update firmware. Options:
- **Official** (stable, safest, region-locked Sub-GHz).
- **Community** (Unleashed / RogueMaster / Momentum) — unlocks region-free Sub-GHz and extra apps. Flash at your own risk and within the law.
**F1.4** Insert a microSD (formatted FAT32) — stores dumps, IR libraries, apps.

✅ **Check:** Flipper shows a firmware version and mounts the SD.

## PHASE F2 — Pair with the iPhone (BLE)
**F2.1** 📱 Install the official **Flipper** app (App Store).
**F2.2** On the Flipper: Settings → Bluetooth → ensure it's on.
**F2.3** 📱 Open the app → Add device → pair → verify the code.
**F2.4** 📱 From the app you can: browse/transfer files, use the remote, update firmware, run apps.

✅ **Check:** the app shows battery + firmware and the screen mirrors/controls.

## PHASE F3 — Drive it from the Pi (USB serial)
**F3.1** 🍓 Connect Flipper ↔ Pi with USB-C. Find the port:
```bash
ls /dev/ttyACM*
```
**F3.2** 🍓 Open the Flipper CLI:
```bash
sudo apt install -y screen && sudo screen /dev/ttyACM0 230400
```
(Type `help` for commands; exit `screen` with `Ctrl-A` then `K`.)
**F3.3** 🍓 Scriptable tooling (optional): the `flipperzero-protobuf` / `pyflipper` Python libs let the Pi automate the Flipper over serial.

✅ **Check:** the CLI prompt responds to `help` and `device_info`.

---

## Modules — what each does (own devices / authorized scope)

### Sub-GHz (300–928 MHz)
- **Read → Save → Emulate** your own remotes (garage, gate, some car fobs).
- **Frequency Analyzer** finds a remote's frequency.
- ⚠️ **Rolling codes** (KeeLoq, most modern cars) can't be simply replayed — fixed-code devices can. This is by design; don't expect to replay secure fobs.

### 125 kHz RFID (EM4100, HID Prox, Indala)
- **Read → Save → Emulate** your own access fobs.
- **Write** to a blank **T5577** card to make a working copy of your own fob.

### NFC 13.56 MHz
- Read/emulate **MIFARE Classic/Ultralight**, NTAG, bank-card UID (read-only info).
- MIFARE Classic sectors need keys; the Flipper has a dictionary + `mfkey32` flow to recover keys **from your own reader interactions**.

### iButton (Dallas)
- Read/save/emulate 1-Wire keys (your own).

### Infrared
- **Universal remote** (TVs/ACs) + **learn → replay** any IR remote you own.

### GPIO / hardware
- UART bridge, SPI/I²C, logic-level pins for hardware hacking and connecting to the Pi; can act as a USB-UART adapter.

### BadUSB
- Runs Rubber-Ducky-style HID scripts. Use **only on machines you own/are authorized to test** — it types keystrokes as a trusted keyboard. Great for testing your own endpoint's USB policy.

### U2F / Bluetooth
- Acts as a U2F security key; BLE remote for presentations, etc.

---

## PHASE F4 — Optional Wi-Fi add-on (ESP32)
**F4.1** Attach an **ESP32 Wi-Fi Dev Board** to the Flipper's GPIO.
**F4.2** Flash **Marauder** (or Black Magic) to the ESP32.
**F4.3** 2.4 GHz only: probe/beacon sniffing, handshake capture, deauth (authorized).
⚠️ Limited vs. the Alfa — the **Alfa on the Pi stays your real Wi-Fi tool**; the ESP32 is a convenience.

✅ **Check:** the Flipper's WiFi app lists the ESP32 and scans 2.4 GHz APs.

---

## PHASE F5 — Role in the station workflow
- 📱 **iPhone (Flipper app)** → field control: read/replay your own IR/Sub-GHz/RFID on the move.
- 🍓 **Pi (serial/qFlipper)** → bulk management: back up dumps to the Pi, script captures, store IR/RFID libraries on the Pi.
- The Flipper covers the **physical layer** of a pentest (badges, remotes, USB, IR); the **Pi+Alfa** cover the network/Wi-Fi layer; **iHunter** covers on-device recon.

### Practice ideas (your own gear)
- Clone your **own** office/home RFID fob onto a T5577 and test the copy on your own reader.
- Learn your **own** TV/AC IR remote and rebuild it as a universal remote.
- Save and replay your **own** fixed-code garage remote; observe that your rolling-code fob can't be replayed (why that matters).
- Write a BadUSB script that opens a terminal on **your own** laptop to test USB lockdown.

### Golden rules
- Own devices / written scope only. · Mind regional RF transmit law. · Rolling codes ≠ replayable. · Back up dumps to the Pi; keep the SD tidy.
