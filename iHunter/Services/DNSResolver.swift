import Foundation

struct DNSRecord: Identifiable {
    let id = UUID()
    let type: String
    let value: String
}

enum DNSResolver {
    /// Forward resolution via getaddrinfo — returns A and AAAA records.
    static func resolve(host: String) async -> [DNSRecord] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var records: [DNSRecord] = []
                var hints = addrinfo(
                    ai_flags: 0,
                    ai_family: AF_UNSPEC,
                    ai_socktype: SOCK_STREAM,
                    ai_protocol: IPPROTO_TCP,
                    ai_addrlen: 0,
                    ai_canonname: nil,
                    ai_addr: nil,
                    ai_next: nil
                )
                var info: UnsafeMutablePointer<addrinfo>?
                let status = getaddrinfo(host, nil, &hints, &info)
                guard status == 0, let first = info else {
                    continuation.resume(returning: records)
                    return
                }
                defer { freeaddrinfo(info) }

                var seen = Set<String>()
                var ptr: UnsafeMutablePointer<addrinfo>? = first
                while let current = ptr {
                    var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(current.pointee.ai_addr,
                                   current.pointee.ai_addrlen,
                                   &buffer, socklen_t(buffer.count),
                                   nil, 0, NI_NUMERICHOST) == 0 {
                        let value = String(cString: buffer)
                        if !value.isEmpty && seen.insert(value).inserted {
                            let type = current.pointee.ai_family == AF_INET6 ? "AAAA" : "A"
                            records.append(DNSRecord(type: type, value: value))
                        }
                    }
                    ptr = current.pointee.ai_next
                }
                continuation.resume(returning: records)
            }
        }
    }

    /// Reverse resolution (PTR) for an IP literal.
    static func reverse(ip: String) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var sa = sockaddr_in()
                sa.sin_family = sa_family_t(AF_INET)
                sa.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
                guard inet_pton(AF_INET, ip, &sa.sin_addr) == 1 else {
                    continuation.resume(returning: nil)
                    return
                }
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = withUnsafePointer(to: &sa) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { ptr in
                        getnameinfo(ptr, socklen_t(MemoryLayout<sockaddr_in>.size),
                                    &host, socklen_t(host.count), nil, 0, NI_NAMEREQD)
                    }
                }
                if result == 0 {
                    continuation.resume(returning: String(cString: host))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
