import SwiftUI

struct ToolFeasibility: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let status: Status
    let note: String

    enum Status: String {
        case native = "On device"
        case remote = "Remote (SSH)"
        case impossible = "Impossible on iOS"
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
        .init(name: "nmap (port/service scan)", category: "Recon", status: .native,
              note: "TCP connect scanning works in this app (Host/Port Scanner). SYN/UDP/OS scans need root → not available on iOS."),
        .init(name: "DNS / whois / banner grab", category: "Recon", status: .native,
              note: "DNS Resolver and banner reading run on device."),
        .init(name: "TLS/SSL analysis (testssl)", category: "Recon", status: .native,
              note: "The TLS/Certificate screen shows the certificate chain and trust result."),
        .init(name: "OpenVAS / Nessus (vuln scan)", category: "Vulnerability", status: .native,
              note: "The full engine can't be installed on iOS, but the Vuln Insight screen does on-device service/banner detection, misconfiguration rules, and NVD CVE lookup. For a full scan, run OpenVAS on a Kali box."),
        .init(name: "sqlmap (SQLi)", category: "Web", status: .native,
              note: "The Injection Tester does non-destructive SQLi/XSS *detection* on authorized targets. Automated DB dumping/exploitation is out of scope — run sqlmap on a Kali box."),
        .init(name: "Burp Suite / Caido (proxy)", category: "Web", status: .native,
              note: "System-wide MITM isn't possible on iOS, but the HTTP Repeater lets you craft a request and inspect the response (Burp's Repeater part). For a full proxy, use the desktop tool remotely."),
        .init(name: "Metasploit (exploit framework)", category: "Exploitation", status: .remote,
              note: "Can't be installed on iOS (Ruby + raw sockets + root). Use only on a Kali box you control, for authorized tests."),
        .init(name: "aircrack-ng / airmon-ng", category: "Wireless", status: .impossible,
              note: "Requires monitor mode + 802.11 packet injection. iOS does NOT grant this access to the Wi-Fi radio — not even with a jailbreak in practice. A separate Linux box + compatible Wi-Fi adapter is required."),
        .init(name: "Wireless attacks (deauth, WPA)", category: "Wireless", status: .impossible,
              note: "Same hardware limit. iPhone can't be an attack platform here; it can only be a terminal to a remote tool.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Realistic architecture", systemImage: "lightbulb.fill").foregroundStyle(Theme.warning)
                            .font(.subheadline.weight(.semibold))
                        Text("iPhone can't host NetHunter. The right pattern: do lightweight recon on device, and run the heavy work (vuln scanning, exploitation, wireless) on a Kali box you control, driven from the iPhone over SSH.")
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
                        Label("Authorized-testing reminder", systemImage: "checkmark.shield.fill")
                            .foregroundStyle(Theme.accent).font(.subheadline.weight(.semibold))
                        Text("Use the tools above only on systems you have written permission to test. Any use outside a CTF, lab, your own infrastructure, or a contracted pentest scope is illegal.")
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
