import Foundation
import Brudcast

/// The app's own record of who is signed in, the way any app keeps its login. Signing in and out
/// here is also where the app tells Brudcast, so the two never disagree. Brudcast restores its own
/// identity at launch; this only decides which screen the app starts on.
final class SampleSession: ObservableObject {
    /// The signed-in user.
    struct User: Equatable {
        let externalId: String
        let email: String?
    }

    static let shared = SampleSession()

    private static let externalIdKey = "sample.session.externalId"
    private static let emailKey = "sample.session.email"

    private let defaults = UserDefaults.standard

    @Published private(set) var current: User?

    private init() {
        current = defaults.string(forKey: Self.externalIdKey).map { User(externalId: $0, email: defaults.string(forKey: Self.emailKey)) }
    }

    /// Signs a user in and identifies them to Brudcast.
    ///
    /// - Parameters:
    ///   - externalId: The user's id in the app.
    ///   - userHash: The hash the app's backend computed with the identity secret, or nil when the
    ///     application does not enforce identity verification.
    ///   - email: The user's email, for the contact Brudcast creates.
    func signIn(externalId: String, userHash: String?, email: String?) {
        Brudcast.identify(externalId: externalId, userHash: userHash, traits: BrudcastTraits(email: email))
        defaults.set(externalId, forKey: Self.externalIdKey)
        defaults.set(email, forKey: Self.emailKey)
        current = User(externalId: externalId, email: email)
    }

    /// Signs the user out and resets Brudcast, which clears their messages from the device.
    func signOut() {
        Brudcast.reset()
        defaults.removeObject(forKey: Self.externalIdKey)
        defaults.removeObject(forKey: Self.emailKey)
        current = nil
    }
}
