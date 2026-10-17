import Foundation
import BrudcastNotificationService

/// Attaches notification images and records deliveries for the app to send, through the App Group
/// the app and this extension share.
final class NotificationService: BrudcastNotificationServiceExtension {
    override var appGroupIdentifier: String? {
        Bundle.main.object(forInfoDictionaryKey: "BrudcastAppGroup") as? String
    }
}
