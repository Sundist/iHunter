import Foundation

struct InjectionSignal: Identifiable {
    let id = UUID()
    let technique: String
    let indicative: Bool
    let detail: String
}

struct InjectionReport {
    let parameter: String
    let baselineStatus: Int
    let signals: [InjectionSignal]
    var likelyVulnerable: Bool { signals.contains { $0.indicative } }
}

/// Non-destructive SQLi / reflected-XSS **detection** probe.
///
/// Scope on purpose:
/// - Only GET requests, only the single named parameter.
/// - Read-only, a handful of probes — no crawling, no fuzzing of every field.
/// - Detects *whether* a parameter looks injectable; it does NOT extract data,
///   enumerate schemas, or open shells. That (the sqlmap exploitation core) is
///   intentionally out of scope and belongs on an authorized Kali box.
enum InjectionTester {
    private struct Fetch { let status: Int; let body: String; let length: Int }

    // Common DBMS error signatures (error-based detection).
    private static let sqlErrors = [
        "sql syntax", "mysql_fetch", "mysqli", "you have an error in your sql",
        "ora-0", "oracle error", "postgresql", "pg_query", "sqlite", "sqlite3",
        "odbc", "unclosed quotation mark", "quoted string not properly terminated",
        "sqlstate", "syntax error at or near", "warning: mysql", "native client"
    ]

    static func test(urlString: String, parameter: String) async -> InjectionReport? {
        var normalized = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.lowercased().hasPrefix("http") { normalized = "https://" + normalized }
        guard let comps = URLComponents(string: normalized),
              let items = comps.queryItems,
              items.contains(where: { $0.name == parameter }) else {
            return nil
        }

        func variant(_ transform: (String) -> String) -> URL? {
            var copy = comps
            copy.queryItems = items.map { item in
                item.name == parameter
                    ? URLQueryItem(name: item.name, value: transform(item.value ?? ""))
                    : item
            }
            return copy.url
        }

        guard let baseURL = comps.url,
              let base = await fetch(baseURL) else { return nil }

        var signals: [InjectionSignal] = []

        // 1) Error-based: a lone single quote should not, by itself, surface a
        //    raw DBMS error on a well-parameterized endpoint.
        if let u = variant({ $0 + "'" }), let r = await fetch(u) {
            let hit = sqlErrors.first(where: { r.body.lowercased().contains($0) })
            if let hit, !base.body.lowercased().contains(hit) {
                signals.append(.init(technique: "Error-based SQLi",
                                     indicative: true,
                                     detail: "Adding a single quote surfaced a DBMS error signature: \"\(hit)\". The parameter may not be sanitized."))
            } else {
                signals.append(.init(technique: "Error-based SQLi",
                                     indicative: false,
                                     detail: "No DBMS error signature appeared for the single-quote probe."))
            }
        }

        // 2) Boolean-based: TRUE payload should resemble baseline, FALSE should differ.
        if let tURL = variant({ $0 + "' AND '1'='1" }),
           let fURL = variant({ $0 + "' AND '1'='2" }),
           let t = await fetch(tURL), let f = await fetch(fURL) {
            let maxLen = max(max(base.length, t.length), max(f.length, 1))
            let trueClose = Double(abs(t.length - base.length)) / Double(maxLen) < 0.05
            let falseFar = Double(abs(f.length - base.length)) / Double(maxLen) > 0.30
                || f.status != base.status
            if trueClose && falseFar {
                signals.append(.init(technique: "Boolean-based SQLi",
                                     indicative: true,
                                     detail: "TRUE response nearly matches baseline while FALSE differs clearly (len: base \(base.length), true \(t.length), false \(f.length)). Sign of blind SQLi."))
            } else {
                signals.append(.init(technique: "Boolean-based SQLi",
                                     indicative: false,
                                     detail: "No meaningful difference between TRUE/FALSE responses (len: base \(base.length), true \(t.length), false \(f.length))."))
            }
        }

        // 3) Reflected XSS: does a unique marker come back unencoded?
        let marker = "iHunter<svg/onload=1>"
        if let u = variant({ _ in marker }), let r = await fetch(u) {
            if r.body.contains(marker) {
                signals.append(.init(technique: "Reflected XSS",
                                     indicative: true,
                                     detail: "The marker was reflected UNENCODED in the response body. Output encoding may be missing."))
            } else {
                signals.append(.init(technique: "Reflected XSS",
                                     indicative: false,
                                     detail: "The marker was not reflected raw (encoded or filtered)."))
            }
        }

        return InjectionReport(parameter: parameter, baselineStatus: base.status, signals: signals)
    }

    private static func fetch(_ url: URL) async -> Fetch? {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 15
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue("iHunter/1.0", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession(configuration: .ephemeral).data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(decoding: data.prefix(200_000), as: UTF8.self)
            return Fetch(status: status, body: body, length: data.count)
        } catch {
            return nil
        }
    }
}
