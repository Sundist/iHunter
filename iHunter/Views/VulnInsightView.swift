import SwiftUI

@MainActor
final class VulnInsightModel: ObservableObject {
    @Published var target = ""
    @Published var findings: [VulnFinding] = []
    @Published var services: [ServiceObservation] = []
    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var status = ""

    private var task: Task<Void, Never>?

    func start() {
        guard !isScanning, !target.isEmpty else { return }
        let host = target.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        findings = []
        services = []
        isScanning = true
        progress = 0
        status = "Scanning ports and services…"

        task = Task {
            let ports = PortCatalog.common.map { $0.port }
            var observations: [ServiceObservation] = []
            var done = 0

            await withTaskGroup(of: ServiceObservation?.self) { group in
                let sem = AsyncSemaphore(limit: 32)
                for port in ports {
                    await sem.wait()
                    group.addTask {
                        defer { Task { await sem.signal() } }
                        guard await TCPProbe.isOpen(host: host, port: port, timeout: 0.8) else { return nil }
                        let banner = await BannerGrabber.grab(host: host, port: port)
                        return ServiceObservation(port: port, service: PortCatalog.service(for: port), banner: banner)
                    }
                }
                for await obs in group {
                    done += 1
                    progress = Double(done) / Double(ports.count) * 0.85
                    if let obs { observations.append(obs) }
                }
            }
            observations.sort { $0.port < $1.port }
            services = observations

            var httpFindings: [HeaderFinding] = []
            let webPorts: Set<UInt16> = [80, 443, 8080, 8443, 8000, 8888]
            if observations.contains(where: { webPorts.contains($0.port) }) {
                status = "Inspecting HTTP security headers…"
                if let r = try? await HTTPInspector.inspect(urlString: host) {
                    httpFindings = r.findings
                }
            }
            progress = 1
            findings = VulnRules.evaluate(observations: observations, httpFindings: httpFindings)
            status = observations.isEmpty
                ? "No open ports found."
                : "Done · \(observations.count) services, \(findings.count) findings."
            isScanning = false
        }
    }

    func stop() { task?.cancel(); isScanning = false }
}

struct VulnInsightView: View {
    @StateObject private var model = VulnInsightModel()
    @State private var cveKeyword = ""
    @State private var cveResult: CVELookup.Result?
    @State private var cveLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Target host / IP").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        TextField("192.168.1.1 or example.com", text: $model.target)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Text("Scans ports, reads service banners, and flags misconfigurations. It does not exploit — detection and reporting only.")
                            .font(.caption2).foregroundStyle(.secondary)
                        HStack {
                            Spacer()
                            if model.isScanning {
                                Button("Stop", role: .destructive) { model.stop() }.buttonStyle(.borderedProminent)
                            } else {
                                Button("Analyze") { model.start() }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(model.target.isEmpty)
                            }
                        }
                    }
                }

                if model.isScanning || (!model.status.isEmpty && model.progress < 1) {
                    Panel {
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressView(value: model.progress).tint(Theme.accent)
                            Text(model.status).font(Theme.monoSmall).foregroundStyle(.secondary)
                        }
                    }
                }

                if !model.findings.isEmpty {
                    Panel {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Summary").font(.headline).foregroundStyle(.white)
                            HStack(spacing: 8) {
                                severityChip(.high)
                                severityChip(.medium)
                                severityChip(.low)
                                severityChip(.info)
                            }
                        }
                    }

                    ForEach(model.findings) { f in
                        Panel {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    TagLabel(text: f.severity.label, color: severityColor(f.severity))
                                    Text(f.title).font(.subheadline.weight(.medium)).foregroundStyle(.white)
                                    Spacer()
                                }
                                Text(f.detail).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                                if let banner = bannerFor(f), let kw = VulnRules.cveKeyword(from: banner) {
                                    Button {
                                        cveKeyword = kw
                                        runCVE()
                                    } label: {
                                        Label("Search NVD for CVEs: \(kw)", systemImage: "magnifyingglass")
                                            .font(.caption2)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }

                cveSection
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private var cveSection: some View {
        Panel {
            VStack(alignment: .leading, spacing: 10) {
                Text("CVE search (NVD)").font(.headline).foregroundStyle(Theme.info)
                HStack {
                    TextField("e.g. OpenSSH 8.2", text: $cveKeyword)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button(action: runCVE) {
                        if cveLoading { ProgressView() } else { Text("Search") }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(cveKeyword.count < 2 || cveLoading)
                }
                if let result = cveResult {
                    switch result {
                    case .items(let items):
                        ForEach(items) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(item.identifier).font(Theme.monoSmall.weight(.bold)).foregroundStyle(Theme.accent)
                                    Spacer()
                                    if let s = item.score {
                                        TagLabel(text: String(format: "CVSS %.1f", s), color: scoreColor(s))
                                    }
                                }
                                Text(item.summary).font(.caption2).foregroundStyle(.secondary).lineLimit(4)
                            }
                            .padding(.vertical, 2)
                        }
                    case .empty:
                        Text("No matching CVEs found.").font(.caption).foregroundStyle(.secondary)
                    case .failed:
                        Text("Could not reach NVD (rate limit/network). Try again in a few seconds.")
                            .font(.caption).foregroundStyle(Theme.warning)
                    }
                } else {
                    Text("Enter a product/version keyword, or tap the button on a finding.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func runCVE() {
        let kw = cveKeyword
        guard kw.count >= 2 else { return }
        cveLoading = true
        cveResult = nil
        Task {
            let result = await CVELookup.search(keyword: kw)
            await MainActor.run {
                cveResult = result
                cveLoading = false
            }
        }
    }

    private func bannerFor(_ f: VulnFinding) -> String? {
        guard let port = f.port else { return nil }
        return model.services.first(where: { $0.port == port })?.banner
    }

    private func severityChip(_ s: VulnFinding.Severity) -> some View {
        let count = model.findings.filter { $0.severity == s }.count
        return TagLabel(text: "\(s.label) \(count)", color: severityColor(s))
    }

    private func severityColor(_ s: VulnFinding.Severity) -> Color {
        switch s {
        case .high: return Theme.danger
        case .medium: return Theme.warning
        case .low: return Theme.info
        case .info: return .secondary
        }
    }

    private func scoreColor(_ s: Double) -> Color {
        if s >= 7 { return Theme.danger }
        if s >= 4 { return Theme.warning }
        return Theme.info
    }
}
