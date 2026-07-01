#!/bin/sh

# Xcode Cloud post-clone script.
#
# Xcode Cloud checks out a fresh copy of the repo and then runs `xcodebuild`
# directly. But a Flutter app's iOS project depends on files that Flutter
# generates and that are gitignored (see ios/.gitignore):
#
#   - Flutter/Generated.xcconfig
#   - Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage  (SPM)
#   - Pods/
#
# Without this bootstrap, package resolution fails with:
#   "the package at '.../ephemeral/Packages/FlutterGeneratedPluginSwiftPackage'
#    cannot be accessed (... doesn't exist in file system)"
#
# `flutter pub get` regenerates Generated.xcconfig and the SPM package;
# `pod install` restores the CocoaPods workspace.

# Fail the build if any command fails.
set -e

# Xcode Cloud starts this script in the ci_scripts directory.
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Pin Flutter to the version this app is built against (see pubspec.yaml).
FLUTTER_VERSION="3.44.0"

echo "== Installing Flutter $FLUTTER_VERSION =="
git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter --version
flutter precache --ios

echo "== flutter pub get (regenerates Generated.xcconfig + ephemeral SPM package) =="
flutter pub get

echo "== Installing CocoaPods =="
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods

echo "== pod install =="
cd ios
pod install

echo "== Post-clone bootstrap complete =="
exit 0
