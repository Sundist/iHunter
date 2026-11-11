# iHunter

iPhone (iOS) için güvenlik & ağ keşif araç seti. Kali **NetHunter**'dan ilham alır,
ancak iOS'un izin verdiği sınırlar içinde — **root/jailbreak gerektirmeden** — çalışır.

> ⚠️ **Yasal uyarı:** Bu uygulama yalnızca **yetkili güvenlik testi, eğitim ve CTF**
> içindir. Araçları yalnızca sahibi olduğunuz veya yazılı izniniz olan sistemlerde kullanın.
> İzinsiz tarama/erişim birçok ülkede suçtur.

## Neden NetHunter birebir iPhone'a taşınamaz?

Kali NetHunter bir **Android** platformudur ve şunlara dayanır: root, özel kernel,
Wi-Fi monitor mode + paket enjeksiyonu, USB HID gadget modu, ham soketler. iOS kapalı
bir sandbox'tır ve bunların hiçbirine izin vermez. Apple App Store da bu tür araçları
kabul etmez. Dolayısıyla "NetHunter'ı iOS'a port et" teknik olarak mümkün değildir.

Bunun yerine iHunter, iOS'ta **gerçekten çalışan** keşif/analiz araçlarını sunar ve
ağır işler için doğru deseni gösterir: *uzaktaki bir Kali kutusunu iPhone'dan sürmek.*

## Cihazda çalışan araçlar

| Araç | Açıklama |
|------|----------|
| Ağ Paneli | `getifaddrs` ile arayüz/IP bilgisi, önerilen tarama aralığı |
| Host Tarayıcı | Yerel alt ağda canlı cihaz keşfi (eşzamanlı TCP connect probe) |
| Port Tarayıcı | Yaygın portlar veya aralık taraması (TCP connect, `Network.framework`) |
| DNS Çözümleyici | `getaddrinfo` ile A/AAAA + ters DNS (PTR) |
| HTTP Başlık Denetçisi | Güvenlik başlığı analizi (HSTS, CSP, X-Frame-Options, bilgi ifşası) |
| TLS / Sertifika | TLS bağlantısı, sertifika zinciri ve güven değerlendirmesi |
| Subnet Hesaplayıcı | CIDR / alt ağ matematiği |
| Kripto & Kodlama | MD5/SHA1/256/512, Base64, Hex, URL, parola entropisi |
| Referans | Araç fizibilite matrisi + yetkili test rehberi |

> Not: SYN/UDP/OS taraması (`nmap -sS/-sU/-O`) root ister → iOS'ta mümkün değil.
> iHunter TCP connect taraması yapar; bu sandbox'taki tek gerçek vektördür.

## iOS'ta mümkün OLMAYAN istekler (dürüst değerlendirme)

| İstenen | Durum | Neden |
|---------|-------|-------|
| OpenVAS / Nessus | ❌ iOS'a kurulamaz | Sunucu tabanlı tarayıcı; uzaktaki Kali'de çalıştırıp SSH ile yönetin |
| Burp Suite / Caido | ❌ sistem MITM yok | iOS sandbox araya girmeye izin vermez; masaüstü proxy'yi uzaktan kullanın |
| sqlmap | ❌ çalışmaz | Python aracı; Kali kutusunda çalıştırın |
| Metasploit | ❌ kurulamaz | Ruby + ham soket + root; yalnızca kontrol ettiğiniz Kali'de |
| aircrack-ng / airmon-ng | ❌ imkânsız | iOS Wi-Fi radyosu monitor mode / enjeksiyona açılmaz (jailbreak'te bile) |

## Gerçekçi mimari: iPhone'u "kontrol terminali" yapın

Pentester'ların iPhone ile gerçekte yaptığı şey:

1. Kontrol ettiğiniz bir **Kali Linux kutusu** kurun (bulut droplet, Raspberry Pi,
   ev lab'ı veya rootlu Android + NetHunter).
2. iPhone'dan bir **SSH istemcisi** (ör. Termius, Blink Shell) ile bağlanın.
3. nmap, OpenVAS, sqlmap, Metasploit, aircrack-ng gibi ağır araçları **orada** çalıştırın.
4. Hafif keşfi (host/port/DNS/TLS/başlık) iHunter ile **cihazda** yapın.

## Derleme

- **Gerekli:** macOS + Xcode 16+ (file-system synchronized groups kullanır).
- Bir iPhone'a kurmak için ücretsiz bir Apple Developer hesabı yeterlidir.

```bash
open iHunter.xcodeproj
```

Xcode'da: Target → Signing & Capabilities → kendi *Team*'inizi seçin, Bundle
Identifier'ı benzersiz yapın (`com.ihunter.toolkit` → kendi adınız), ardından
telefonunuzu seçip **Run** (⌘R).

> İlk taramada iOS "Yerel Ağ" izni ister — tarama için **İzin Ver** deyin.

## Yapı

```
iHunter/
├── iHunterApp.swift        # @main
├── ContentView.swift       # araç menüsü
├── Theme.swift             # koyu "terminal" teması
├── Services/               # ağ motoru (TCP probe, DNS, TLS, HTTP, kripto)
└── Views/                  # her araç için bir ekran
```
