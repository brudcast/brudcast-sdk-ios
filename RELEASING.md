# Releasing

The SDK ships two ways from the same git tag:

- **Swift Package Manager** reads the tag directly, so the tag is the release.
- **CocoaPods** gets four pods, `Brudcast`, `BrudcastNotificationService`, `BrudcastInApp` and
  `BrudcastPush`, one per Swift module, so `import BrudcastInApp` works the same with either.
  Publishing a GitHub release runs `.github/workflows/release.yml`, which pushes them to trunk in
  stages.

Each podspec reads its version from `BrudcastSDK.version` in
`Sources/Brudcast/Internal/BrudcastSDK.swift`, the same string the SDK reports to Brudcast, so the
pods, the tag and the SDK can never name different versions.

## The stages

```
                  ┌─▶ Build with Swift Package Manager ─┐
Verify ─▶ Test ───┤                                      ├─▶ Push to CocoaPods
                  └─▶ Validate the podspecs ────────────┘    (waits for approval)
```

| Stage | What it does | Secrets |
| --- | --- | --- |
| Verify | Reads `BrudcastSDK.version`, checks a release's tag is `v<version>` and that `CHANGELOG.md` and the README name the same version, and refuses a release while the repository is private | none |
| Test | The logic tests and the iOS build | none |
| Build with Swift Package Manager | `scripts/check-spm-consumer.sh`: builds a scratch app package that depends on the SDK from GitHub, with all four products, for iOS. On a release it depends on `exact: "<version>"`, so it proves Swift Package Manager can resolve and build the tag customers will get; on a dry run it depends on the commit being run | none |
| Validate the podspecs | `pod lib lint` on all four pods; on a release, also `pod spec lint` on `Brudcast` and `BrudcastNotificationService` against the tag, as trunk will. The pods that depend on them are validated by trunk when they are pushed, once their dependencies are there | none |
| Push to CocoaPods | After approval in the `cocoapods` environment, checks the trunk token is set and pushes the four pods, dependencies first | the trunk token |

Trunk has no staging area, so there is nothing to drop when a run stops before **Push to
CocoaPods**. A failed stage can be re-run on its own from the run page.

## Release

1. On a `docs/release-<version>` branch, set `BrudcastSDK.version` to the new version, move the
   `Unreleased` section of `CHANGELOG.md` under that version with today's date, and set the
   version in the README's `Package.swift` line to it. Commit as `docs: release <version>` and
   merge to `main`. CI runs `scripts/check-version.sh`, which fails until all three name the same
   version.
2. Create a GitHub release from `main` with the tag `v<version>`, such as `v0.2.0`, and the
   changelog section as its notes. Swift Package Manager can resolve it at once.
3. The run stops at **Push to CocoaPods** and waits for a reviewer. Open the run, check the
   **Validate the podspecs** summary, and choose **Review deployments**:
   - **Approve** to push. The pods appear on [CocoaPods](https://cocoapods.org) within a few
     minutes.
   - **Reject** to stop. Nothing reaches trunk, though the tag is already out for Swift Package
     Manager.

A version on trunk cannot be overwritten. A mistake needs a new version, or
`pod trunk deprecate` while the fix ships.

## Conventions

- Commits follow [Conventional Commits](https://www.conventionalcommits.org). A change that breaks
  the public API gets a `!` after its type, such as `fix!:`, before 1.0 too.
- `CHANGELOG.md` lists what an app using the SDK gets. How the SDK is built, tested and released
  belongs in the pull request and in this file, not in the changelog.

## Dry run

Run the **Release** workflow by hand from the Actions tab with **dry run** ticked, which is the
default. It verifies, tests, builds the current commit with Swift Package Manager and lints the four
pods, then stops before **Push to CocoaPods**.
Nothing is pushed.

## Check Swift Package Manager locally

```sh
scripts/check-spm-consumer.sh --version 0.1.0
scripts/check-spm-consumer.sh --revision "$(git rev-parse HEAD)"
```

Swift Package Manager has no registry to publish to: apps fetch the package from the tag, so the tag
is the release. This check builds what they would get. A commit has to be pushed to GitHub before
`--revision` can find it.

## Check the podspecs locally

```sh
pod lib lint Brudcast.podspec --platforms=ios --skip-tests
pod lib lint BrudcastNotificationService.podspec --platforms=ios --skip-tests
pod lib lint BrudcastInApp.podspec --platforms=ios --skip-tests --include-podspecs='{Brudcast,BrudcastNotificationService}.podspec'
pod lib lint BrudcastPush.podspec --platforms=ios --skip-tests --include-podspecs='{Brudcast,BrudcastNotificationService}.podspec'
```

CI runs the same on every pull request.

## One-time setup

### 1. The trunk token

1. Register with trunk, using an address that should own the pods:

   ```sh
   pod trunk register security@brudcast.com 'Brudcast' --description='Release workflow'
   ```

   Click the link in the email trunk sends.

2. Copy the token trunk saved into `~/.netrc`, under `machine trunk.cocoapods.org`, as its
   `password`.

3. The first release claims the four pod names. To let teammates publish too, add them with
   `pod trunk add-owner <pod> <email>` for each pod.

### 2. The GitHub secret

In the repository's **Settings → Secrets and variables → Actions**, add the repository secret
`COCOAPODS_TRUNK_TOKEN` with the token. **Push to CocoaPods** checks it is set before it pushes
anything.

### 3. The approval gate

In **Settings → Environments**, create an environment called `cocoapods` and add everyone who may
approve a release as **required reviewers**. Under **Deployment branches and tags**, allow only tags
matching `v*`, so **Push to CocoaPods** can run only from a release tag and never from a branch,
even in a run started by hand with dry run unticked. On GitHub's free plan, required reviewers only
work in public repositories, which is one reason **Verify** refuses a release while the repository
is private. Dry runs work either way.

### 4. Publishing 0.1.0

`v0.1.0` was tagged before the podspecs existed, so a release run from it has no podspecs or
release workflow to run, and the `cocoapods` gate keeps runs from `main` from pushing. The podspecs
on `main` still read 0.1.0 and fetch their sources from that tag, so 0.1.0 can be pushed once by
hand from `main`, before `BrudcastSDK.version` moves on:

```sh
pod spec lint Brudcast.podspec BrudcastNotificationService.podspec --platforms=ios --skip-tests
pod trunk push Brudcast.podspec --synchronous
pod trunk push BrudcastNotificationService.podspec --synchronous
pod trunk push BrudcastInApp.podspec --synchronous
pod trunk push BrudcastPush.podspec --synchronous
```

Every later version goes through the release workflow.
