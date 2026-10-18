#!/usr/bin/env bash
# Checks that BrudcastSDK.version, the newest released section of CHANGELOG.md and the package
# version in the README's install section all name the same version, so a release cannot be tagged
# with a stale changelog or install line.
#
# Usage: scripts/check-version.sh
set -euo pipefail

version="$(sed -n 's/.*version = "\(.*\)".*/\1/p' Sources/Brudcast/Internal/BrudcastSDK.swift)"
changelog="$(sed -n 's/^## \[\([0-9][^]]*\)\] - .*/\1/p' CHANGELOG.md | head -n 1)"
readme="$(sed -n 's/.*brudcast-sdk-ios", from: "\([^"]*\)".*/\1/p' README.md | head -n 1)"
mismatch=0

check() {
  if [ "$2" != "$version" ]; then
    echo "::error::$1 names ${2:-no version}, but BrudcastSDK.version is $version"
    mismatch=1
  fi
}

check "The newest released section of CHANGELOG.md" "$changelog"
check "The README's install section" "$readme"

if [ "$mismatch" -ne 0 ]; then
  echo "Bump them together in the release pull request. See RELEASING.md."
  exit 1
fi
echo "BrudcastSDK.version, CHANGELOG.md and README.md all name $version"
