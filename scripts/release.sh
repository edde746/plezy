#!/bin/bash

# Plezy Release Automation Script
# This script automates the release process for both iOS and Android

set -e

# Get the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Load environment variables from .env
if [ -f "$PROJECT_ROOT/.env" ]; then
    # Export variables without executing the file
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
    echo -e "${GREEN}✅ Loaded environment variables from .env${NC}"
else
    echo -e "${RED}❌ Error: .env file not found${NC}"
    exit 1
fi

# Function to show help
show_help() {
    echo -e "${BLUE}Plezy Release Automation${NC}"
    echo ""
    echo "Usage: ./scripts/release.sh <command>"
    echo ""
    echo "Available commands:"
    echo "  sync      - Sync iOS release notes to Android changelog"
    echo "  android   - Build and release to Google Play Store"
    echo "  ios       - Build and release to App Store"
    echo "  all       - Sync changelogs and release to both platforms"
    echo "  clean     - Clean build artifacts"
    echo "  help      - Show this help message"
    echo ""
    echo "Prerequisites:"
    echo "  - .env file must be configured with credentials"
    echo "  - iOS release notes updated in ios/fastlane/metadata/en-US/release_notes.txt"
    echo "  - Version bumped in pubspec.yaml"
    echo ""
    echo "Example:"
    echo "  ./scripts/release.sh all"
}

# Function to sync changelogs
sync_changelogs() {
    echo -e "${YELLOW}📝 Syncing changelogs...${NC}"
    "$SCRIPT_DIR/sync_changelogs.sh"
}

# Function to release Android
release_android() {
    echo -e "${GREEN}🤖 Building and releasing Android app...${NC}"
    cd "$PROJECT_ROOT/android"
    fastlane release
    cd "$PROJECT_ROOT"
}

# Function to release iOS
release_ios() {
    echo -e "${GREEN}🍎 Building and releasing iOS app...${NC}"
    cd "$PROJECT_ROOT/ios"
    fastlane deploy_appstore
    cd "$PROJECT_ROOT"
}

# Function to release all
release_all() {
    sync_changelogs
    echo ""
    release_android
    echo ""
    release_ios
    echo ""
    echo -e "${GREEN}✅ Release complete for both platforms!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Check Google Play Console for the draft release"
    echo "  2. Check App Store Connect for the uploaded build"
    echo "  3. Submit for review when ready"
}

# Function to clean build artifacts
clean() {
    echo -e "${YELLOW}🧹 Cleaning build artifacts...${NC}"
    cd "$PROJECT_ROOT/android"
    ./gradlew clean 2>/dev/null || true
    cd "$PROJECT_ROOT/ios"
    xcodebuild clean -workspace Runner.xcworkspace -scheme Runner 2>/dev/null || true
    cd "$PROJECT_ROOT"
    flutter clean
    echo -e "${GREEN}✅ Clean complete!${NC}"
}

# Main script logic
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

case "$1" in
    sync)
        sync_changelogs
        ;;
    android)
        release_android
        ;;
    ios)
        release_ios
        ;;
    all)
        release_all
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
