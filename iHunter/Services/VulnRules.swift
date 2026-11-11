import Foundation

struct VulnFinding: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let severity: Severity
    let port: UInt16?

    enum Severity: Int, Comparable {
        case info = 0, low, medium, high
        static func < (l: Severity, r: Severity) -> Bool { l.rawValue < r.rawValue }
        var label: String {
            switch self { case .info: return "INFO"; case .low: return "LOW"; case .medium: return "MEDIUM"; case .high: return "HIGH" }
        }
    }
}

struct ServiceObservation {
    let port: UInt16
    let service: String
    let banner: String?
}

/// Configuration-review ruleset. This IDENTIFIES and INFORMS (like the
/// reporting side of a vulnerability scanner) — it does not exploit anything.
enum VulnRules {
    static func evaluate(observations: [ServiceObservation], httpFindings: [HeaderFinding]) -> [VulnFinding] {
        var out: [VulnFinding] = []

        for obs in observations {
            switch obs.port {
            case 23:
                out.append(.init(title: "Telnet open (23)",
                                 detail: "Telnet carries credentials in clear text. Replace it with SSH.",
                                 severity: .high, port: 23))
            case 21:
                out.append(.init(title: "FTP open (21)",
                                 detail: "FTP is usually plaintext. Use FTPS/SFTP and disable anonymous access.",
                                 severity: .medium, port: 21))
            case 139, 445:
                out.append(.init(title: "SMB/NetBIOS open (\(obs.port))",
                                 detail: "Exposed SMB is a serious risk (EternalBlue, etc.). Keep it internal and patched.",
                                 severity: .high, port: obs.port))
            case 3389:
                out.append(.init(title: "RDP open (3389)",
                                 detail: "RDP is a brute-force/exploit target. Put it behind NLA + VPN.",
                                 severity: .medium, port: 3389))
            case 5900:
                out.append(.init(title: "VNC open (5900)",
                                 detail: "VNC may be passwordless/weak. Restrict access and add strong auth.",
                                 severity: .high, port: 5900))
            case 6379:
                out.append(.init(title: "Redis open (6379)",
                                 detail: "Redis is unauthenticated by default. Never expose it to the internet.",
                                 severity: .high, port: 6379))
            case 27017:
                out.append(.init(title: "MongoDB open (27017)",
                                 detail: "Exposed MongoDB is a frequent cause of data leaks. Enable auth + firewall.",
                                 severity: .high, port: 27017))
            case 3306, 5432:
                out.append(.init(title: "Database port open (\(obs.port))",
                                 detail: "DB reachable from the network. Allow only the application server.",
                                 severity: .medium, port: obs.port))
            case 25:
                out.append(.init(title: "SMTP open (25)",
                                 detail: "Check for an open relay; STARTTLS should be enforced.",
                                 severity: .low, port: 25))
            case 80, 8000, 8080, 8888:
                out.append(.init(title: "Cleartext HTTP (\(obs.port))",
                                 detail: "Traffic is plaintext. Redirect to HTTPS and enforce HSTS.",
                                 severity: .low, port: obs.port))
            default:
                break
            }

            if let banner = obs.banner, !banner.isEmpty {
                out.append(.init(title: "Banner/version disclosure (\(obs.port)/\(obs.service))",
                                 detail: shorten(banner),
                                 severity: .info, port: obs.port))
            }
        }

        for f in httpFindings where f.severity != .ok {
            out.append(.init(title: "HTTP header: \(f.header)",
                             detail: f.detail,
                             severity: f.severity == .bad ? .medium : .low,
                             port: nil))
        }

        return out.sorted { $0.severity > $1.severity }
    }

    /// Extracts a likely "product version" keyword from a banner, for CVE search.
    static func cveKeyword(from banner: String) -> String? {
        let firstLine = banner.split(whereSeparator: { $0 == "\n" || $0 == "\r" }).first.map(String.init) ?? banner
        // Keep tokens that look like "name/x.y" or "name x.y.z".
        if let match = firstLine.range(of: #"[A-Za-z][A-Za-z0-9._-]*[/ ]\d+(\.\d+)+"#, options: .regularExpression) {
            return String(firstLine[match]).replacingOccurrences(of: "/", with: " ")
        }
        return nil
    }

    private static func shorten(_ s: String) -> String {
        let one = s.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\r", with: " ")
        return one.count > 180 ? String(one.prefix(180)) + "…" : one
    }
}
