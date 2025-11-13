#!/bin/bash
# Setup script for Plezy tvOS Xcode project

echo "🚀 Setting up Plezy tvOS Xcode Project"
echo ""

# Check if we're in the right directory
if [ ! -d "tvos" ]; then
    echo "❌ Error: tvos directory not found"
    echo "Please run this script from the plezy repository root"
    exit 1
fi

cd tvos

echo "📋 Step-by-step instructions:"
echo ""
echo "1. Open Xcode"
echo "2. File → New → Project"
echo "3. Select: tvOS → App"
echo "4. Configure:"
echo "   - Product Name: Plezy"
echo "   - Organization Identifier: com.plezy (or your domain)"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "   - Storage: None"
echo "   - Include Tests: Yes (optional)"
echo ""
echo "5. Save in: $(pwd)"
echo "   (Save it as 'Plezy.xcodeproj' in the tvos/ directory)"
echo ""
echo "6. Once project is created:"
echo "   - Delete ContentView.swift"
echo "   - Delete PlezyApp.swift"
echo "   - Delete Assets.xcassets (we'll add it back)"
echo ""
echo "7. Add source files:"
echo "   - Drag 'Plezy' folder from Finder into Xcode project"
echo "   - Check: ✅ Copy items if needed"
echo "   - Check: ✅ Create groups"
echo "   - Add to targets: Plezy"
echo ""
echo "8. Configure Info.plist:"
echo "   - Select project in navigator"
echo "   - Select target → Build Settings"
echo "   - Search: 'Info.plist File'"
echo "   - Set to: Plezy/Resources/Info.plist"
echo ""
echo "9. Build Settings:"
echo "   - iOS Deployment Target: iOS 16.0"
echo "   - Swift Language Version: Swift 5"
echo ""
echo "10. Select 'Apple TV' simulator and press Cmd+R"
echo ""
echo "✅ Setup complete!"
