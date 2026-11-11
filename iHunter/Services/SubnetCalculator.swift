import Foundation

struct SubnetResult {
    let network: String
    let broadcast: String
    let firstHost: String
    let lastHost: String
    let netmask: String
    let wildcard: String
    let hostCount: UInt64
    let cidr: Int
}

enum SubnetCalculator {
    /// Parses an IPv4 string into a UInt32, big-endian host order.
    static func parseIPv4(_ s: String) -> UInt32? {
        let parts = s.split(separator: ".")
        guard parts.count == 4 else { return nil }
        var value: UInt32 = 0
        for part in parts {
            guard let octet = UInt32(part), octet <= 255 else { return nil }
            value = (value << 8) | octet
        }
        return value
    }

    static func format(_ value: UInt32) -> String {
        "\((value >> 24) & 0xFF).\((value >> 16) & 0xFF).\((value >> 8) & 0xFF).\(value & 0xFF)"
    }

    /// Computes subnet facts for `ip/cidr`.
    static func calculate(ip: String, cidr: Int) -> SubnetResult? {
        guard (0...32).contains(cidr), let ipVal = parseIPv4(ip) else { return nil }
        let mask: UInt32 = cidr == 0 ? 0 : (~UInt32(0)) << (32 - cidr)
        let network = ipVal & mask
        let broadcast = network | ~mask
        let total = cidr >= 31 ? UInt64(1) << (32 - cidr) : (UInt64(1) << (32 - cidr))
        let usable: UInt64 = cidr >= 31 ? total : (total > 2 ? total - 2 : 0)
        let first = cidr >= 31 ? network : network &+ 1
        let last = cidr >= 31 ? broadcast : (broadcast > network ? broadcast &- 1 : broadcast)

        return SubnetResult(
            network: format(network),
            broadcast: format(broadcast),
            firstHost: format(first),
            lastHost: format(last),
            netmask: format(mask),
            wildcard: format(~mask),
            hostCount: usable,
            cidr: cidr
        )
    }

    /// Enumerates host addresses in a /24-or-smaller range for scanning.
    /// Capped to avoid runaway loops on wide prefixes.
    static func hosts(ip: String, cidr: Int, cap: Int = 1024) -> [String] {
        guard let ipVal = parseIPv4(ip), (0...32).contains(cidr) else { return [] }
        let mask: UInt32 = cidr == 0 ? 0 : (~UInt32(0)) << (32 - cidr)
        let network = ipVal & mask
        let broadcast = network | ~mask
        guard broadcast >= network else { return [] }
        var out: [String] = []
        var addr = cidr >= 31 ? network : network &+ 1
        let end = cidr >= 31 ? broadcast : (broadcast > network ? broadcast &- 1 : broadcast)
        while addr <= end && out.count < cap {
            out.append(format(addr))
            if addr == UInt32.max { break }
            addr &+= 1
        }
        return out
    }
}
