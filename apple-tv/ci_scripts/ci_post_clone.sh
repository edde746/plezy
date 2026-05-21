#!/bin/bash
set -e

echo "=== Clearing Swift Package Manager cache ==="
# Fix "already exists in file system" errors when resolving SPM packages
swift package purge-cache 2>/dev/null || true
rm -rf ~/Library/Caches/org.swift.swiftpm/artifacts 2>/dev/null || true

echo "=== Resolving packages ==="
cd "$(dirname "$0")/.."
xcodebuild -resolvePackageDependencies -workspace VibeStream.xcodeproj/project.xcworkspace -scheme VibeStream

echo "=== tvOS CI post-clone complete ==="
