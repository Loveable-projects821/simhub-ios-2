import SwiftUI

@main
struct SimHubApp: App {
    @StateObject private var hub = HubConnection()
    @State private var activeCallNumber: String? = nil

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(hub)

                if let number = activeCallNumber {
                    CallInProgressView(number: number) {
                        WebRTCClient.shared.endCall()
                        hub.endCall()
                        CallKitManager.shared.endReportedCall()
                        activeCallNumber = nil
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .onAppear {
                WebRTCClient.shared.attach(hub: hub)

                hub.onIncomingCall = { event in
                    CallKitManager.shared.reportIncomingCall(from: event.number)
                }
                hub.onCallEnded = {
                    WebRTCClient.shared.endCall()
                    CallKitManager.shared.endReportedCall()
                    activeCallNumber = nil
                }
                CallKitManager.shared.onAnswer = {
                    WebRTCClient.shared.startAsAnswerer()
                    hub.answerCall()
                    if let latest = hub.callEvents.first {
                        activeCallNumber = latest.number
                    }
                }
                CallKitManager.shared.onEnd = {
                    WebRTCClient.shared.endCall()
                    hub.endCall()
                    activeCallNumber = nil
                }
            }
        }
    }
}
