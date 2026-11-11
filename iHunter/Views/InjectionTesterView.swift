import SwiftUI

@MainActor
final class InjectionTesterModel: ObservableObject {
    @Published var url = ""
    @Published var parameter = ""
    @Published var report: InjectionReport?
    @Published var isWorking = false
    @Published var error: String?

    func run() {
        guard !isWorking, !url.isEmpty, !parameter.isEmpty else { return }
        isWorking = true
        error = nil
        report = nil
        let u = url, p = parameter
        Task {
            let result = await InjectionTester.test(urlString: u, parameter: p)
            await MainActor.run {
                if let result {
                    report = result
                } else {
                    error = "Could not run the probe. Make sure the URL includes the parameter, e.g. https://site/page?id=1 with parameter `id`."
                }
                isWorking = false
            }
        }
    }
}

struct InjectionTesterView: View {
    @StateObject private var model = InjectionTesterModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.shield.fill").foregroundStyle(Theme.danger)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Detection only — authorized targets")
                                .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                            Text("Sends a few read-only probes to tell whether a parameter looks injectable. It does NOT extract data, enumerate the database, or exploit anything. Use only where you have written permission.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Target URL (with query parameter)").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        TextField("https://example.com/item?id=1", text: $model.url)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Text("Parameter to test").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        TextField("id", text: $model.parameter)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        HStack {
                            Spacer()
                            Button(action: model.run) {
                                if model.isWorking { ProgressView() } else { Text("Run detection") }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(model.url.isEmpty || model.parameter.isEmpty || model.isWorking)
                        }
                    }
                }

                if let error = model.error {
                    Panel {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.footnote).foregroundStyle(Theme.danger)
                    }
                }

                if let report = model.report {
                    Panel {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Verdict").font(.headline).foregroundStyle(.white)
                                Spacer()
                                TagLabel(text: report.likelyVulnerable ? "LIKELY INJECTABLE" : "NO SIGNAL",
                                         color: report.likelyVulnerable ? Theme.danger : Theme.accent)
                            }
                            Text("Parameter `\(report.parameter)` · baseline HTTP \(report.baselineStatus)")
                                .font(Theme.monoSmall).foregroundStyle(.secondary)
                        }
                    }

                    ForEach(report.signals) { signal in
                        Panel {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: signal.indicative ? "exclamationmark.octagon.fill" : "checkmark.circle")
                                        .foregroundStyle(signal.indicative ? Theme.danger : Theme.accent)
                                        .font(.caption)
                                    Text(signal.technique).font(.subheadline.weight(.medium)).foregroundStyle(.white)
                                    Spacer()
                                    TagLabel(text: signal.indicative ? "signal" : "clean",
                                             color: signal.indicative ? Theme.danger : Theme.accent)
                                }
                                Text(signal.detail).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                            }
                        }
                    }

                    if report.likelyVulnerable {
                        Panel {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Next step", systemImage: "arrow.right.circle")
                                    .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.info)
                                Text("Confirm and exploit (if in scope) with a full tool on an authorized Kali box, e.g. sqlmap. iHunter stops at detection by design.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}
