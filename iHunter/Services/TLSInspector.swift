import Foundation
import Network
import Security

struct TLSCertificate: Identifiable {
    let id = UUID()
    let summary: String
    let position: Int
}

struct TLSResult {
    let host: String
    let port: UInt16
    let trusted: Bool
    let certificates: [TLSCertificate]
    let negotiatedProtocol: String
}

enum TLSInspector {
    /// Opens a TLS connection and reports the certificate chain + trust result.
    static func inspect(host: String, port: UInt16 = 443, timeout: TimeInterval = 10) async -> TLSResult? {
        await withCheckedContinuation { continuation in
            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                continuation.resume(returning: nil)
                return
            }

            let tlsOptions = NWProtocolTLS.Options()
            let box = TrustBox()

            sec_protocol_options_set_verify_block(
                tlsOptions.securityProtocolOptions,
                { _, secTrust, complete in
                    let trust = sec_trust_copy_ref(secTrust).takeRetainedValue()
                    box.store(trust)
                    // We only inspect — always continue so we can read the chain
                    // even for self-signed / untrusted certs.
                    complete(true)
                },
                DispatchQueue.global()
            )

            let params = NWParameters(tls: tlsOptions)
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: nwPort,
                using: params
            )
            let guardLatch = ResumeGuard()

            func finish() {
                guard guardLatch.trip() else { return }
                let trust = box.value
                var trusted = false
                var certs: [TLSCertificate] = []
                if let trust {
                    trusted = SecTrustEvaluateWithError(trust, nil)
                    if let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate] {
                        for (idx, cert) in chain.enumerated() {
                            let summary = (SecCertificateCopySubjectSummary(cert) as String?) ?? "Unknown subject"
                            certs.append(TLSCertificate(summary: summary, position: idx))
                        }
                    }
                }
                connection.cancel()
                let result = TLSResult(
                    host: host,
                    port: port,
                    trusted: trusted,
                    certificates: certs,
                    negotiatedProtocol: "TLS"
                )
                continuation.resume(returning: certs.isEmpty && !trusted ? nil : result)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    finish()
                case .failed, .cancelled:
                    finish()
                default:
                    break
                }
            }
            connection.start(queue: .global(qos: .userInitiated))
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { finish() }
        }
    }
}

/// Captures the SecTrust from the verify block across threads.
final class TrustBox: @unchecked Sendable {
    private let lock = NSLock()
    private var trust: SecTrust?
    func store(_ t: SecTrust) {
        lock.lock(); trust = t; lock.unlock()
    }
    var value: SecTrust? {
        lock.lock(); defer { lock.unlock() }
        return trust
    }
}
