import SwiftUI
import Brudcast
import BrudcastInApp

/// Where a signed-in user lands: their message counts, a welcome message their backend sends, and a
/// way into the shop to set off campaigns.
struct HomeView: View {
    let user: SampleSession.User
    @ObservedObject private var log = ActionLog.shared
    @State private var unread = Brudcast.inApp.inbox.unreadCount
    @State private var status: String?
    @State private var failed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome back").font(Typography.pageTitle).tracking(-0.6)
                    Text(user.email ?? user.externalId).font(Typography.description).foregroundStyle(Palette.mutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                MetricLedger(metrics: [("Unread messages", unread), ("Actions received", log.entries.count)])
                welcomeSection
                Rule()
                SectionBlock(title: "Inbox", description: "Messages sent with an inbox copy stay here after they close.") {
                    Button("Open inbox") { Brudcast.inApp.inbox.present() }
                        .buttonStyle(OutlineButtonStyle())
                }
                Rule()
                SectionBlock(
                    title: "Set off a campaign",
                    description: "Campaigns triggered by the checkout_started event or the Checkout screen show while you shop."
                ) {
                    Button("Go to the shop") { SampleRouter.shared.tab = .shop }
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .background(Palette.background)
        .trackScreen("Home")
        .onReceive(Brudcast.inApp.inbox.unreadCountPublisher) { unread = $0 }
    }

    /// Asks the app's backend to send the user a welcome message through the Brudcast API, the way a
    /// product sends transactional messages.
    private var welcomeSection: some View {
        SectionBlock(title: "Welcome message", description: "Your backend sends it through the Brudcast API and it shows here at once.") {
            if let backend = SampleConfig.sampleBackend {
                Button("Send me a welcome") {
                    Task {
                        do {
                            try await backend.sendWelcome(externalId: user.externalId)
                            status = "Sent. It shows as soon as it arrives."
                            failed = false
                        } catch {
                            status = "Sending failed: \(error.localizedDescription)"
                            failed = true
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("sendWelcomeButton")
                if let status {
                    Text(status)
                        .font(Typography.description)
                        .foregroundStyle(failed ? Palette.destructiveForeground : Palette.mutedForeground)
                }
            } else {
                Text("Add SAMPLE_BACKEND_URL to Config/Local.xcconfig to send one.")
                    .font(Typography.description)
                    .foregroundStyle(Palette.mutedForeground)
            }
        }
    }
}
