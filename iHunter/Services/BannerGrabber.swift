import Foundation
import Network

/// Reads the service banner from an open TCP port — the on-device equivalent
/// of `nmap -sV` banner probing. TLS ports are handled separately by
/// TLSInspector / HTTPInspector.
enum BannerGrabber {
    private static let httpPorts: Set<UInt16> = [80, 591, 8000, 8080, 8888]

    static func grab(host: String, port: UInt16, timeout: TimeInterval = 2.5) async -> String? {
        await withCheckedContinuation { continuation in
            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                continuation.resume(returning: nil); return
            }
            let conn = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp)
            let latch = ResumeGuard()

            func finish(_ value: String?) {
                guard latch.trip() else { return }
                conn.cancel()
                continuation.resume(returning: value)
            }

            conn.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if httpPorts.contains(port) {
                        let req = "HEAD / HTTP/1.0\r\nHost: \(host)\r\nUser-Agent: iHunter\r\n\r\n"
                        conn.send(content: Data(req.utf8), completion: .contentProcessed { _ in
                            readBanner(conn, finish)
                        })
                    } else {
                        // SSH/FTP/SMTP/POP/IMAP send a greeting on connect.
                        readBanner(conn, finish)
                    }
                case .failed, .cancelled:
                    finish(nil)
                default:
                    break
                }
            }
            conn.start(queue: .global(qos: .userInitiated))
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { finish(nil) }
        }
    }

    private static func readBanner(_ conn: NWConnection, _ finish: @escaping (String?) -> Void) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 2048) { data, _, _, _ in
            if let data, !data.isEmpty {
                let text = String(decoding: data, as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                finish(text.isEmpty ? nil : text)
            } else {
                finish(nil)
            }
        }
    }
}
