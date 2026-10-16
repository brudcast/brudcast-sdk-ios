# Brudcast iOS SDK

In-app messaging and push notifications for iOS apps on Brudcast. iOS 14 and later, Swift Package
Manager.

| Product                       | What it does                                                                                                                       |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `Brudcast`                    | Core: configuration, device id, sessions, identity, the event queue, the action handler. Always needed                             |
| `BrudcastInApp`               | In-app messages: sync, the live stream, triggers, display rules, native modal, banner and full screen rendering, the inbox         |
| `BrudcastPush`                | Push: permission, FCM token registration for the signed-in user, foreground presentation, open tracking                            |
| `BrudcastNotificationService` | For a notification service extension: attaches notification images and records `push_received`                                   |

A push-only app links `Brudcast` and `BrudcastPush` and never ships the renderer.

## Install

Add `https://github.com/brudcast/brudcast-sdk-ios` in Xcode (File > Add Package Dependencies) and pick
the products you need.

## Start

```swift
import Brudcast
import BrudcastInApp
import BrudcastPush

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    Brudcast.initialize(
        publishableKey: "bpk_...",
        options: BrudcastOptions(
            environment: .production,
            modules: [BrudcastInApp.module, BrudcastPush.module],
            appGroupIdentifier: "group.com.example.app"
        )
    )
    return true
}
```

The publishable key is public by design. Never put the application's identity secret in the app.

## Identify the user

Compute the user hash on your server and hand it to the app with the user's session:

```txt
userHash = hex(HMAC-SHA256(identitySecret, externalId))
```

```swift
Brudcast.identify(externalId: user.id, userHash: user.brudcastHash, traits: BrudcastTraits(email: user.email))
```

Call `Brudcast.reset()` on logout. The device keeps its id, and its push token stops reaching the
previous user. An application that enforces identity verification refuses a wrong hash; the SDK
logs the error and waits for the next `identify`.

## Events and screens

```swift
Brudcast.track("checkout_started", properties: ["total": 120, "plan": "pro"])
Brudcast.screen("Checkout")
```

In-app messages triggered by an event or a screen show at once, offline too.

## In-app messages

Nothing else is needed for messages to show. Optional controls:

```swift
Brudcast.inApp.pauseDisplay()
Brudcast.inApp.resumeDisplay()

Brudcast.inApp.setMessageHandler { message in
    message.format == .fullscreen && isOnboarding ? .defer : .show
}

Brudcast.setActionHandler { action in
    if action.kind == .deeplink, router.handle(action.value) { return .handled }
    return .useDefault
}
```

Inbox:

```swift
Brudcast.inApp.inbox.present()
Brudcast.inApp.inbox.unreadCountPublisher.sink { badge = $0 }
Brudcast.inApp.inbox.list { result in ... }
```

## Push

Push sends through FCM, so the app needs Firebase Messaging for its token. The SDK does not bundle
Firebase; pass it the token:

```swift
func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    if let fcmToken { Brudcast.push.setToken(fcmToken) }
}
```

Ask for permission, from a moment that makes sense to the user or from an in-app message's
`request_push_permission` button:

```swift
Brudcast.push.requestPermission { status in ... }
```

Let the SDK see notification taps. Either install its delegate at launch, after your own:

```swift
Brudcast.push.installNotificationDelegate()
```

or, when your app or another SDK owns `UNUserNotificationCenterDelegate`, forward to it:

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    Brudcast.push.handleNotificationResponse(response)
    completionHandler()
}

func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler(Brudcast.push.presentationOptions(for: notification) ?? [.banner, .sound])
}
```

Images and delivery receipts need a notification service extension. Add one, link
`BrudcastNotificationService`, share an App Group with the app, and make its principal class:

```swift
import BrudcastNotificationService

final class NotificationService: BrudcastNotificationServiceExtension {
    override var appGroupIdentifier: String? { "group.com.example.app" }
}
```

Push needs the in-app application linked to a push application in the dashboard. Until the
environment accepts device tokens, the SDK logs a warning once and keeps the token for later.

## Behaviour

- Calls made before `initialize` are queued. Nothing throws or blocks the main thread.
- Events are stored on disk and sent in batches of up to 100 every 10 seconds, when 20 are waiting,
  and when the app goes to the background. Failed batches back off up to 5 minutes; events older than
  7 days are dropped.
- The device id is a random UUID in the Keychain, never the IDFA or IDFV.
- `Brudcast.disableTracking()` stops all event collection, for consent frameworks.
- Each product ships a privacy manifest.

## Develop

```sh
swift test                                                             # logic tests on macOS
xcodebuild -scheme Brudcast-Package -destination 'generic/platform=iOS Simulator' build
```

`.local(port: 8191)` points the SDK at `brudcast-in-app-delivery-service` running on this machine.
