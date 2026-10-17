import Foundation
import Brudcast

/// The actions the SDK handed to the sample, newest first, for the screen to show.
final class ActionLog: ObservableObject {
    static let shared = ActionLog()

    private static let maxEntries = 20

    @Published private(set) var entries: [String] = []

    /// Adds an action to the log.
    ///
    /// - Parameter action: The action.
    func record(_ action: BrudcastAction) {
        let source: String
        switch action.source {
        case .inApp(let messageId, _):
            source = "in-app \(messageId)"
        case .push(let messageId):
            source = "push \(messageId)"
        }
        append("\(action.kind.rawValue) \(action.value) (\(source))")
    }

    /// Adds a URL the system opened the app with, such as a `brudcast-sample:` link.
    ///
    /// - Parameter url: The URL.
    func record(openedURL url: URL) {
        append("opened \(url.absoluteString)")
    }

    private func append(_ line: String) {
        DispatchQueue.main.async {
            self.entries = Array(([line] + self.entries).prefix(Self.maxEntries))
        }
    }
}
