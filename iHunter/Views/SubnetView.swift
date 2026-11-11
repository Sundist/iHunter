import SwiftUI

struct SubnetView: View {
    @State private var ip = "192.168.1.10"
    @State private var cidr: Double = 24
    @State private var result: SubnetResult?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("IPv4 address").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        TextField("192.168.1.10", text: $ip)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numbersAndPunctuation)
                            .autocorrectionDisabled()
                        HStack {
                            Text("Prefix").font(.subheadline).foregroundStyle(.white)
                            Spacer()
                            Text("/\(Int(cidr))").font(Theme.mono.weight(.bold)).foregroundStyle(Theme.accent)
                        }
                        Slider(value: $cidr, in: 0...32, step: 1).tint(Theme.accent)
                        Button("Calculate") { compute() }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                    }
                }

                if let r = result {
                    Panel {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Result · /\(r.cidr)").font(.headline).foregroundStyle(Theme.accent)
                            row("Network address", r.network)
                            row("Broadcast", r.broadcast)
                            row("First host", r.firstHost)
                            row("Last host", r.lastHost)
                            row("Subnet mask", r.netmask)
                            row("Wildcard", r.wildcard)
                            row("Usable hosts", "\(r.hostCount)")
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear(perform: compute)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.footnote).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(Theme.monoSmall.weight(.medium)).foregroundStyle(.white).textSelection(.enabled)
        }
    }

    private func compute() {
        result = SubnetCalculator.calculate(ip: ip.trimmingCharacters(in: .whitespaces), cidr: Int(cidr))
    }
}
