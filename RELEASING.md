# Releasing

The SDK ships two ways from the same git tag:

- **Swift Package Manager** reads the tag directly, so the tag is the release.
- **CocoaPods** gets four pods, `Brudcast`, `BrudcastNotificationService`, `BrudcastInApp` and
  `BrudcastPush`, one per Swift module, so `import BrudcastInApp` works the same with either.
  Publishing a GitHub release runs `.github/workflows/release.yml`, which pushes them to trunk.

Each podspec reads its version from `BrudcastSDK.version` in
`Sources/Brudcast/Internal/BrudcastSDK.swift`, the same string the SDK reports to Brudcast, so the
pods, the tag and the SDK can never name different versions.

## Release

1. Set `BrudcastSDK.version` to the new version, move the `Unreleased` section of `CHANGELOG.md`
   under that version with today's date, and merge to `main`.
2. Create a GitHub release from `main` with the tag `v<version>`, such as `v0.2.0`, and the
   changelog section as its notes. Swift Package Manager can resolve it at once.
3. The release workflow checks the tag matches `BrudcastSDK.version`, then pushes the four pods,
   dependencies first. They appear on [CocoaPods](https://cocoapods.org) within a few minutes.

A version on trunk cannot be overwritten. A mistake needs a new version, or
`pod trunk deprecate` while the fix ships.

## Check the podspecs locally

```sh
pod lib lint Brudcast.podspec --platforms=ios --skip-tests
pod lib lint BrudcastNotificationService.podspec --platforms=ios --skip-tests
pod lib lint BrudcastInApp.podspec --platforms=ios --skip-tests --include-podspecs='{Brudcast,BrudcastNotificationService}.podspec'
pod lib lint BrudcastPush.podspec --platforms=ios --skip-tests --include-podspecs='{Brudcast,BrudcastNotificationService}.podspec'
```

CI runs the same on every pull request.

## One-time setup

1. Register with trunk, using an address that should own the pods:

   ```sh
   pod trunk register security@brudcast.com 'Brudcast' --description='Release workflow'
   ```

   Click the link in the email trunk sends.

2. Copy the token trunk saved into `~/.netrc`, under `machine trunk.cocoapods.org`, as its
   `password`.

3. Add it to the repository as the secret `COCOAPODS_TRUNK_TOKEN` (Settings → Secrets and
   variables → Actions).

4. The first release claims the four pod names. To let teammates publish too, add them with
   `pod trunk add-owner <pod> <email>` for each pod.
