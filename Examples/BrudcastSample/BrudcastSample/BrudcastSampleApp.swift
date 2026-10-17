import SwiftUI

@main
struct BrudcastSampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    ActionLog.shared.record(openedURL: url)
                    SampleRouter.shared.open(url)
                }
        }
    }
}
