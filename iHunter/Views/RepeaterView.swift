import SwiftUI

@MainActor
final class RepeaterModel: ObservableObject {
    @Published var method = "GET"
    @Published var url = ""
    @Published var headers = "User-Agent: iHunter/1.0"
    @Published var body = ""
    @Published var responseStatus = ""
    @Published var responseHeaders = ""
    @Published var responseBody = ""
    @Published var elapsed = ""
    @Published var isSending = false
    @Published var error: String?

    let methods = ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS", "PATCH"]

    func send() {
        guard !isSending, !url.isEmpty else { return }
        var s = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.lowercased().hasPrefix("http") { s = "https://" + s }
        guard let u = URL(string: s) else { error = "Geçersiz URL"; return }

        isSending = true
        error = nil
        responseStatus = ""; responseHeaders = ""; responseBody = ""; elapsed = ""

        var req = URLRequest(url: u)
        req.httpMethod = method
        req.timeoutInterval = 25
        req.cachePolicy = .reloadIgnoringLocalCacheData

        for line in headers.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            if parts.count == 2, !parts[0].isEmpty {
                req.setValue(parts[1], forHTTPHeaderField: parts[0])
            }
        }
        if !body.isEmpty, method != "GET", method != "HEAD" {
            req.httpBody = Data(body.utf8)
        }

        let start = Date()
        Task {
            do {
                let config = URLSessionConfiguration.ephemeral
                let (data, response) = try await URLSession(configuration: config).data(for: req)
                let ms = Int(Date().timeIntervalSince(start) * 1000)
                let http = response as? HTTPURLResponse
                let hdrs = http?.allHeaderFields
                    .map { "\($0.key): \($0.value)" }
                    .sorted()
                    .joined(separator: "\n") ?? ""
                let bodyText = String(decoding: data.prefix(40_000), as: UTF8.self)
                await MainActor.run {
                    responseStatus = http.map { "HTTP \($0.statusCode)" } ?? "Yanıt"
                    responseHeaders = hdrs
                    responseBody = bodyText.isEmpty ? "(boş gövde)" : bodyText
                    elapsed = "\(ms) ms · \(data.count) bayt"
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isSending = false
                }
            }
        }
    }
}

struct RepeaterView: View {
    @StateObject private var model = RepeaterModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("İstek").font(.headline).foregroundStyle(Theme.accent)
                        Picker("Metot", selection: $model.method) {
                            ForEach(model.methods, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)

                        TextField("https://example.com/api", text: $model.url)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        Text("Başlıklar (her satır `Ad: Değer`)").font(.caption).foregroundStyle(.secondary)
                        editor($model.headers, minHeight: 70)

                        if model.method != "GET" && model.method != "HEAD" {
                            Text("Gövde").font(.caption).foregroundStyle(.secondary)
                            editor($model.body, minHeight: 80)
                        }

                        HStack {
                            Spacer()
                            Button(action: model.send) {
                                if model.isSending { ProgressView() } else { Label("Gönder", systemImage: "paperplane.fill") }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(model.url.isEmpty || model.isSending)
                        }
                    }
                }

                if let error = model.error {
                    Panel {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.footnote).foregroundStyle(Theme.danger)
                    }
                }

                if !model.responseStatus.isEmpty {
                    Panel {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(model.responseStatus).font(.headline).foregroundStyle(statusColor)
                                Spacer()
                                Text(model.elapsed).font(Theme.monoSmall).foregroundStyle(.secondary)
                            }
                            if !model.responseHeaders.isEmpty {
                                Text("Yanıt başlıkları").font(.caption.weight(.semibold)).foregroundStyle(.white)
                                Text(model.responseHeaders).font(Theme.monoSmall).foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    Panel {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Yanıt gövdesi").font(.caption.weight(.semibold)).foregroundStyle(.white)
                            Text(model.responseBody).font(Theme.monoSmall).foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private var statusColor: Color {
        if model.responseStatus.contains("HTTP 2") { return Theme.accent }
        if model.responseStatus.contains("HTTP 3") { return Theme.info }
        return Theme.warning
    }

    private func editor(_ text: Binding<String>, minHeight: CGFloat) -> some View {
        TextEditor(text: text)
            .font(Theme.monoSmall)
            .frame(minHeight: minHeight)
            .scrollContentBackground(.hidden)
            .padding(8)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
    }
}
