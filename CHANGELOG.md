# Changelog

All notable changes to the Brudcast iOS SDK are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the SDK uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Before 1.0, a minor release may change
the public API.

## [Unreleased]

## [0.2.0] - 2026-10-18

### Added

- Handlers that answer later, for bridges such as the Flutter plugin whose handlers reply
  asynchronously: `Brudcast.setAsyncActionHandler`, `BrudcastInApp.setAsyncMessageHandler` and
  `BrudcastPush.setAsyncNotificationHandler`. Each waits two seconds, then uses the default. The
  synchronous setters now wrap them.
- `BrudcastPush.presentationOptions(for:completionHandler:)`, which waits for an asynchronous
  notification handler. The notification delegate installed by `installNotificationDelegate` uses
  it.
- `Brudcast.performDefaultAction`, which runs an action's default behaviour without the handler.
- `BrudcastInbox.render(_:onContentHeightChange:)`, which reports the height an entry's design
  needs, so a custom inbox can size the view to fit.
- `BrudcastDecision`, the one-answer-with-timeout helper the asynchronous handlers use, for modules.
- `BrudcastSDK.setWrapper(name:version:)`, which adds a wrapping SDK such as the Flutter plugin to
  the `User-Agent`.

## [0.1.1] - 2026-10-18

### Added

- `BrudcastAction.verified`, matching the Android SDK. Every action the iOS SDK creates comes from
  the app's own UI or from the system notification center, so it is always true.

### Removed

- CocoaPods. 0.1.0 is published there as one pod per module (`Brudcast`, `BrudcastInApp`,
  `BrudcastPush`, `BrudcastNotificationService`) and is the last version there, because CocoaPods
  trunk is becoming read-only. Later versions are Swift Package Manager only.

## [0.1.0] - 2026-10-18

### Added

- `Brudcast` core: configuration, a Keychain device id, sessions, `identify` and `reset` with
  server-computed user hashes, `track` and `screen`, a persistent batched event queue, opt-out,
  `disableTracking` for consent frameworks, and the action handler.
- `BrudcastInApp`: message sync, the live stream, event, screen and session triggers with property
  filters, display rules and the frequency cap, native modal, banner and full screen rendering,
  the host message handler, and the inbox with its default screen.
- `BrudcastPush`: permission, FCM token registration for the signed-in user, foreground
  presentation, open tracking and a notification-center delegate proxy.
- `BrudcastNotificationService`: a notification service extension that attaches images and records
  deliveries for the app to send.
- A privacy manifest in every product.
- Apache License 2.0, a security policy and this changelog.
- A sample app with a notification service extension in `Examples/BrudcastSample` that uses the
  SDK the way a customer's app would, from sign-in through a shop to sign-out, built in CI.

### Security

- Events are sent with the session of the user who produced them. Events of a user who signed out
  go with that user's last session while it lasts and are dropped after that, instead of being
  credited to whoever signs in next.
- The core's privacy manifest declares the email address, phone number and name apps may pass in
  `BrudcastTraits`.

### Fixed

- A NaN or infinite event property no longer crashes the app. It is dropped with a warning, and a
  request body that cannot be encoded fails without retrying.
- The device id survives a launch that cannot read the Keychain, such as a background launch before
  the first unlock. The Keychain item is no longer deleted and re-added.
- A delivery recorded by both the notification service extension and the foreground handler is
  counted once.
- One invalid event no longer drops the whole batch. A rejected batch is halved until the event the
  service refuses is sent alone and dropped.
- A refused publishable key is told apart from a refused user hash by the service's error code when
  it sends one, and a refused key is tried again on the next foreground instead of never.
- A view from `BrudcastInbox.render(_:)` keeps updating after the call returns.
- Messages with a trigger this SDK cannot read are reported as `render_unsupported` instead of
  being dropped silently.
- The notification service extension skips images over Apple's 10 MB attachment limit.
- The event queue is written to disk at most once a second, and when the app goes to the
  background, instead of on every event.

[Unreleased]: https://github.com/brudcast/brudcast-sdk-ios/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/brudcast/brudcast-sdk-ios/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/brudcast/brudcast-sdk-ios/releases/tag/v0.1.0
