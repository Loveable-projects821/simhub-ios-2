import Foundation
import Contacts

/// Merges iPhone's own address book with contacts relayed from Android.
/// Gmail contacts are NOT included here — syncing a Google account's contacts
/// requires Google Sign-In + the People API, which means talking to Google's
/// servers (can't be done locally/offline). Flagged as a future add-on rather
/// than silently left out — see README.
final class ContactsManager: ObservableObject {

    @Published var iphoneContacts: [HubContact] = []
    @Published var mergedContacts: [HubContact] = []

    private let store = CNContactStore()

    func requestAccessAndLoad(androidContacts: [HubContact]) {
        store.requestAccess(for: .contacts) { [weak self] granted, _ in
            guard granted, let self = self else { return }
            self.loadIphoneContacts()
            DispatchQueue.main.async {
                self.merge(with: androidContacts)
            }
        }
    }

    private func loadIphoneContacts() {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var results: [HubContact] = []

        try? store.enumerateContacts(with: request) { contact, _ in
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            for phone in contact.phoneNumbers {
                results.append(HubContact(name: name.isEmpty ? "Unknown" : name,
                                           number: phone.value.stringValue,
                                           source: "iphone"))
            }
        }

        DispatchQueue.main.async {
            self.iphoneContacts = results
        }
    }

    /// Combines both sources, de-duplicating by phone number (last-digits match).
    func merge(with androidContacts: [HubContact]) {
        var seenNumbers = Set<String>()
        var combined: [HubContact] = []

        for contact in (iphoneContacts + androidContacts) {
            let normalized = String(contact.number.filter(\.isNumber).suffix(10))
            if normalized.isEmpty || !seenNumbers.contains(normalized) {
                if !normalized.isEmpty { seenNumbers.insert(normalized) }
                combined.append(contact)
            }
        }

        mergedContacts = combined.sorted { $0.name < $1.name }
    }
}
