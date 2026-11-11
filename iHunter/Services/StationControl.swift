import Foundation

/// Talks to the Raspberry Pi "station agent" over HTTP (see
/// docs/station-agent/). Token-protected, fixed action set. This keeps iHunter
/// dependency-free: no embedded SSH stack. For an interactive shell, use a
/// dedicated SSH app (Termius/Blink) — this panel is for one-tap actions.
@MainActor
final class StationControl: ObservableObject {
    @Published var host: String { didSet { save() } }
    @Published var port: String { didSet { save() } }
    @Published var token: String { didSet { save() } }
    @Published var nmapTarget: String = ""
    @Published var log: String = ""
    @Published var busy = false

    private let d = UserDefaults.standard

    init() {
        host = d.string(forKey: "station.host") ?? "10.42.0.1"
        port = d.string(forKey: "station.port") ?? "8777"
        token = d.string(forKey: "station.token") ?? ""
    }

    private func save() {
        d.set(host, forKey: "station.host")
        d.set(port, forKey: "station.port")
        d.set(token, forKey: "station.token")
    }

    private func makeURL(_ path: String, query: [String: String] = [:]) -> URL? {
        var c = URLComponents()
        c.scheme = "http"
        c.host = host.trimmingCharacters(in: .whitespaces)
        c.port = Int(port)
        c.path = path
        if !query.isEmpty {
            c.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return c.url
    }

    func call(_ title: String, path: String, method: String = "GET", query: [String: String] = [:], timeout: TimeInterval = 45) {
        guard !busy else { return }
        guard !host.isEmpty, Int(port) != nil else { append("✖ Set host and port first."); return }
        guard let url = makeURL(path, query: query) else { append("✖ Invalid URL."); return }
        busy = true
        append("▶ \(title) …")

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = timeout
        req.setValue(token, forHTTPHeaderField: "X-Station-Token")

        Task {
            do {
                let (data, resp) = try await URLSession(configuration: .ephemeral).data(for: req)
                let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                let body = prettify(String(decoding: data.prefix(60_000), as: UTF8.self))
                await MainActor.run {
                    append("◀ [\(code)] \(title)\n\(body)")
                    busy = false
                }
            } catch {
                await MainActor.run {
                    append("✖ \(title): \(error.localizedDescription)\n   (Agent running? On the Pi's hotspot? Token correct?)")
                    busy = false
                }
            }
        }
    }

    func runNmap() {
        let t = nmapTarget.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { append("✖ Enter an nmap target."); return }
        call("nmap \(t)", path: "/nmap", query: ["target": t])
    }

    private func prettify(_ s: String) -> String {
        guard let data = s.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: pretty, encoding: .utf8) else {
            return s
        }
        return str
    }

    private func append(_ s: String) {
        let stamp = Self.timeFormatter.string(from: Date())
        log = "[\(stamp)] \(s)\n\n" + log
    }

    func clear() { log = "" }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
}
