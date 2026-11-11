import Foundation

struct InterfaceAddress: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let netmask: String
    let isIPv4: Bool
}

enum NetworkInfo {
    /// Enumerates active interface addresses via getifaddrs (BSD).
    static func addresses() -> [InterfaceAddress] {
        var result: [InterfaceAddress] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return result }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let current = ptr {
            let flags = Int32(current.pointee.ifa_flags)
            let family = current.pointee.ifa_addr.pointee.sa_family
            let up = (flags & IFF_UP) == IFF_UP
            let loopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK

            if up && !loopback, family == UInt8(AF_INET) || family == UInt8(AF_INET6) {
                let name = String(cString: current.pointee.ifa_name)
                let addr = sockaddrToString(current.pointee.ifa_addr)
                let mask = current.pointee.ifa_netmask.map { sockaddrToString($0) } ?? ""
                if !addr.isEmpty {
                    result.append(
                        InterfaceAddress(
                            name: name,
                            address: addr,
                            netmask: mask,
                            isIPv4: family == UInt8(AF_INET)
                        )
                    )
                }
            }
            ptr = current.pointee.ifa_next
        }
        return result
    }

    /// Returns the primary IPv4 address of the Wi-Fi interface if present.
    static func primaryWiFiIPv4() -> InterfaceAddress? {
        let all = addresses().filter { $0.isIPv4 }
        return all.first(where: { $0.name == "en0" }) ?? all.first
    }

    private static func sockaddrToString(_ sa: UnsafeMutablePointer<sockaddr>) -> String {
        var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let len = socklen_t(sa.pointee.sa_len)
        let status = getnameinfo(sa, len, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
        guard status == 0 else { return "" }
        var str = String(cString: host)
        // Strip scope id from link-local IPv6 (fe80::1%en0)
        if let pct = str.firstIndex(of: "%") { str = String(str[..<pct]) }
        return str
    }
}
