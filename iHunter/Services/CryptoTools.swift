import Foundation
import CryptoKit

enum CryptoTools {
    static func md5(_ text: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(text.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func sha1(_ text: String) -> String {
        let digest = Insecure.SHA1.hash(data: Data(text.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func sha256(_ text: String) -> String {
        let digest = SHA256.hash(data: Data(text.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func sha512(_ text: String) -> String {
        let digest = SHA512.hash(data: Data(text.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func base64Encode(_ text: String) -> String {
        Data(text.utf8).base64EncodedString()
    }

    static func base64Decode(_ text: String) -> String {
        guard let data = Data(base64Encoded: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              let decoded = String(data: data, encoding: .utf8) else {
            return "⚠️ Invalid Base64"
        }
        return decoded
    }

    static func urlEncode(_ text: String) -> String {
        text.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? text
    }

    static func urlDecode(_ text: String) -> String {
        text.removingPercentEncoding ?? "⚠️ Could not decode"
    }

    static func hexEncode(_ text: String) -> String {
        Data(text.utf8).map { String(format: "%02x", $0) }.joined()
    }

    static func hexDecode(_ text: String) -> String {
        let clean = text.replacingOccurrences(of: " ", with: "")
        guard clean.count % 2 == 0 else { return "⚠️ Invalid hex" }
        var data = Data()
        var index = clean.startIndex
        while index < clean.endIndex {
            let next = clean.index(index, offsetBy: 2)
            guard let byte = UInt8(clean[index..<next], radix: 16) else { return "⚠️ Invalid hex" }
            data.append(byte)
            index = next
        }
        return String(data: data, encoding: .utf8) ?? "⚠️ Not UTF-8"
    }

    /// Rough password strength estimate (Shannon-ish entropy in bits).
    static func passwordEntropy(_ pw: String) -> Double {
        guard !pw.isEmpty else { return 0 }
        var pool = 0
        if pw.contains(where: { $0.isLowercase }) { pool += 26 }
        if pw.contains(where: { $0.isUppercase }) { pool += 26 }
        if pw.contains(where: { $0.isNumber }) { pool += 10 }
        if pw.contains(where: { !$0.isLetter && !$0.isNumber }) { pool += 33 }
        guard pool > 0 else { return 0 }
        return Double(pw.count) * log2(Double(pool))
    }
}
