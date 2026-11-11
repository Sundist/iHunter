import SwiftUI

struct DNSView: View {
    @State private var query = ""
    @State private var records: [DNSRecord] = []
    @State private var reverse: String?
    @State private var isWorking = false
    @State private var searched = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Alan adı veya IP").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        TextField("example.com", text: $query)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onSubmit(run)
                        HStack {
                            Spacer()
                            Button(action: run) {
                                if isWorking { ProgressView() } else { Text("Çözümle") }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(query.isEmpty || isWorking)
                        }
                    }
                }

                if !records.isEmpty {
                    Panel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kayıtlar").font(.headline).foregroundStyle(Theme.accent)
                            ForEach(records) { r in
                                HStack {
                                    TagLabel(text: r.type, color: r.type == "A" ? Theme.accent : Theme.info)
                                    Text(r.value).font(Theme.monoSmall).foregroundStyle(.white)
                                        .textSelection(.enabled)
                                    Spacer()
                                }
                            }
                        }
                    }
                }

                if let reverse {
                    Panel {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ters DNS (PTR)").font(.headline).foregroundStyle(Theme.info)
                            Text(reverse).font(Theme.monoSmall).foregroundStyle(.white).textSelection(.enabled)
                        }
                    }
                }

                if searched && records.isEmpty && reverse == nil && !isWorking {
                    Panel {
                        Label("Sonuç bulunamadı.", systemImage: "questionmark.circle")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func run() {
        let host = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !host.isEmpty else { return }
        isWorking = true
        records = []
        reverse = nil
        searched = true
        Task {
            let resolved = await DNSResolver.resolve(host: host)
            var ptr: String?
            if SubnetCalculator.parseIPv4(host) != nil {
                ptr = await DNSResolver.reverse(ip: host)
            }
            await MainActor.run {
                records = resolved
                reverse = ptr
                isWorking = false
            }
        }
    }
}
