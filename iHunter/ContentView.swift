import SwiftUI

struct Tool: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let destination: AnyView
}

struct ContentView: View {
    private let tools: [Tool] = [
        Tool(name: "Ağ Paneli", subtitle: "Cihaz ve yerel ağ bilgisi", systemImage: "wifi", color: Theme.info, destination: AnyView(DashboardView())),
        Tool(name: "Host Tarayıcı", subtitle: "Yerel ağda canlı cihazları keşfet", systemImage: "dot.radiowaves.left.and.right", color: Theme.accent, destination: AnyView(HostScannerView())),
        Tool(name: "Port Tarayıcı", subtitle: "TCP açık port taraması", systemImage: "lock.open", color: Theme.warning, destination: AnyView(PortScannerView())),
        Tool(name: "Zafiyet Analizi", subtitle: "Servis/banner + yanlış yapılandırma + CVE", systemImage: "ladybug", color: Theme.danger, destination: AnyView(VulnInsightView())),
        Tool(name: "HTTP Repeater", subtitle: "Elle istek oluştur & incele (Burp-lite)", systemImage: "paperplane", color: Theme.warning, destination: AnyView(RepeaterView())),
        Tool(name: "DNS Çözümleyici", subtitle: "A/AAAA ve ters DNS", systemImage: "globe", color: Theme.info, destination: AnyView(DNSView())),
        Tool(name: "HTTP Başlık Denetçisi", subtitle: "Güvenlik başlığı analizi", systemImage: "doc.text.magnifyingglass", color: Theme.accent, destination: AnyView(HTTPHeaderView())),
        Tool(name: "TLS / Sertifika", subtitle: "Sertifika zinciri inceleme", systemImage: "checkmark.seal", color: Theme.info, destination: AnyView(TLSView())),
        Tool(name: "Subnet Hesaplayıcı", subtitle: "CIDR / alt ağ matematiği", systemImage: "square.grid.3x3", color: Theme.warning, destination: AnyView(SubnetView())),
        Tool(name: "Kripto & Kodlama", subtitle: "Hash, Base64, Hex, URL", systemImage: "number", color: Theme.accent, destination: AnyView(CryptoView())),
        Tool(name: "Referans Kütüphanesi", subtitle: "Pentest komut/cheatsheet", systemImage: "books.vertical", color: Theme.info, destination: AnyView(ReferenceView()))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ConsentBanner()
                    ForEach(tools) { tool in
                        NavigationLink {
                            tool.destination
                                .navigationTitle(tool.name)
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            ToolRow(tool: tool)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("iHunter")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
    }
}

private struct ToolRow: View {
    let tool: Tool
    var body: some View {
        Panel {
            HStack(spacing: 14) {
                Image(systemName: tool.systemImage)
                    .font(.title2)
                    .foregroundStyle(tool.color)
                    .frame(width: 42, height: 42)
                    .background(tool.color.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(tool.name).font(.headline).foregroundStyle(.white)
                    Text(tool.subtitle).font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
        }
    }
}

private struct ConsentBanner: View {
    var body: some View {
        Panel {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(Theme.warning)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Yalnızca yetkili kullanım")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Bu araçları yalnızca sahibi olduğunuz ya da yazılı izin aldığınız sistemlerde kullanın. İzinsiz tarama birçok ülkede suçtur.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
