import Foundation

/// The app's own backend, which signs users in and holds what the app must never contain: the
/// identity secret and the Brudcast API key. The README lists the endpoints it needs.
struct SampleBackend {
    /// What the backend returns at sign-in, ready for `Brudcast.identify`.
    struct SignedIn: Decodable {
        let externalId: String
        let userHash: String
        let email: String?
    }

    struct Failure: LocalizedError {
        let message: String

        var errorDescription: String? { message }
    }

    let baseURL: URL

    /// Signs a user in. The backend computes the user hash with the identity secret.
    ///
    /// - Parameters:
    ///   - userId: The user's id.
    ///   - email: The user's email, for the contact Brudcast creates.
    /// - Returns: The external id and user hash to identify with.
    func login(userId: String, email: String?) async throws -> SignedIn {
        let data = try await post("login", body: ["userId": userId, "email": email ?? NSNull()])
        return try JSONDecoder().decode(SignedIn.self, from: data)
    }

    /// Asks the backend to send the user a welcome in-app message through the Brudcast API.
    ///
    /// - Parameter externalId: The user's external id.
    func sendWelcome(externalId: String) async throws {
        _ = try await post("welcome", body: ["externalId": externalId])
    }

    private func post(_ path: String, body: [String: Any]) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
            throw Failure(message: message ?? "HTTP \(status)")
        }
        return data
    }
}
