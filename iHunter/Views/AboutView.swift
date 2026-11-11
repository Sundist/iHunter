import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iHunter").font(.title2.weight(.bold)).foregroundStyle(Theme.accent)
                        Text("iOS güvenlik & ağ araç seti · v1.0")
                            .font(.footnote).foregroundStyle(.secondary)
                        Text("Kali NetHunter'dan ilham alır, ancak iOS sandbox'ının izin verdiği (root gerektirmeyen) keşif ve analiz araçlarını sağlar.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Neden NetHunter birebir port edilemez?", systemImage: "questionmark.circle")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        bullet("iOS kapalı bir sandbox'tır; root/kernel erişimi yoktur.")
                        bullet("Wi-Fi radyosu monitor mode / paket enjeksiyonuna açılmaz.")
                        bullet("USB HID, özel kernel, ham soket araçları çalışamaz.")
                        bullet("App Store bu tür araçları dağıtıma kabul etmez.")
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Yasal & etik", systemImage: "scalemass")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.warning)
                        Text("Bu araç yalnızca yetkili güvenlik testi, eğitim ve CTF içindir. İzinsiz tarama ve erişim yasa dışıdır ve kullanıcının sorumluluğundadır.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Hakkında")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").foregroundStyle(Theme.accent)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }
}
