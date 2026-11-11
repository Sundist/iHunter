# iHunter

A security & network recon toolkit for iPhone (iOS). Inspired by Kali **NetHunter**,
but running within what iOS allows — **no root/jailbreak required**.

> ⚠️ **Legal notice:** This app is for **authorized security testing, education, and CTF**
> only. Use the tools only on systems you own or have written permission to test.
> Unauthorized scanning/access is a crime in many jurisdictions.

## Why can't NetHunter be ported to iPhone 1:1?

Kali NetHunter is an **Android** platform and depends on: root, custom kernels,
Wi-Fi monitor mode + packet injection, USB HID gadget mode, raw sockets. iOS is a
closed sandbox and allows none of these. The Apple App Store also won't accept tools
of this kind. So "port NetHunter to iOS" is technically impossible.

Instead, iHunter provides recon/analysis tools that **actually work** on iOS, and
points at the right pattern for the heavy work: *driving a remote Kali box from the iPhone.*

## On-device tools

| Tool | Description |
|------|-------------|
| Network Panel | Interface/IP info via `getifaddrs`, suggested scan range |
| Host Scanner | Live-host discovery on the local subnet (concurrent TCP connect probes) |
| Port Scanner | Common ports or a port range (TCP connect, `Network.framework`) |
| Vuln Insight | Service/banner + version detection, misconfiguration rules, NVD CVE lookup |
| Injection Tester | Non-destructive SQLi/XSS **detection** on authorized targets |
| HTTP Repeater | Craft a request and inspect the response (Burp's Repeater part) |
| DNS Resolver | A/AAAA + reverse DNS (PTR) via `getaddrinfo` |
| HTTP Header Inspector | Security-header analysis (HSTS, CSP, X-Frame-Options, info disclosure) |
| TLS / Certificate | TLS connection, certificate chain, and trust evaluation |
| Subnet Calculator | CIDR / subnet math |
| Crypto & Encoding | MD5/SHA1/256/512, Base64, Hex, URL, password entropy |
| Reference | Tool feasibility matrix + authorized-testing guide |

> Note: SYN/UDP/OS scans (`nmap -sS/-sU/-O`) need root → not possible on iOS.
> iHunter does TCP connect scanning, which is the only real vector in the sandbox.

## Requests that are NOT possible on iOS (honest assessment)

| Requested | Status | Why |
|-----------|--------|-----|
| OpenVAS / Nessus (full engine) | ❌ can't install | Server-based scanner; run on a Kali box and manage over SSH. iHunter ships a lightweight *detection* subset (Vuln Insight). |
| Burp Suite / Caido (system proxy) | ❌ no system MITM | iOS sandbox forbids intercepting other apps. iHunter ships the Repeater subset. |
| sqlmap (automated exploitation) | ❌ no DB dumping | Python tool. iHunter does SQLi/XSS *detection* only; run sqlmap on a Kali box. |
| Metasploit | ❌ can't install | Ruby + raw sockets + root; only on a Kali box you control. |
| aircrack-ng / airmon-ng | ❌ impossible | iOS Wi-Fi radio never opens for monitor mode / injection (not even jailbroken). |

## Realistic architecture: make the iPhone a "control terminal"

What pentesters actually do with an iPhone:

1. Stand up a **Kali Linux box** you control (cloud droplet, Raspberry Pi,
   home lab, or rooted Android + NetHunter).
2. Connect from the iPhone with an **SSH client** (e.g. Termius, Blink Shell).
3. Run the heavy tools (nmap, OpenVAS, sqlmap, Metasploit, aircrack-ng) **there**.
4. Do lightweight recon (host/port/DNS/TLS/headers) **on device** with iHunter.

## Build

- **Required:** macOS + Xcode 16+ (uses file-system synchronized groups).
- A free Apple Developer account is enough to install it on your own iPhone.

```bash
open iHunter.xcodeproj
```

In Xcode: Target → Signing & Capabilities → select your own *Team*, make the Bundle
Identifier unique (`com.ihunter.toolkit` → your own), then pick your phone and **Run** (⌘R).

> On the first scan iOS asks for "Local Network" permission — tap **Allow** so scanning works.

## Structure

```
iHunter/
├── iHunterApp.swift        # @main
├── ContentView.swift       # tool menu
├── Theme.swift             # dark "terminal" theme
├── Services/               # network engine (TCP probe, DNS, TLS, HTTP, crypto)
└── Views/                  # one screen per tool
```
