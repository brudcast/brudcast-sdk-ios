# Releasing

The SDK ships through **Swift Package Manager**, which has no registry to publish to: apps fetch
the package straight from the git tag, so the tag is the release. Publishing a GitHub release runs
`.github/workflows/release.yml`, which checks the release builds the way a customer gets it.

`BrudcastSDK.version` in `Sources/Brudcast/Internal/BrudcastSDK.swift` is the version the SDK
reports to Brudcast, and the release tag has to match it.

## CocoaPods

0.1.0 is on CocoaPods as four pods, `Brudcast`, `BrudcastNotificationService`, `BrudcastInApp` and
`BrudcastPush`, owned by `security@brudcast.com`. It is the last version there: CocoaPods trunk is
becoming read-only, so later versions are Swift Package Manager only and the repository no longer
has podspecs. 0.1.0 stays installable. To mark it deprecated in favour of Swift Package Manager, an
owner can run `pod trunk deprecate <pod>` for each pod while trunk still accepts changes.

## The stages

```
Verify ─▶ Test ─▶ Build with Swift Package Manager
```

| Stage | What it does |
| --- | --- |
| Verify | Reads `BrudcastSDK.version`, checks a release's tag is `v<version>` and that `CHANGELOG.md` and the README name the same version, and refuses a release while the repository is private |
| Test | The logic tests and the iOS build |
| Build with Swift Package Manager | `scripts/check-spm-consumer.sh`: builds a scratch app package that depends on the SDK from GitHub, with all four products, for iOS. On a release it depends on `exact: "<version>"`, so it proves Swift Package Manager can resolve and build the tag customers will get; on a run started by hand it depends on the commit being run |

The workflow publishes nothing and needs no secrets. A failed stage can be re-run on its own from
the run page.

## Release

1. On a `docs/release-<version>` branch, set `BrudcastSDK.version` to the new version, move the
   `Unreleased` section of `CHANGELOG.md` under that version with today's date, and set the
   version in the README's `Package.swift` line to it. Commit as `docs: release <version>` and
   merge to `main`. CI runs `scripts/check-version.sh`, which fails until all three name the same
   version.
2. Create a GitHub release from `main` with the tag `v<version>`, such as `v0.2.0`, and the
   changelog section as its notes. Swift Package Manager can resolve it at once.
3. Check the **Release** run passes. If **Build with Swift Package Manager** fails, the tag is out
   but broken: fix it in a new version rather than moving the tag, since apps that already resolved
   it have pinned its commit.

## Conventions

- Commits follow [Conventional Commits](https://www.conventionalcommits.org). A change that breaks
  the public API gets a `!` after its type, such as `fix!:`, before 1.0 too.
- `CHANGELOG.md` lists what an app using the SDK gets. How the SDK is built, tested and released
  belongs in the pull request and in this file, not in the changelog.

## Check a commit before releasing

Run the **Release** workflow by hand from the Actions tab. It verifies, tests and builds the commit
it runs on with Swift Package Manager. Nothing is published.

Or check locally:

```sh
scripts/check-spm-consumer.sh --version 0.1.0
scripts/check-spm-consumer.sh --revision "$(git rev-parse HEAD)"
```

A commit has to be pushed to GitHub before `--revision` can find it.
