#!/bin/bash

# Sync changelogs between iOS and Android
# This script copies the iOS release notes to the Android changelog for the current version

set -e

# Get the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}📝 Syncing changelogs between iOS and Android${NC}"

# Extract version code from pubspec.yaml
PUBSPEC_PATH="$PROJECT_ROOT/pubspec.yaml"
if [ ! -f "$PUBSPEC_PATH" ]; then
    echo -e "${RED}Error: pubspec.yaml not found at $PUBSPEC_PATH${NC}"
    exit 1
fi

VERSION_CODE=$(grep -E "version:\s*(.+)\+(\d+)" "$PUBSPEC_PATH" | sed -E 's/.*\+([0-9]+).*/\1/')

if [ -z "$VERSION_CODE" ]; then
    echo -e "${RED}Error: Could not extract version code from pubspec.yaml${NC}"
    exit 1
fi

echo -e "${YELLOW}Current version code: $VERSION_CODE${NC}"

# Define paths
IOS_RELEASE_NOTES="$PROJECT_ROOT/ios/fastlane/metadata/en-US/release_notes.txt"
ANDROID_CHANGELOG="$PROJECT_ROOT/android/fastlane/metadata/android/en-GB/changelogs/$VERSION_CODE.txt"

# Check if iOS release notes exist
if [ ! -f "$IOS_RELEASE_NOTES" ]; then
    echo -e "${RED}Error: iOS release notes not found at $IOS_RELEASE_NOTES${NC}"
    exit 1
fi

# Create Android changelogs directory if it doesn't exist
ANDROID_CHANGELOGS_DIR="$(dirname "$ANDROID_CHANGELOG")"
mkdir -p "$ANDROID_CHANGELOGS_DIR"

# Copy iOS release notes to Android changelog
cp "$IOS_RELEASE_NOTES" "$ANDROID_CHANGELOG"

echo -e "${GREEN}✅ Successfully synced changelog!${NC}"
echo -e "   iOS release notes → Android changelog ($VERSION_CODE.txt)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the changelog at: $ANDROID_CHANGELOG"
echo "2. Commit the changes"
echo "3. Run fastlane to deploy"
