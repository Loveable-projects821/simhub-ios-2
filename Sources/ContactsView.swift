import SwiftUI

struct ContactsView: View {
    @EnvironmentObject var hub: HubConnection
    @StateObject private var contactsManager = ContactsManager()

    var body: some View {
        List(contactsManager.mergedContacts) { contact in
            Button {
                WebRTCClient.shared.startAsCaller()
                hub.dial(number: contact.number)
            } label: {
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(Text(String(contact.name.prefix(1))).foregroundColor(.blue))
                    VStack(alignment: .leading) {
                        Text(contact.name).foregroundColor(.primary)
                        Text(contact.number).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(contact.source == "android" ? "Android" : "iPhone")
                        .font(.caption2)
                        .padding(4)
                        .background(Color(.tertiarySystemFill))
                        .cornerRadius(4)
                }
            }
        }
        .overlay {
            if contactsManager.mergedContacts.isEmpty {
                Text("No contacts synced yet").foregroundColor(.secondary)
            }
        }
        .onAppear {
            hub.requestContacts()
            contactsManager.requestAccessAndLoad(androidContacts: hub.androidContacts)
        }
        .onChange(of: hub.androidContacts) { newValue in
            contactsManager.merge(with: newValue)
        }
    }
}
