import UIKit
import Brudcast
import BrudcastInApp
import BrudcastPush

/// Starts the SDK the way an app should: once, at launch, with the publishable key and environment
/// from `Config/Local.xcconfig`.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        guard let key = SampleConfig.publishableKey else {
            print("Set BRUDCAST_PUBLISHABLE_KEY in Config/Local.xcconfig to start the SDK")
            return true
        }
        Brudcast.setActionHandler(handle)
        Brudcast.initialize(
            publishableKey: key,
            options: BrudcastOptions(
                environment: SampleConfig.environment,
                logLevel: .debug,
                modules: [BrudcastInApp.module, BrudcastPush.module],
                appGroupIdentifier: SampleConfig.appGroup,
                accentColor: Palette.primaryUIColor
            )
        )
        Brudcast.push.installNotificationDelegate()
        return true
    }

    /// Records every action in the activity log, and routes the sample's own deep links to its
    /// screens, such as `brudcast-sample://checkout`.
    ///
    /// - Parameter action: The action from an in-app button or a push tap.
    /// - Returns: `.handled` for `brudcast-sample:` links, the default behaviour for everything else.
    private func handle(_ action: BrudcastAction) -> BrudcastActionResult {
        ActionLog.shared.record(action)
        guard action.kind == .deeplink, action.value.hasPrefix("\(SampleConfig.deepLinkScheme):") else { return .useDefault }
        if let url = URL(string: action.value) {
            SampleRouter.shared.open(url)
        }
        return .handled
    }
}
