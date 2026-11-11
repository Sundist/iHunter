import SwiftUI

struct StationControlView: View {
    @StateObject private var station = StationControl()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
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
                        SecureField("Token (X-Station-Token)", text: $station.token)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Text("Runs the Pi-side agent (docs/station-agent). Connect the iPhone to the Pi's hotspot first.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Actions").font(.headline).foregroundStyle(Theme.accent)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                            actionButton("Status", "gauge.with.dots.needle.33percent") {
                                station.call("Status", path: "/status")
                            }
                            actionButton("Interfaces", "network") {
                                station.call("Interfaces", path: "/interfaces")
                            }
                            actionButton("Services", "gearshape.2") {
                                station.call("Services", path: "/services")
                            }
                            actionButton("Monitor ▶", "dot.radiowaves.left.and.right") {
                                station.call("Start monitor", path: "/monitor/start", method: "POST")
                            }
                            actionButton("Monitor ■", "stop.circle") {
                                station.call("Stop monitor", path: "/monitor/stop", method: "POST")
                            }
                            actionButton("Scan APs", "wifi") {
                                station.call("Scan APs", path: "/scan/aps", timeout: 60)
                            }
                        }
                    }
                }

                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("nmap (via Pi)").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        HStack {
                            TextField("target (lab host/IP)", text: $station.nmapTarget)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            Button("Run") { station.runNmap() }
                                .buttonStyle(.borderedProminent)
                                .disabled(station.busy)
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
                            Text("Tap an action. Responses appear here, newest first.")
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

    private func actionButton(_ title: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.accent.opacity(0.12))
            .foregroundStyle(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(station.busy)
    }
}
