#!/bin/bash
# Generate Xcode project for VibeStream tvOS
# Run on macOS: cd tvos && bash generate-xcode-project.sh
#
# This script uses xcodegen to create a proper Xcode project.
# Install xcodegen: brew install xcodegen
# Then run this script from the tvos/ directory.

set -e

# Check if xcodegen is available
if ! command -v xcodegen &> /dev/null; then
    echo "xcodegen not found. Install with: brew install xcodegen"
    echo "Alternatively, open the project in Xcode and add all Swift files manually."
    exit 1
fi

xcodegen generate

echo "Xcode project generated successfully!"
echo "Open VibeStream.xcodeproj in Xcode to build and run."
