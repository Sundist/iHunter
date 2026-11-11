import SwiftUI

struct LiveHost: Identifiable {
    let id = UUID()
    let ip: String
    var openPorts: [UInt16]
    var hostname: String?
}

@MainActor
final class HostScannerModel: ObservableObject {
    @Published var subnet: String = ""
    @Published var cidr: Int = 24
    @Published var hosts: [LiveHost] = []
    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var scannedCount = 0
    @Published var totalCount = 0

    private var task: Task<Void, Never>?

    // Ports used purely as liveness probes (fast, commonly open).
    private let probePorts: [UInt16] = [80, 443, 22, 445, 139, 8080, 53, 3389]

    func autofill() {
        if let primary = NetworkInfo.primaryWiFiIPv4() {
            subnet = primary.address
        }
    }

    func start() {
        guard !isScanning else { return }
        let targets = SubnetCalculator.hosts(ip: subnet, cidr: cidr, cap: 512)
        guard !targets.isEmpty else { return }
        hosts = []
        isScanning = true
        progress = 0
        scannedCount = 0
        totalCount = targets.count

        task = Task {
            await withTaskGroup(of: LiveHost?.self) { group in
                let semaphore = AsyncSemaphore(limit: 48)
                for ip in targets {
                    await semaphore.wait()
                    group.addTask { [probePorts] in
                        defer { Task { await semaphore.signal() } }
                        var open: [UInt16] = []
                        for port in probePorts {
                            if await TCPProbe.isOpen(host: ip, port: port, timeout: 0.6) {
                                open.append(port)
                            }
                        }
                        guard !open.isEmpty else { return nil }
                        let name = await DNSResolver.reverse(ip: ip)
                        return LiveHost(ip: ip, openPorts: open, hostname: name)
                    }
                }
                for await result in group {
                    scannedCount += 1
                    progress = totalCount > 0 ? Double(scannedCount) / Double(totalCount) : 0
                    if let host = result {
                        hosts.append(host)
                        hosts.sort { ipLess($0.ip, $1.ip) }
                    }
                }
            }
            isScanning = false
            progress = 1
        }
    }

    func stop() {
        task?.cancel()
        isScanning = false
    }

    private func ipLess(_ a: String, _ b: String) -> Bool {
        (SubnetCalculator.parseIPv4(a) ?? 0) < (SubnetCalculator.parseIPv4(b) ?? 0)
    }
}

struct HostScannerView: View {
    @StateObject private var model = HostScannerModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Target subnet").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        HStack {
                            TextField("192.168.1.0", text: $model.subnet)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numbersAndPunctuation)
                                .autocorrectionDisabled()
                            Text("/ \(model.cidr)").font(Theme.mono).foregroundStyle(Theme.accent)
                        }
                        Stepper("Prefix: /\(model.cidr)", value: $model.cidr, in: 20...30)
                            .font(.footnote)
                        HStack {
                            Button("Use my network") { model.autofill() }
                                .buttonStyle(.bordered)
                            Spacer()
                            if model.isScanning {
                                Button("Stop", role: .destructive) { model.stop() }
                                    .buttonStyle(.borderedProminent)
                            } else {
                                Button("Scan") { model.start() }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(model.subnet.isEmpty)
                            }
                        }
                    }
                }

                if model.isScanning || model.progress > 0 {
                    Panel {
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressView(value: model.progress)
                                .tint(Theme.accent)
                            Text("\(model.scannedCount) / \(model.totalCount) addresses scanned · \(model.hosts.count) live hosts")
                                .font(Theme.monoSmall).foregroundStyle(.secondary)
                        }
                    }
                }

                ForEach(model.hosts) { host in
                    Panel {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "desktopcomputer").foregroundStyle(Theme.accent)
                                Text(host.ip).font(Theme.mono.weight(.bold)).foregroundStyle(.white)
                                Spacer()
                                TagLabel(text: "\(host.openPorts.count) ports", color: Theme.warning)
                            }
                            if let name = host.hostname {
                                Text(name).font(Theme.monoSmall).foregroundStyle(Theme.info)
                            }
                            Text(host.openPorts.map { "\($0)/\(PortCatalog.service(for: $0))" }.joined(separator: "  "))
                                .font(Theme.monoSmall).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}
