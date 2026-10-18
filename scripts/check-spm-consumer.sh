#!/usr/bin/env bash
# Builds a scratch app package that depends on the SDK from GitHub the way a customer's app does,
# with all four products, for iOS. It proves Swift Package Manager can resolve and build the given
# version or commit from the published repository, not just from this checkout.
#
# Usage: scripts/check-spm-consumer.sh --version 0.2.0
#        scripts/check-spm-consumer.sh --revision <commit sha>
set -euo pipefail

case "${1:-}" in
  --version) requirement="exact: \"$2\"" ;;
  --revision) requirement="revision: \"$2\"" ;;
  *) echo "Usage: $0 --version <version> | --revision <commit sha>" >&2; exit 2 ;;
esac

url="${BRUDCAST_SDK_URL:-https://github.com/brudcast/brudcast-sdk-ios}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/Sources/BrudcastConsumer"

cat > "$work/Package.swift" <<SWIFT
// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "BrudcastConsumer",
    platforms: [.iOS(.v14)],
    products: [.library(name: "BrudcastConsumer", targets: ["BrudcastConsumer"])],
    dependencies: [.package(url: "$url", $requirement)],
    targets: [
        .target(
            name: "BrudcastConsumer",
            dependencies: [
                .product(name: "Brudcast", package: "brudcast-sdk-ios"),
                .product(name: "BrudcastInApp", package: "brudcast-sdk-ios"),
                .product(name: "BrudcastPush", package: "brudcast-sdk-ios"),
                .product(name: "BrudcastNotificationService", package: "brudcast-sdk-ios"),
            ]
        ),
    ]
)
SWIFT

cat > "$work/Sources/BrudcastConsumer/Consumer.swift" <<'SWIFT'
import Brudcast
import BrudcastInApp
import BrudcastNotificationService
import BrudcastPush
SWIFT

echo "Resolving $url ($requirement)"
(cd "$work" && swift package resolve)
echo "Building all four products for iOS"
(cd "$work" && xcodebuild -scheme BrudcastConsumer -destination 'generic/platform=iOS Simulator' -derivedDataPath "$work/DerivedData" -quiet build)
echo "Swift Package Manager resolves and builds $url ($requirement) for iOS"
