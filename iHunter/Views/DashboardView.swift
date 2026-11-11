import SwiftUI

struct DashboardView: View {
    @State private var interfaces: [InterfaceAddress] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let primary = NetworkInfo.primaryWiFiIPv4() {
                    Panel {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Birincil IPv4", systemImage: "antenna.radiowaves.left.and.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.accent)
                            Text(primary.address)
                                .font(.system(.title2, design: .monospaced).weight(.bold))
                                .foregroundStyle(.white)
                            Text("Arayüz: \(primary.name)  ·  Maske: \(primary.netmask)")
                                .font(Theme.monoSmall)
                                .foregroundStyle(.secondary)
                            if let cidr = maskToCIDR(primary.netmask) {
                                Text("Önerilen tarama aralığı: \(primary.address)/\(cidr)")
                                    .font(Theme.monoSmall)
                                    .foregroundStyle(Theme.info)
                            }
                        }
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tüm Arayüzler").font(.headline).foregroundStyle(.white)
                        if interfaces.isEmpty {
                            Text("Arayüz bulunamadı.").font(.footnote).foregroundStyle(.secondary)
                        }
                        ForEach(interfaces) { iface in
                            HStack {
                                TagLabel(text: iface.isIPv4 ? "v4" : "v6", color: iface.isIPv4 ? Theme.accent : Theme.info)
                                Text(iface.name).font(Theme.monoSmall).foregroundStyle(.secondary)
                                Spacer()
                                Text(iface.address).font(Theme.monoSmall).foregroundStyle(.white)
                                    .lineLimit(1).truncationMode(.middle)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear { interfaces = NetworkInfo.addresses() }
    }

    private func maskToCIDR(_ mask: String) -> Int? {
        guard let value = SubnetCalculator.parseIPv4(mask) else { return nil }
        return value.nonzeroBitCount
    }
}
