import Foundation
import Network

/// A lightweight TCP connect probe built on Apple's Network framework.
/// Works inside the iOS sandbox without root — the only vector actually
/// available to a non-jailbroken App Store app.
enum TCPProbe {
    /// Attempts a TCP handshake to `host:port`. Returns true if it connects
    /// before `timeout` seconds.
    static func isOpen(host: String, port: UInt16, timeout: TimeInterval = 1.0) async -> Bool {
        await withCheckedContinuation { continuation in
            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                continuation.resume(returning: false)
                return
            }
            let params = NWParameters.tcp
            // Fail fast; we only care about the handshake.
            if let tcp = params.defaultProtocolStack.transportProtocol as? NWProtocolTCP.Options {
                tcp.connectionTimeout = Int(timeout)
                tcp.noDelay = true
            }
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: nwPort,
                using: params
            )
            let finished = ResumeGuard()
            let deadline = DispatchTime.now() + timeout

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if finished.trip() {
                        connection.cancel()
                        continuation.resume(returning: true)
                    }
                case .failed, .cancelled:
                    if finished.trip() {
                        connection.cancel()
                        continuation.resume(returning: false)
                    }
                default:
                    break
                }
            }
            connection.start(queue: .global(qos: .userInitiated))
            DispatchQueue.global().asyncAfter(deadline: deadline) {
                if finished.trip() {
                    connection.cancel()
                    continuation.resume(returning: false)
                }
            }
        }
    }
}

/// Thread-safe one-shot latch so a continuation is only resumed once.
final class ResumeGuard: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false
    func trip() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if done { return false }
        done = true
        return true
    }
}

/// Well-known ports with human-readable service names.
struct PortInfo: Identifiable {
    var id: UInt16 { port }
    let port: UInt16
    let service: String
}

enum PortCatalog {
    static let common: [PortInfo] = [
        .init(port: 21, service: "FTP"),
        .init(port: 22, service: "SSH"),
        .init(port: 23, service: "Telnet"),
        .init(port: 25, service: "SMTP"),
        .init(port: 53, service: "DNS"),
        .init(port: 80, service: "HTTP"),
        .init(port: 110, service: "POP3"),
        .init(port: 139, service: "NetBIOS"),
        .init(port: 143, service: "IMAP"),
        .init(port: 443, service: "HTTPS"),
        .init(port: 445, service: "SMB"),
        .init(port: 993, service: "IMAPS"),
        .init(port: 995, service: "POP3S"),
        .init(port: 1723, service: "PPTP"),
        .init(port: 3306, service: "MySQL"),
        .init(port: 3389, service: "RDP"),
        .init(port: 5432, service: "PostgreSQL"),
        .init(port: 5900, service: "VNC"),
        .init(port: 6379, service: "Redis"),
        .init(port: 8080, service: "HTTP-alt"),
        .init(port: 8443, service: "HTTPS-alt"),
        .init(port: 27017, service: "MongoDB")
    ]

    static func service(for port: UInt16) -> String {
        common.first(where: { $0.port == port })?.service ?? "unknown"
    }
}
