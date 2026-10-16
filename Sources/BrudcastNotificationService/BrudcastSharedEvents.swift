import Foundation

/// A file in an App Group where a notification service extension leaves events for the app to send.
///
/// The extension cannot open a session, so it records what it saw and the app's push module sends
/// it on the next launch or foreground.
public enum BrudcastSharedEvents {
    static let directoryName = "Brudcast"
    static let fileName = "push_events.json"
    static let maxEvents = 200

    /// Appends an event.
    ///
    /// - Parameters:
    ///   - type: The event type, such as `push_received`.
    ///   - messageId: The Brudcast message id from the payload.
    ///   - properties: String properties.
    ///   - appGroupIdentifier: The App Group shared by the app and the extension.
    ///   - occurredAt: When it happened.
    public static func append(type: String, messageId: String, properties: [String: String] = [:], appGroupIdentifier: String, occurredAt: Date = Date()) {
        guard let url = fileURL(appGroupIdentifier) else { return }
        let event: [String: Any] = [
            "id": UUID().uuidString.lowercased(),
            "type": type,
            "messageId": messageId,
            "properties": properties,
            "occurredAt": format(occurredAt),
        ]
        coordinate(url) { target in
            var events = read(target)
            events.append(event)
            if events.count > maxEvents {
                events.removeFirst(events.count - maxEvents)
            }
            write(events, to: target)
        }
    }

    /// Takes every waiting event and empties the file.
    ///
    /// - Parameter appGroupIdentifier: The App Group shared by the app and the extension.
    /// - Returns: The events, oldest first, as JSON objects.
    public static func drain(appGroupIdentifier: String) -> [[String: Any]] {
        guard let url = fileURL(appGroupIdentifier) else { return [] }
        var drained: [[String: Any]] = []
        coordinate(url) { target in
            drained = read(target)
            if !drained.isEmpty {
                try? FileManager.default.removeItem(at: target)
            }
        }
        return drained
    }

    static func fileURL(_ appGroupIdentifier: String) -> URL? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            return nil
        }
        let directory = container.appendingPathComponent(directoryName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(fileName)
    }

    private static func coordinate(_ url: URL, _ body: (URL) -> Void) {
        var error: NSError?
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url, options: [], error: &error) { target in
            body(target)
        }
    }

    private static func read(_ url: URL) -> [[String: Any]] {
        guard let data = try? Data(contentsOf: url),
              let events = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
            return []
        }
        return events
    }

    private static func write(_ events: [[String: Any]], to url: URL) {
        guard let data = try? JSONSerialization.data(withJSONObject: events, options: []) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    private static func format(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
