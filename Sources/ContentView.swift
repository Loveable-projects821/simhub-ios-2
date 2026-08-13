import SwiftUI

struct ContentView: View {
    @EnvironmentObject var hub: HubConnection
    @State private var ipAddress: String = ""
    @State private var pin: String = ""

    var body: some View {
        if hub.state == .paired {
            MainTabView()
        } else {
            PairingView(ipAddress: $ipAddress, pin: $pin)
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationView { KeypadView() }
                .tabItem { Label("Keypad", systemImage: "circle.grid.3x3.fill") }

            NavigationView { RecentsView() }
                .tabItem { Label("Recents", systemImage: "clock.fill") }

            NavigationView { ContactsView() }
                .tabItem { Label("Contacts", systemImage: "person.crop.circle.fill") }

            NavigationView { MessagesView() }
                .tabItem { Label("Messages", systemImage: "message.fill") }

            NavigationView { StatusView() }
                .tabItem { Label("Signal", systemImage: "antenna.radiowaves.left.and.right") }
        }
    }
}

struct StatusView: View {
    @EnvironmentObject var hub: HubConnection

    var body: some View {
        List {
            Section("SIM Signal") {
                if hub.signalEvents.isEmpty {
                    Text("Waiting for signal data…").foregroundColor(.secondary)
                }
                ForEach(hub.signalEvents.keys.sorted(), id: \.self) { slot in
                    if let event = hub.signalEvents[slot] {
                        HStack {
                            Text("SIM \(slot + 1) — \(event.carrier)")
                            Spacer()
                            SignalBars(level: event.level)
                        }
                    }
                }
            }
            Section {
                Button("Disconnect", role: .destructive) { hub.disconnect() }
            }
        }
        .navigationTitle("Signal")
    }
}

struct PairingView: View {
    @EnvironmentObject var hub: HubConnection
    @Binding var ipAddress: String
    @Binding var pin: String

    var body: some View {
        VStack(spacing: 20) {
            Text("Connect to your Android hub").font(.headline)
            Text("Join the Android's hotspot WiFi first, then enter the IP and PIN shown on its screen.")
                .font(.caption).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)

            TextField("Android IP (e.g. 192.168.43.1)", text: $ipAddress)
                .textFieldStyle(.roundedBorder).keyboardType(.numbersAndPunctuation)
                .autocapitalization(.none).padding(.horizontal)

            TextField("6-digit PIN", text: $pin)
                .textFieldStyle(.roundedBorder).keyboardType(.numberPad).padding(.horizontal)

            statusLabel

            Button("Connect") { hub.connect(ip: ipAddress, pin: pin) }
                .buttonStyle(.borderedProminent)
                .disabled(ipAddress.isEmpty || pin.count != 6)
        }
        .padding()
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch hub.state {
        case .connecting: Text("Connecting…").foregroundColor(.orange)
        case .awaitingPin: Text("Verifying PIN…").foregroundColor(.orange)
        case .wrongPin: Text("Wrong PIN — check the Android screen").foregroundColor(.red)
        case .error(let msg): Text("Error: \(msg)").foregroundColor(.red)
        default: EmptyView()
        }
    }
}

struct SignalBars: View {
    let level: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < level ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 4, height: CGFloat(6 + i * 4))
            }
        }
    }
}
