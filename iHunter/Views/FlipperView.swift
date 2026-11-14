import SwiftUI

/// Flipper panel. The Flipper is connected to the Pi over USB; iHunter drives it
/// through the same station agent (shared host/port/token with Station Control).
struct FlipperView: View {
    @StateObject private var station = StationControl()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "dolphin.fill").foregroundStyle(Theme.info)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Flipper via Pi agent").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                            Text("Connect the Flipper to the Pi over USB-C. Uses the same agent as Station Control (needs python3-serial on the Pi).")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pi station agent").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        HStack {
                            TextField("10.42.0.1", text: $station.host)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numbersAndPunctuation)
                                .autocorrectionDisabled()
                            TextField("8777", text: $station.port)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                        }
                        SecureField("Token", text: $station.token)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Device").font(.headline).foregroundStyle(Theme.accent)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                            action("Info", "info.circle") {
                                station.call("Flipper info", path: "/flipper/info", timeout: 15)
                            }
                            action("Battery", "battery.75") {
                                station.call("Flipper battery", path: "/flipper/battery", timeout: 15)
                            }
                        }
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Storage").font(.headline).foregroundStyle(Theme.accent)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                            action("Sub-GHz", "dot.radiowaves.right") { storage("/ext/subghz") }
                            action("RFID", "wave.3.right") { storage("/ext/lfrfid") }
                            action("NFC", "wave.3.forward") { storage("/ext/nfc") }
                            action("Infrared", "rays") { storage("/ext/infrared") }
                            action("iButton", "key") { storage("/ext/ibutton") }
                            action("Root", "folder") { storage("/ext") }
                        }
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Output").font(.headline).foregroundStyle(.white)
                            if station.busy { ProgressView().scaleEffect(0.8) }
                            Spacer()
                            Button("Clear") { station.clear() }.font(.caption).buttonStyle(.bordered)
                        }
                        if station.log.isEmpty {
                            Text("Tap an action. Reads your own Flipper over the Pi, newest first.")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text(station.log)
                                .font(Theme.monoSmall)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func storage(_ path: String) {
        station.call("ls \(path)", path: "/flipper/storage", query: ["path": path], timeout: 15)
    }

    private func action(_ title: String, _ icon: String, _ run: @escaping () -> Void) -> some View {
        Button(action: run) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.info.opacity(0.12))
            .foregroundStyle(Theme.info)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(station.busy)
    }
}
