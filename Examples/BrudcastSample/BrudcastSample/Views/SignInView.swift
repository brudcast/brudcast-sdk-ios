import SwiftUI

/// Signs the user in. With a sample backend configured it signs in the way a real app does: the
/// backend checks the user and returns the user hash, so the identity secret never reaches the
/// device. Without one it takes a pasted hash.
struct SignInView: View {
    @State private var userId = ""
    @State private var userHash = ""
    @State private var email = ""
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Brudcast Sample").font(Typography.label).foregroundStyle(Palette.brand)
                Text("Sign in").font(Typography.pageTitle).tracking(-0.6)
                Text(
                    SampleConfig.sampleBackend == nil
                        ? "Paste the user hash your server computed. Without a backend, this is how you try identity verification."
                        : "Your backend checks who you are and returns the user hash Brudcast.identify needs."
                )
                .font(Typography.description)
                .foregroundStyle(Palette.mutedForeground)
                if SampleConfig.publishableKey == nil {
                    Notice(
                        text: "Set BRUDCAST_PUBLISHABLE_KEY in Config/Local.xcconfig, then rebuild. The SDK is not running.",
                        background: Palette.warning,
                        foreground: Palette.warningForeground
                    )
                }
                Group {
                    if let backend = SampleConfig.sampleBackend {
                        backendForm(backend)
                    } else {
                        manualForm
                    }
                }
                .padding(.vertical, 8)
                Text(footer).font(Typography.micro).foregroundStyle(Palette.foregroundSubtle)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 48)
        }
        .background(Palette.background)
        .trackScreen("SignIn")
    }

    private var footer: String {
        guard let backend = SampleConfig.sampleBackend else { return "Environment: \(SampleConfig.environmentName)" }
        return "Environment: \(SampleConfig.environmentName), backend: \(backend.baseURL.absoluteString)"
    }

    private func backendForm(_ backend: SampleBackend) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Field(label: "User id", text: $userId, placeholder: "e.g. ada-lovelace", identifier: "userIdField")
            Field(label: "Email", text: $email, placeholder: "ada@example.com", keyboard: .emailAddress, identifier: "emailField")
            if let error {
                Notice(text: error, background: Palette.destructive, foreground: Palette.destructiveForeground)
            }
            Button(busy ? "Signing in…" : "Sign in") {
                let id = userId.trimmingCharacters(in: .whitespaces)
                let address = email.trimmingCharacters(in: .whitespaces)
                busy = true
                error = nil
                Task {
                    do {
                        let user = try await backend.login(userId: id, email: address.isEmpty ? nil : address)
                        SampleRouter.shared.reset()
                        SampleSession.shared.signIn(externalId: user.externalId, userHash: user.userHash, email: user.email)
                    } catch {
                        self.error = "Sign-in failed: \(error.localizedDescription)"
                    }
                    busy = false
                }
            }
            .buttonStyle(PrimaryButtonStyle(fullWidth: true))
            .disabled(userId.trimmingCharacters(in: .whitespaces).isEmpty || busy)
            .accessibilityIdentifier("signInButton")
        }
    }

    private var manualForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Field(label: "External id", text: $userId)
            Field(label: "User hash", text: $userHash, placeholder: "From your server")
            Field(label: "Email", text: $email, keyboard: .emailAddress)
            Button("Sign in") {
                let hash = userHash.trimmingCharacters(in: .whitespaces)
                let address = email.trimmingCharacters(in: .whitespaces)
                SampleRouter.shared.reset()
                SampleSession.shared.signIn(
                    externalId: userId.trimmingCharacters(in: .whitespaces),
                    userHash: hash.isEmpty ? nil : hash,
                    email: address.isEmpty ? nil : address
                )
            }
            .buttonStyle(PrimaryButtonStyle(fullWidth: true))
            .disabled(userId.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
