import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iHunter").font(.title2.weight(.bold)).foregroundStyle(Theme.accent)
                        Text("iOS security & network toolkit · v1.0")
                            .font(.footnote).foregroundStyle(.secondary)
                        Text("Inspired by Kali NetHunter, but provides the recon and analysis tools that the iOS sandbox allows (no root required).")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Why can't NetHunter be ported 1:1?", systemImage: "questionmark.circle")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        bullet("iOS is a closed sandbox; there is no root/kernel access.")
                        bullet("The Wi-Fi radio is never opened for monitor mode / packet injection.")
                        bullet("USB HID, custom kernels, and raw-socket tools cannot run.")
                        bullet("The App Store does not accept tools of this kind for distribution.")
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Legal & ethical", systemImage: "scalemass")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.warning)
                        Text("This tool is for authorized security testing, education, and CTF only. Unauthorized scanning and access is illegal and is the user's responsibility.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").foregroundStyle(Theme.accent)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }
}
