import Foundation

/// Matches the JSON shapes broadcast by the Android WsServer.
/// Kept as loose dictionaries-in, typed-structs-out since the "type" field
/// discriminates the shape and Swift's Codable doesn't do that gracefully by default.

struct SignalEvent: Identifiable {
    let id = UUID()
    let slot: Int
    let carrier: String
    let level: Int          // 0 (none) ... 4 (great)
    let timestamp: Date

    init?(json: [String: Any]) {
        guard let slot = json["slot"] as? Int,
              let carrier = json["carrier"] as? String,
              let level = json["level"] as? Int,
              let ts = json["timestamp"] as? Double else { return nil }
        self.slot = slot
        self.carrier = carrier
        self.level = level
        self.timestamp = Date(timeIntervalSince1970: ts / 1000)
    }
}

struct CallEvent: Identifiable {
    let id = UUID()
    let state: String       // "ringing" | "answered" | "ended"
    let number: String
    let timestamp: Date

    init?(json: [String: Any]) {
        guard let state = json["state"] as? String,
              let number = json["number"] as? String,
              let ts = json["timestamp"] as? Double else { return nil }
        self.state = state
        self.number = number
        self.timestamp = Date(timeIntervalSince1970: ts / 1000)
    }
}

struct HubContact: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var number: String
    var source: String   // "iphone" | "android"

    init?(json: [String: Any]) {
        guard let name = json["name"] as? String,
              let number = json["number"] as? String else { return nil }
        self.name = name
        self.number = number
        self.source = "android"
    }

    init(name: String, number: String, source: String) {
        self.name = name
        self.number = number
        self.source = source
    }
}

struct SmsEvent: Identifiable {
    let id = UUID()
    let from: String
    let body: String
    let timestamp: Date

    init?(json: [String: Any]) {
        guard let from = json["from"] as? String,
              let body = json["body"] as? String,
              let ts = json["timestamp"] as? Double else { return nil }
        self.from = from
        self.body = body
        self.timestamp = Date(timeIntervalSince1970: ts / 1000)
    }
}
