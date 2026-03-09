#!/bin/bash
set -euo pipefail

# Deploy Plezy to iPhone and Apple Watch
# Usage: ./scripts/deploy.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

info() { echo -e "${GREEN}▸${NC} $1"; }
warn() { echo -e "${YELLOW}▸${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }

# Step 1: Kill any existing flutter/xcode processes
info "Killing stale processes..."
pkill -f "flutter run" 2>/dev/null || true
pkill -f "dart.*flutter_tools" 2>/dev/null || true

# Step 2: Update build stamp so we can verify the watch app updated
BUILD_STAMP="$(date +%b%d-%H%M)"
STAMP_FILE="$PROJECT_DIR/ios/PlezyWatch Watch App/BuildInfo.swift"
cat > "$STAMP_FILE" << SWIFT
import Foundation

enum BuildInfo {
    static var stamp: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "v\(v) $BUILD_STAMP"
    }
}
SWIFT
info "Build stamp: $BUILD_STAMP"

# Step 3: Bump CFBundleVersion to force Watch app re-install
PLIST="$PROJECT_DIR/ios/PlezyWatch Watch App/Info.plist"
CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST" 2>/dev/null || echo "1")
# Handle $(CURRENT_PROJECT_VERSION) placeholder
if [[ "$CURRENT_BUILD" == *"CURRENT_PROJECT_VERSION"* ]]; then
    CURRENT_BUILD="1"
fi
NEW_BUILD=$((CURRENT_BUILD + 1))
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$PLIST" 2>/dev/null || true
info "Watch app build number: $NEW_BUILD"

# Step 4: Find the iPhone
info "Looking for iPhone..."
DEVICE_INFO=$(xcrun devicectl list devices 2>/dev/null | grep -i iphone | head -1)
if [ -z "$DEVICE_INFO" ]; then
    fail "No iPhone found. Make sure it's plugged in via USB or on the same network."
fi
DEVICE_ID=$(echo "$DEVICE_INFO" | awk '{for(i=1;i<=NF;i++) if($i ~ /^[A-F0-9]{8}-/) print $i}')
DEVICE_NAME=$(echo "$DEVICE_INFO" | awk '{print $1}')
info "Found: $DEVICE_NAME ($DEVICE_ID)"

# Step 5: Clean derived data for watch target to force full rebuild
info "Cleaning Watch app build cache..."
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
WATCH_BUILD=$(find "$DERIVED_DATA" -path "*/Runner-*/Build/Intermediates.noindex/Runner.build/*/PlezyWatch*" -type d -maxdepth 6 2>/dev/null | head -1)
if [ -n "$WATCH_BUILD" ]; then
    rm -rf "$(dirname "$WATCH_BUILD")"/../../../Products/*/PlezyWatch\ Watch\ App.app 2>/dev/null || true
    info "Cleaned cached Watch app"
fi

# Step 6: Run Flutter analyze and tests
info "Running flutter analyze..."
ANALYZE_OUTPUT=$(flutter analyze --no-pub 2>&1 || true)
if echo "$ANALYZE_OUTPUT" | grep -q "error •" 2>/dev/null; then
    echo "$ANALYZE_OUTPUT" | grep "error •" || true
    fail "Flutter analyze found errors"
else
    ISSUE_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -oE '[0-9]+ issues? found' | head -1 || true)
    info "Flutter analyze passed (${ISSUE_COUNT:-no issues})"
fi

info "Running flutter test..."
if [ -d "$PROJECT_DIR/test" ]; then
    if ! flutter test 2>&1 | tail -5; then
        fail "Flutter tests failed"
    fi
    info "Tests passed ✓"
else
    info "No test directory — skipping tests"
fi

# Step 7: Build via flutter (builds both iOS and Watch)
info "Building Flutter iOS app (release)..."
flutter build ios --release 2>&1 | while IFS= read -r line; do
    case "$line" in
        *"Xcode build done"*) info "$line" ;;
        *"Built build"*) info "$line" ;;
        *"error:"*|*"Error"*) echo -e "${RED}  $line${NC}" ;;
    esac
done

APP_PATH="$PROJECT_DIR/build/ios/iphoneos/Runner.app"
if [ ! -d "$APP_PATH" ]; then
    fail "Build failed — Runner.app not found at $APP_PATH"
fi

# Step 8: Verify Watch app is embedded and contains our build stamp
WATCH_APP="$APP_PATH/Watch/PlezyWatch Watch App.app"
if [ ! -d "$WATCH_APP" ]; then
    warn "Watch app not found embedded in Runner.app!"
    warn "Attempting xcodebuild directly..."
    xcodebuild -project ios/Runner.xcodeproj -scheme Runner \
        -destination "generic/platform=iOS" \
        -configuration Release \
        -quiet build 2>&1 | tail -5
else
    info "Watch app embedded ✓"
    # Verify the binary contains our stamp
    if strings "$WATCH_APP/PlezyWatch Watch App" 2>/dev/null | grep -q "$BUILD_STAMP"; then
        info "Build stamp verified in Watch binary ✓"
    else
        warn "Build stamp not found in Watch binary — may be using cached build"
    fi
fi

# Step 9: Install to iPhone (Watch app syncs automatically)
info "Installing to $DEVICE_NAME..."
if xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH" 2>&1; then
    info "Installed on iPhone ✓"
else
    fail "Install failed. Is the device connected?"
fi

# Step 10: Launch the app
info "Launching Plezy..."
xcrun devicectl device process launch --device "$DEVICE_ID" com.edde746.plezy 2>/dev/null || true

echo ""
info "iPhone app installed and launched."
info "Watch app will sync from iPhone. Look for 'Build: $BUILD_STAMP' on the Watch home screen."
info "If the Watch still shows old build, force-close Plezy on Watch (side button → hold on app → X)."
echo ""
echo -e "${GREEN}✓ Deploy complete — verify Watch shows: Build: $BUILD_STAMP${NC}"
