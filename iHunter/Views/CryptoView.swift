import SwiftUI

struct CryptoView: View {
    @State private var input = ""
    @State private var selected: Operation = .sha256

    enum Operation: String, CaseIterable, Identifiable {
        case md5 = "MD5", sha1 = "SHA-1", sha256 = "SHA-256", sha512 = "SHA-512"
        case b64enc = "Base64 ↑", b64dec = "Base64 ↓"
        case urlenc = "URL ↑", urldec = "URL ↓"
        case hexenc = "Hex ↑", hexdec = "Hex ↓"
        var id: String { rawValue }
    }

    private var output: String {
        guard !input.isEmpty else { return "" }
        switch selected {
        case .md5: return CryptoTools.md5(input)
        case .sha1: return CryptoTools.sha1(input)
        case .sha256: return CryptoTools.sha256(input)
        case .sha512: return CryptoTools.sha512(input)
        case .b64enc: return CryptoTools.base64Encode(input)
        case .b64dec: return CryptoTools.base64Decode(input)
        case .urlenc: return CryptoTools.urlEncode(input)
        case .urldec: return CryptoTools.urlDecode(input)
        case .hexenc: return CryptoTools.hexEncode(input)
        case .hexdec: return CryptoTools.hexDecode(input)
        }
    }

    private var entropy: Double { CryptoTools.passwordEntropy(input) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Input").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        TextEditor(text: $input)
                            .font(Theme.monoSmall)
                            .frame(minHeight: 90)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(Theme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Operation").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92))], spacing: 8) {
                            ForEach(Operation.allCases) { op in
                                Button {
                                    selected = op
                                } label: {
                                    Text(op.rawValue)
                                        .font(.caption.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(selected == op ? Theme.accent.opacity(0.22) : Theme.background)
                                        .foregroundStyle(selected == op ? Theme.accent : .white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if !output.isEmpty {
                    Panel {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Output").font(.headline).foregroundStyle(Theme.accent)
                            Text(output).font(Theme.monoSmall).foregroundStyle(.white).textSelection(.enabled)
                        }
                    }
                }

                if !input.isEmpty {
                    Panel {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Password entropy").font(.headline).foregroundStyle(.white)
                                Spacer()
                                TagLabel(text: "\(Int(entropy)) bits", color: entropyColor)
                            }
                            Text(entropyLabel).font(.footnote).foregroundStyle(entropyColor)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private var entropyColor: Color {
        if entropy < 40 { return Theme.danger }
        if entropy < 70 { return Theme.warning }
        return Theme.accent
    }
    private var entropyLabel: String {
        if entropy < 40 { return "Weak — easily cracked." }
        if entropy < 70 { return "Medium — make it longer/more complex." }
        return "Strong."
    }
}
