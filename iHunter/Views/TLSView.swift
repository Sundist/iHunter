import SwiftUI

struct TLSView: View {
    @State private var host = ""
    @State private var result: TLSResult?
    @State private var isWorking = false
    @State private var searched = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Host (port 443)").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        TextField("example.com", text: $host)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onSubmit(run)
                        HStack {
                            Spacer()
                            Button(action: run) {
                                if isWorking { ProgressView() } else { Text("Bağlan") }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(host.isEmpty || isWorking)
                        }
                    }
                }

                if let result {
                    Panel {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Güven değerlendirmesi").font(.headline).foregroundStyle(.white)
                                Spacer()
                                TagLabel(text: result.trusted ? "GÜVENİLİR" : "GÜVENİLMEZ",
                                         color: result.trusted ? Theme.accent : Theme.danger)
                            }
                            Text("\(result.host):\(String(result.port)) · \(result.negotiatedProtocol)")
                                .font(Theme.monoSmall).foregroundStyle(.secondary)
                        }
                    }

                    Panel {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Sertifika zinciri (\(result.certificates.count))").font(.headline).foregroundStyle(Theme.accent)
                            ForEach(result.certificates) { cert in
                                HStack(alignment: .top) {
                                    TagLabel(text: cert.position == 0 ? "leaf" : "#\(cert.position)",
                                             color: cert.position == 0 ? Theme.accent : Theme.info)
                                    Text(cert.summary).font(Theme.monoSmall).foregroundStyle(.white)
                                        .textSelection(.enabled)
                                    Spacer()
                                }
                            }
                        }
                    }
                } else if searched && !isWorking {
                    Panel {
                        Label("TLS bağlantısı kurulamadı veya sertifika okunamadı.", systemImage: "xmark.shield")
                            .font(.footnote).foregroundStyle(Theme.danger)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func run() {
        let target = host.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        guard !target.isEmpty else { return }
        isWorking = true
        searched = true
        result = nil
        Task {
            let r = await TLSInspector.inspect(host: target)
            await MainActor.run { result = r; isWorking = false }
        }
    }
}
