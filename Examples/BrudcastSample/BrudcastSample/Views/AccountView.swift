import SwiftUI
import Brudcast
import BrudcastInApp
import BrudcastPush

/// The user's account: notification and message settings, the actions messages handed the app,
/// tools for sending any event, build details, and sign-out.
struct AccountView: View {
    let user: SampleSession.User
    @ObservedObject private var log = ActionLog.shared
    @State private var permission = BrudcastPushPermission.notDetermined
    @State private var paused = false
    @State private var eventName = "checkout_started"
    @State private var property = "product"
    @State private var propertyValue = "sneakers"
    @State private var screenName = "Checkout"

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                PageHeader(title: user.externalId, description: user.email ?? "No email")
                SectionBlock(
                    title: "Notifications",
                    description: "Tokens register only once you add Firebase Messaging and pass its token to Brudcast.push.setToken. See the README."
                ) {
                    DetailRow(label: "Permission", value: permission.rawValue)
                    Button("Allow notifications") { Brudcast.push.requestPermission() }
                        .buttonStyle(OutlineButtonStyle())
                }
                Rule()
                SectionBlock(title: "In-app messages", description: "Pause to hold messages back, such as during onboarding.") {
                    Toggle("Pause display", isOn: $paused)
                        .font(Typography.body)
                        .tint(Palette.primary)
                        .onChange(of: paused) { isPaused in
                            if isPaused {
                                Brudcast.inApp.pauseDisplay()
                            } else {
                                Brudcast.inApp.resumeDisplay()
                            }
                        }
                    Button("Sync now") { Brudcast.inApp.sync() }
                        .buttonStyle(OutlineButtonStyle())
                }
                Rule()
                SectionBlock(title: "Activity", description: "Buttons in messages and notification taps the app was handed, newest first.") {
                    if log.entries.isEmpty {
                        Text("Nothing yet. Tap a button in a message.")
                            .font(Typography.description)
                            .foregroundStyle(Palette.foregroundSubtle)
                    }
                    ForEach(Array(log.entries.enumerated()), id: \.offset) { _, entry in
                        Text(entry).font(Typography.description)
                            .accessibilityIdentifier("actionLogEntry")
                    }
                }
                Rule()
                developerSection
                Rule()
                SectionBlock(title: "About this build") {
                    DetailRow(label: "Environment", value: SampleConfig.environmentName)
                    DetailRow(label: "SDK running", value: Brudcast.isInitialized ? "Yes" : "No")
                    DetailRow(label: "Device id", value: Brudcast.deviceId ?? "-")
                }
                Rule()
                Button("Sign out") { SampleSession.shared.signOut() }
                    .buttonStyle(OutlineButtonStyle(fullWidth: true, destructive: true))
                    .accessibilityIdentifier("signOutButton")
                    .padding(20)
            }
        }
        .background(Palette.background)
        .trackScreen("Account")
        .onReceive(Brudcast.push.permissionPublisher) { permission = $0 }
    }

    private var developerSection: some View {
        SectionBlock(title: "Developer tools", description: "Send any event or screen to try a campaign's trigger and filters.") {
            Field(label: "Event name", text: $eventName)
            HStack(spacing: 8) {
                Field(label: "Property", text: $property)
                Field(label: "Value", text: $propertyValue)
            }
            Button("Track event") {
                var properties: BrudcastProperties = [:]
                let key = property.trimmingCharacters(in: .whitespaces)
                if !key.isEmpty {
                    properties[key] = Double(propertyValue).map(BrudcastValue.number) ?? .string(propertyValue)
                }
                Brudcast.track(eventName, properties: properties)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!Brudcast.isValidEventName(eventName))
            Field(label: "Screen name", text: $screenName)
            Button("Record screen") { Brudcast.screen(screenName) }
                .buttonStyle(OutlineButtonStyle())
                .disabled(screenName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
