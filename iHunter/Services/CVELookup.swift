import Foundation

struct CVEItem: Identifiable {
    let id: String
    var identifier: String { id }
    let summary: String
    let score: Double?
}

/// Queries the public NVD (National Vulnerability Database) 2.0 API by keyword.
/// Best-effort: the API is rate-limited for anonymous callers, so failures are
/// returned as an empty list and surfaced gently in the UI.
enum CVELookup {
    enum Result { case items([CVEItem]), empty, failed }

    static func search(keyword: String) async -> Result {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return .empty }
        guard var comps = URLComponents(string: "https://services.nvd.nist.gov/rest/json/cves/2.0") else { return .failed }
        comps.queryItems = [
            URLQueryItem(name: "keywordSearch", value: trimmed),
            URLQueryItem(name: "resultsPerPage", value: "15")
        ]
        guard let url = comps.url else { return .failed }
        var req = URLRequest(url: url)
        req.timeoutInterval = 25
        req.setValue("iHunter/1.0", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                return .failed
            }
            let items = parse(data)
            return items.isEmpty ? .empty : .items(items)
        } catch {
            return .failed
        }
    }

    private static func parse(_ data: Data) -> [CVEItem] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let vulns = root["vulnerabilities"] as? [[String: Any]] else { return [] }
        var items: [CVEItem] = []
        for v in vulns {
            guard let cve = v["cve"] as? [String: Any],
                  let id = cve["id"] as? String else { continue }
            var summary = ""
            if let descs = cve["descriptions"] as? [[String: Any]] {
                summary = (descs.first(where: { ($0["lang"] as? String) == "en" })?["value"] as? String) ?? ""
            }
            var score: Double?
            if let metrics = cve["metrics"] as? [String: Any] {
                for key in ["cvssMetricV31", "cvssMetricV30", "cvssMetricV2"] {
                    if let arr = metrics[key] as? [[String: Any]],
                       let first = arr.first,
                       let cvss = first["cvssData"] as? [String: Any],
                       let base = cvss["baseScore"] as? Double {
                        score = base
                        break
                    }
                }
            }
            items.append(CVEItem(id: id, summary: summary, score: score))
        }
        return items
    }
}
