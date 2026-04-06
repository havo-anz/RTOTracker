#!/bin/bash

# RTO Tracker - Build Release DMG
# This script builds a release version and creates a DMG for distribution

set -e

PROJECT_DIR="/Users/voha/Source/RTO Tracker/RTOTracker"
PROJECT_NAME="RTOTracker"
APP_NAME="RTO Tracker"
DMG_NAME="RTO-Tracker-Installer"
VERSION="1.0"

echo "🔨 Building RTO Tracker for Release..."

# Build release version
cd "$PROJECT_DIR"
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
           -scheme "$PROJECT_NAME" \
           -configuration Release \
           -derivedDataPath ./build \
           clean build

echo "✅ Build completed successfully"

# Find the built app
BUILD_DIR="./build/Build/Products/Release"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App not found at $APP_PATH"
    exit 1
fi

echo "📦 Creating DMG installer..."

# Create a temporary directory for DMG contents
DMG_TEMP="/tmp/${PROJECT_NAME}_dmg"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy the app
cp -R "$APP_PATH" "$DMG_TEMP/"

# Create a symbolic link to Applications folder
ln -s /Applications "$DMG_TEMP/Applications"

# Create README
cat > "$DMG_TEMP/README.txt" << 'EOF'
RTO Tracker - Installation Instructions
========================================

INSTALLATION:
1. Drag "RTO Tracker" to the Applications folder
2. Double-click "RTO Tracker" from Applications to launch
3. The app will appear in your menu bar (look for the building icon)

FIRST TIME SETUP:
1. Click the menu bar icon
2. Go to Settings
3. Click "Test Connection" to see your current IP
4. Update "IP Prefix" if needed (default: 10.78.)

HOW IT WORKS:
- The app checks your IP address every 5 minutes
- When connected to office network, it marks the day as confirmed
- No manual tracking needed - it runs in the background
- View your quarterly progress from the menu bar

SETTINGS:
- IP Prefix: Your office network IP prefix (e.g., 10.78.)
- Quarter Target: Days required per quarter (default: 36)
- Reminders: Get notified when falling behind (default: 9:15 AM)

IMPORTANT NOTES:
- VPN from home does NOT count as office day
- Data is stored locally only (no cloud sync)
- The app needs to run to track your office days
- Enable "Launch at login" in Settings for automatic tracking

SECURITY:
- The app only reads your local IP address
- No data is uploaded or shared
- All tracking data stays on your Mac
- No permissions required

TROUBLESHOOTING:
- If the app doesn't open: Right-click > Open (bypass Gatekeeper)
- If tracking doesn't work: Verify IP prefix in Settings
- If menu bar icon is missing: Quit and relaunch the app

Version: 1.0
For internal use only
EOF

# Output directory
OUTPUT_DIR="/Users/voha/Source/RTO Tracker/releases"
mkdir -p "$OUTPUT_DIR"

# Create DMG
DMG_PATH="${OUTPUT_DIR}/${DMG_NAME}-v${VERSION}.dmg"
rm -f "$DMG_PATH"

hdiutil create -volname "RTO Tracker" \
               -srcfolder "$DMG_TEMP" \
               -ov \
               -format UDZO \
               "$DMG_PATH"

# Cleanup
rm -rf "$DMG_TEMP"

echo ""
echo "✅ DMG created successfully!"
echo "📍 Location: $DMG_PATH"
echo ""
echo "🎉 Ready for distribution!"
echo ""
echo "To share with colleagues:"
echo "1. Upload the DMG to a shared drive or send via email"
echo "2. Users double-click the DMG"
echo "3. Users drag 'RTO Tracker' to Applications"
echo ""
