import SwiftUI

struct RecentsView: View {
    @EnvironmentObject var hub: HubConnection

    var body: some View {
        List(hub.callEvents) { call in
            HStack {
                Image(systemName: call.state == "ended" ? "phone.arrow.up.right" : "phone.fill.arrow.down.left")
                    .foregroundColor(call.state == "ringing" ? .green : .secondary)
                VStack(alignment: .leading) {
                    Text(call.number.isEmpty ? "Unknown" : call.number)
                        .font(.body)
                    Text(call.state.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(call.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .overlay {
            if hub.callEvents.isEmpty {
                Text("No recent calls").foregroundColor(.secondary)
            }
        }
    }
}
