import Foundation

struct HeaderFinding: Identifiable {
    let id = UUID()
    let header: String
    let present: Bool
    let detail: String
    let severity: Severity

    enum Severity { case ok, warn, bad }
}

struct HTTPResult {
    let statusCode: Int
    let finalURL: String
    let headers: [(String, String)]
    let findings: [HeaderFinding]
    let server: String?
}

enum HTTPInspector {
    /// Fetches headers and grades the response against common security headers.
    static func inspect(urlString: String) async throws -> HTTPResult {
        var normalized = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.lowercased().hasPrefix("http") {
            normalized = "https://" + normalized
        }
        guard let url = URL(string: normalized) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("iHunter/1.0", forHTTPHeaderField: "User-Agent")

        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: config)
        let (_, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        var pairs: [(String, String)] = []
        for (k, v) in http.allHeaderFields {
            pairs.append((String(describing: k), String(describing: v)))
        }
        pairs.sort { $0.0.lowercased() < $1.0.lowercased() }

        let lower = Dictionary(
            uniqueKeysWithValues: pairs.map { ($0.0.lowercased(), $0.1) }
        )

        func check(_ name: String, friendly: String, missingSeverity: HeaderFinding.Severity = .warn) -> HeaderFinding {
            if let value = lower[name.lowercased()] {
                return HeaderFinding(header: friendly, present: true, detail: value, severity: .ok)
            }
            return HeaderFinding(header: friendly, present: false, detail: "Missing", severity: missingSeverity)
        }

        var findings: [HeaderFinding] = [
            check("Strict-Transport-Security", friendly: "HSTS", missingSeverity: .bad),
            check("Content-Security-Policy", friendly: "CSP", missingSeverity: .bad),
            check("X-Frame-Options", friendly: "X-Frame-Options"),
            check("X-Content-Type-Options", friendly: "X-Content-Type-Options"),
            check("Referrer-Policy", friendly: "Referrer-Policy"),
            check("Permissions-Policy", friendly: "Permissions-Policy")
        ]

        // Information disclosure: Server / X-Powered-By expose stack details.
        if let server = lower["server"] {
            findings.append(HeaderFinding(header: "Server (disclosure)", present: true, detail: server, severity: .warn))
        }
        if let powered = lower["x-powered-by"] {
            findings.append(HeaderFinding(header: "X-Powered-By (disclosure)", present: true, detail: powered, severity: .warn))
        }

        return HTTPResult(
            statusCode: http.statusCode,
            finalURL: http.url?.absoluteString ?? normalized,
            headers: pairs,
            findings: findings,
            server: lower["server"]
        )
    }
}
