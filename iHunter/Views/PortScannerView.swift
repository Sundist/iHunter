import SwiftUI

struct ScannedPort: Identifiable {
    let id = UUID()
    let port: UInt16
    let service: String
    let open: Bool
}

@MainActor
final class PortScannerModel: ObservableObject {
    @Published var target: String = ""
    @Published var mode: Mode = .common
    @Published var rangeStart: String = "1"
    @Published var rangeEnd: String = "1024"
    @Published var results: [ScannedPort] = []
    @Published var isScanning = false
    @Published var progress: Double = 0

    enum Mode: String, CaseIterable { case common = "Common", range = "Range" }

    private var task: Task<Void, Never>?

    func start() {
        guard !isScanning, !target.isEmpty else { return }
        let ports = targetPorts()
        guard !ports.isEmpty else { return }
        results = []
        isScanning = true
        progress = 0
        let host = target.trimmingCharacters(in: .whitespaces)
        let total = ports.count
        var done = 0

        task = Task {
            await withTaskGroup(of: ScannedPort?.self) { group in
                let semaphore = AsyncSemaphore(limit: 64)
                for port in ports {
                    await semaphore.wait()
                    group.addTask {
                        defer { Task { await semaphore.signal() } }
                        let open = await TCPProbe.isOpen(host: host, port: port, timeout: 0.8)
                        guard open else { return nil }
                        return ScannedPort(port: port, service: PortCatalog.service(for: port), open: true)
                    }
                }
                for await result in group {
                    done += 1
                    progress = Double(done) / Double(total)
                    if let r = result {
                        results.append(r)
                        results.sort { $0.port < $1.port }
                    }
                }
            }
            isScanning = false
            progress = 1
        }
    }

    func stop() { task?.cancel(); isScanning = false }

    private func targetPorts() -> [UInt16] {
        switch mode {
        case .common:
            return PortCatalog.common.map { $0.port }
        case .range:
            guard let s = UInt16(rangeStart), let e = UInt16(rangeEnd), s <= e else { return [] }
            // Cap to keep the sweep responsive on-device (overflow-safe).
            let endInt = min(Int(e), Int(s) + 2000)
            return (Int(s)...endInt).map { UInt16($0) }
        }
    }
}

struct PortScannerView: View {
    @StateObject private var model = PortScannerModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Target host / IP").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        TextField("scanme.nmap.org or 192.168.1.1", text: $model.target)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        Picker("Mode", selection: $model.mode) {
                            ForEach(PortScannerModel.Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)

                        if model.mode == .range {
                            HStack {
                                TextField("Start", text: $model.rangeStart)
                                    .textFieldStyle(.roundedBorder).keyboardType(.numberPad)
                                Text("–").foregroundStyle(.secondary)
                                TextField("End", text: $model.rangeEnd)
                                    .textFieldStyle(.roundedBorder).keyboardType(.numberPad)
                            }
                            Text("Note: the range is capped at 2000 ports for responsiveness.")
                                .font(.caption2).foregroundStyle(.secondary)
                        }

                        HStack {
                            Spacer()
                            if model.isScanning {
                                Button("Stop", role: .destructive) { model.stop() }.buttonStyle(.borderedProminent)
                            } else {
                                Button("Scan") { model.start() }.buttonStyle(.borderedProminent).disabled(model.target.isEmpty)
                            }
                        }
                    }
                }

                if model.isScanning {
                    Panel {
                        ProgressView(value: model.progress).tint(Theme.accent)
                    }
                }

                if !model.results.isEmpty {
                    Panel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Open ports (\(model.results.count))").font(.headline).foregroundStyle(Theme.accent)
                            ForEach(model.results) { p in
                                HStack {
                                    Image(systemName: "lock.open.fill").foregroundStyle(Theme.accent).font(.caption)
                                    Text("\(p.port)").font(Theme.mono.weight(.bold)).foregroundStyle(.white)
                                        .frame(width: 64, alignment: .leading)
                                    Text(p.service).font(Theme.monoSmall).foregroundStyle(.secondary)
                                    Spacer()
                                    TagLabel(text: "open", color: Theme.accent)
                                }
                            }
                        }
                    }
                } else if !model.isScanning && model.progress >= 1 {
                    Panel {
                        Label("No open ports found.", systemImage: "lock.fill")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}
