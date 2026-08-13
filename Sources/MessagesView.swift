import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var hub: HubConnection
    @State private var showCompose = false

    private var conversations: [String: [SmsEvent]] {
        Dictionary(grouping: hub.smsEvents, by: { $0.from })
    }

    var body: some View {
        List {
            ForEach(conversations.keys.sorted(), id: \.self) { sender in
                if let latest = conversations[sender]?.first {
                    NavigationLink(destination: ConversationView(number: sender, messages: conversations[sender] ?? [])) {
                        VStack(alignment: .leading) {
                            Text(sender).font(.headline)
                            Text(latest.body).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                        }
                    }
                }
            }
        }
        .overlay {
            if hub.smsEvents.isEmpty {
                Text("No messages yet").foregroundColor(.secondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showCompose = true } label: { Image(systemName: "square.and.pencil") }
            }
        }
        .sheet(isPresented: $showCompose) {
            ComposeMessageView()
        }
    }
}

struct ConversationView: View {
    @EnvironmentObject var hub: HubConnection
    let number: String
    let messages: [SmsEvent]
    @State private var draft: String = ""

    var body: some View {
        VStack {
            List(messages.reversed()) { msg in
                HStack {
                    Text(msg.body)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    Spacer()
                }
            }
            HStack {
                TextField("Message", text: $draft)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    guard !draft.isEmpty else { return }
                    hub.sendSms(to: number, body: draft)
                    draft = ""
                }
            }
            .padding()
        }
        .navigationTitle(number)
    }
}

struct ComposeMessageView: View {
    @EnvironmentObject var hub: HubConnection
    @Environment(\.dismiss) var dismiss
    @State private var number = ""
    @State private var messageBody = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("To", text: $number).keyboardType(.phonePad)
                TextField("Message", text: $messageBody)
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        hub.sendSms(to: number, body: messageBody)
                        dismiss()
                    }
                    .disabled(number.isEmpty || messageBody.isEmpty)
                }
            }
        }
    }
}
