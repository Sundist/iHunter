import SwiftUI

struct HTTPHeaderView: View {
    @State private var url = ""
    @State private var result: HTTPResult?
    @State private var isWorking = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("URL").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        TextField("https://example.com", text: $url)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onSubmit(run)
                        HStack {
                            Spacer()
                            Button(action: run) {
                                if isWorking { ProgressView() } else { Text("Inspect") }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(url.isEmpty || isWorking)
                        }
                    }
                }

                if let error {
                    Panel {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.footnote).foregroundStyle(Theme.danger)
                    }
                }

                if let result {
                    Panel {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Status").font(.headline).foregroundStyle(.white)
                                Spacer()
                                TagLabel(text: "\(result.statusCode)",
                                         color: (200..<300).contains(result.statusCode) ? Theme.accent : Theme.warning)
                            }
                            Text(result.finalURL).font(Theme.monoSmall).foregroundStyle(Theme.info)
                                .textSelection(.enabled)
                        }
                    }

                    Panel {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Security-header analysis").font(.headline).foregroundStyle(Theme.accent)
                            ForEach(result.findings) { f in
                                HStack(alignment: .top) {
                                    Image(systemName: icon(f.severity))
                                        .foregroundStyle(color(f.severity))
                                        .font(.caption)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(f.header).font(.subheadline.weight(.medium)).foregroundStyle(.white)
                                        Text(f.detail).font(Theme.monoSmall).foregroundStyle(.secondary)
                                            .lineLimit(3)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }

                    Panel {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Raw headers (\(result.headers.count))").font(.headline).foregroundStyle(.white)
                            ForEach(Array(result.headers.enumerated()), id: \.offset) { _, pair in
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(pair.0).font(Theme.monoSmall.weight(.bold)).foregroundStyle(Theme.accent)
                                    Text(pair.1).font(Theme.monoSmall).foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func icon(_ s: HeaderFinding.Severity) -> String {
        switch s { case .ok: return "checkmark.circle.fill"; case .warn: return "exclamationmark.circle.fill"; case .bad: return "xmark.octagon.fill" }
    }
    private func color(_ s: HeaderFinding.Severity) -> Color {
        switch s { case .ok: return Theme.accent; case .warn: return Theme.warning; case .bad: return Theme.danger }
    }

    private func run() {
        isWorking = true
        error = nil
        result = nil
        Task {
            do {
                let r = try await HTTPInspector.inspect(urlString: url)
                await MainActor.run { result = r; isWorking = false }
            } catch {
                await MainActor.run {
                    self.error = "Request failed: \(error.localizedDescription)"
                    isWorking = false
                }
            }
        }
    }
}
