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
        Tool(name: "Network Panel", subtitle: "Device and local network info", systemImage: "wifi", color: Theme.info, destination: AnyView(DashboardView())),
        Tool(name: "Host Scanner", subtitle: "Discover live devices on the LAN", systemImage: "dot.radiowaves.left.and.right", color: Theme.accent, destination: AnyView(HostScannerView())),
        Tool(name: "Port Scanner", subtitle: "TCP open-port scan", systemImage: "lock.open", color: Theme.warning, destination: AnyView(PortScannerView())),
        Tool(name: "Vuln Insight", subtitle: "Service/banner + misconfig + CVE", systemImage: "ladybug", color: Theme.danger, destination: AnyView(VulnInsightView())),
        Tool(name: "Injection Tester", subtitle: "SQLi / XSS detection (authorized)", systemImage: "syringe", color: Theme.danger, destination: AnyView(InjectionTesterView())),
        Tool(name: "HTTP Repeater", subtitle: "Craft & inspect requests (Burp-lite)", systemImage: "paperplane", color: Theme.warning, destination: AnyView(RepeaterView())),
        Tool(name: "DNS Resolver", subtitle: "A/AAAA and reverse DNS", systemImage: "globe", color: Theme.info, destination: AnyView(DNSView())),
        Tool(name: "HTTP Header Inspector", subtitle: "Security-header analysis", systemImage: "doc.text.magnifyingglass", color: Theme.accent, destination: AnyView(HTTPHeaderView())),
        Tool(name: "TLS / Certificate", subtitle: "Certificate chain inspection", systemImage: "checkmark.seal", color: Theme.info, destination: AnyView(TLSView())),
        Tool(name: "Subnet Calculator", subtitle: "CIDR / subnet math", systemImage: "square.grid.3x3", color: Theme.warning, destination: AnyView(SubnetView())),
        Tool(name: "Crypto & Encoding", subtitle: "Hash, Base64, Hex, URL", systemImage: "number", color: Theme.accent, destination: AnyView(CryptoView())),
        Tool(name: "Reference Library", subtitle: "Pentest tool feasibility & cheatsheet", systemImage: "books.vertical", color: Theme.info, destination: AnyView(ReferenceView()))
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
                    Text("Authorized use only")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Use these tools only on systems you own or have written permission to test. Unauthorized scanning is a crime in many jurisdictions.")
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
