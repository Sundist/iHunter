import SwiftUI

/// Dragon-green "hacker terminal" palette, in the spirit of Kali/NetHunter.
enum Theme {
    static let accent = Color(red: 0.22, green: 0.93, blue: 0.56)   // neon green
    static let danger = Color(red: 0.98, green: 0.36, blue: 0.36)
    static let warning = Color(red: 0.99, green: 0.78, blue: 0.30)
    static let info = Color(red: 0.36, green: 0.73, blue: 0.99)
    static let background = Color(red: 0.05, green: 0.06, blue: 0.08)
    static let card = Color(red: 0.10, green: 0.12, blue: 0.15)
    static let mono = Font.system(.body, design: .monospaced)
    static let monoSmall = Font.system(.footnote, design: .monospaced)
}

/// A reusable card container used across tool screens.
struct Panel<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.accent.opacity(0.18), lineWidth: 1)
            )
    }
}

struct TagLabel: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
