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
            switch self { case .info: return "BİLGİ"; case .low: return "DÜŞÜK"; case .medium: return "ORTA"; case .high: return "YÜKSEK" }
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
                out.append(.init(title: "Telnet açık (23)",
                                 detail: "Telnet kimlik bilgilerini düz metin taşır. SSH ile değiştirin.",
                                 severity: .high, port: 23))
            case 21:
                out.append(.init(title: "FTP açık (21)",
                                 detail: "FTP genelde düz metindir. FTPS/SFTP kullanın, anonim erişimi kapatın.",
                                 severity: .medium, port: 21))
            case 139, 445:
                out.append(.init(title: "SMB/NetBIOS açık (\(obs.port))",
                                 detail: "SMB dışa açıksa ciddi risktir (EternalBlue vb.). İç ağda tutun ve yamalayın.",
                                 severity: .high, port: obs.port))
            case 3389:
                out.append(.init(title: "RDP açık (3389)",
                                 detail: "RDP kaba kuvvet/exploit hedefidir. NLA + VPN arkasına alın.",
                                 severity: .medium, port: 3389))
            case 5900:
                out.append(.init(title: "VNC açık (5900)",
                                 detail: "VNC parolasız/zayıf olabilir. Erişimi kısıtlayın, güçlü kimlik doğrulama ekleyin.",
                                 severity: .high, port: 5900))
            case 6379:
                out.append(.init(title: "Redis açık (6379)",
                                 detail: "Redis varsayılan olarak kimlik doğrulamasızdır. Asla internete açmayın.",
                                 severity: .high, port: 6379))
            case 27017:
                out.append(.init(title: "MongoDB açık (27017)",
                                 detail: "Açık MongoDB sık veri sızıntısı nedenidir. Auth + firewall uygulayın.",
                                 severity: .high, port: 27017))
            case 3306, 5432:
                out.append(.init(title: "Veritabanı portu açık (\(obs.port))",
                                 detail: "DB ağdan erişilebilir. Yalnızca uygulama sunucusuna izin verin.",
                                 severity: .medium, port: obs.port))
            case 25:
                out.append(.init(title: "SMTP açık (25)",
                                 detail: "Açık röle (open relay) kontrol edin; STARTTLS zorunlu olmalı.",
                                 severity: .low, port: 25))
            case 80, 8000, 8080, 8888:
                out.append(.init(title: "Şifresiz HTTP (\(obs.port))",
                                 detail: "Trafik düz metin. HTTPS'e yönlendirin ve HSTS uygulayın.",
                                 severity: .low, port: obs.port))
            default:
                break
            }

            if let banner = obs.banner, !banner.isEmpty {
                out.append(.init(title: "Banner/sürüm ifşası (\(obs.port)/\(obs.service))",
                                 detail: shorten(banner),
                                 severity: .info, port: obs.port))
            }
        }

        for f in httpFindings where f.severity != .ok {
            out.append(.init(title: "HTTP başlık: \(f.header)",
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
