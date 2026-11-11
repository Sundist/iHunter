import SwiftUI

struct ToolFeasibility: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let status: Status
    let note: String

    enum Status: String {
        case native = "Cihazda var"
        case remote = "Uzaktan (SSH)"
        case impossible = "iOS'ta imkânsız"
        var color: Color {
            switch self {
            case .native: return Theme.accent
            case .remote: return Theme.info
            case .impossible: return Theme.danger
            }
        }
    }
}

struct ReferenceView: View {
    private let tools: [ToolFeasibility] = [
        .init(name: "nmap (port/servis tarama)", category: "Keşif", status: .native,
              note: "TCP connect taraması bu uygulamada çalışır (Host/Port Tarayıcı). SYN/UDP/OS taraması root ister → iOS'ta yok."),
        .init(name: "DNS / whois / banner grab", category: "Keşif", status: .native,
              note: "DNS Çözümleyici ve banner okuma cihazda çalışır."),
        .init(name: "TLS/SSL analizi (testssl)", category: "Keşif", status: .native,
              note: "TLS/Sertifika ekranı sertifika zincirini ve güveni gösterir."),
        .init(name: "OpenVAS / Nessus (zafiyet tarama)", category: "Zafiyet", status: .native,
              note: "Tam motor iOS'a kurulamaz; ancak 'Zafiyet Analizi' ekranı cihazda servis/banner tespiti, yanlış yapılandırma kuralları ve NVD CVE sorgusu yapar. Tam tarama için Kali'de OpenVAS çalıştırın."),
        .init(name: "Burp Suite / Caido (proxy)", category: "Web", status: .native,
              note: "Sistem çapında MITM iOS'ta mümkün değil; ama 'HTTP Repeater' ekranı elle istek oluşturup yanıtı incelemenizi sağlar (Burp'ün Repeater kısmı). Tam proxy için masaüstü aracı uzaktan kullanın."),
        .init(name: "sqlmap (SQLi)", category: "Web", status: .remote,
              note: "Python aracı. Stok iOS'ta çalışmaz. Kali kutusunda çalıştırın."),
        .init(name: "Metasploit (exploit framework)", category: "Sömürü", status: .remote,
              note: "iOS'a kurulamaz (Ruby + raw socket + root). Yalnızca yetkili testlerde, kontrol ettiğiniz bir Kali kutusunda kullanın."),
        .init(name: "aircrack-ng / airmon-ng", category: "Kablosuz", status: .impossible,
              note: "Monitor mode + 802.11 paket enjeksiyonu gerektirir. iOS Wi-Fi radyosuna bu erişimi VERMEZ — jailbreak'te bile pratikte yok. Harici bir Linux + uyumlu Wi-Fi adaptörü şart."),
        .init(name: "Kablosuz saldırı (deauth, WPA)", category: "Kablosuz", status: .impossible,
              note: "Aynı donanım sınırı. iPhone bir saldırı platformu olamaz; ancak uzaktaki bir araca terminal olabilir.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Gerçekçi mimari", systemImage: "lightbulb.fill").foregroundStyle(Theme.warning)
                            .font(.subheadline.weight(.semibold))
                        Text("iPhone, NetHunter'ı barındıramaz. Doğru desen: hafif keşfi cihazda yapın, ağır işleri (zafiyet tarama, sömürü, kablosuz) kontrol ettiğiniz bir Kali kutusunda çalıştırıp iPhone'dan SSH ile sürün.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                ForEach(groupedCategories, id: \.self) { category in
                    Panel {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(category).font(.headline).foregroundStyle(Theme.accent)
                            ForEach(tools.filter { $0.category == category }) { tool in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(tool.name).font(.subheadline.weight(.medium)).foregroundStyle(.white)
                                        Spacer()
                                        TagLabel(text: tool.status.rawValue, color: tool.status.color)
                                    }
                                    Text(tool.note).font(.caption).foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Yetkili test hatırlatması", systemImage: "checkmark.shield.fill")
                            .foregroundStyle(Theme.accent).font(.subheadline.weight(.semibold))
                        Text("Yukarıdaki araçları yalnızca yazılı izniniz olan sistemlerde kullanın. CTF, lab, kendi altyapınız veya sözleşmeli pentest kapsamı dışında kullanım yasa dışıdır.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private var groupedCategories: [String] {
        var seen: [String] = []
        for t in tools where !seen.contains(t.category) { seen.append(t.category) }
        return seen
    }
}
