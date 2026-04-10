#!/bin/bash
set -e

# RTO Tracker - Sparkle Update Testing Script
# This script helps you test auto-updates end-to-end

SPARKLE_PATH="/Users/voha/Downloads/Sparkle-2.x"
PROJECT_PATH="/Users/voha/Source/RTO Tracker/RTOTracker"
BUILD_PATH="$PROJECT_PATH/build"

echo "🚀 RTO Tracker - Sparkle Update Test"
echo "======================================"
echo ""

# Step 1: Check if keys exist
if grep -q "PLACEHOLDER_GENERATE_KEYS_FIRST" "$PROJECT_PATH/RTOTracker/Info.plist"; then
    echo "🔑 Step 1: Generate EdDSA Keys"
    echo "--------------------------------"
    cd "$SPARKLE_PATH"
    ./bin/generate_keys

    echo ""
    echo "⚠️  IMPORTANT: Save these keys securely!"
    echo ""
    echo "📝 Next: Copy the PUBLIC KEY above and paste it here:"
    read -p "Public Key: " PUBLIC_KEY

    echo "📝 Copy the PRIVATE KEY and paste it here (will be saved to .sparkle-private-key):"
    read -s -p "Private Key: " PRIVATE_KEY
    echo ""

    # Save private key
    echo "$PRIVATE_KEY" > "$PROJECT_PATH/.sparkle-private-key"
    chmod 600 "$PROJECT_PATH/.sparkle-private-key"

    # Update Info.plist
    sed -i '' "s/PLACEHOLDER_GENERATE_KEYS_FIRST/$PUBLIC_KEY/" "$PROJECT_PATH/RTOTracker/Info.plist"

    echo "✅ Keys saved and Info.plist updated"
    echo ""
else
    echo "✅ Keys already configured"
    echo ""

    if [ ! -f "$PROJECT_PATH/.sparkle-private-key" ]; then
        echo "⚠️  Private key not found in .sparkle-private-key"
        echo "📝 Please paste your PRIVATE KEY:"
        read -s -p "Private Key: " PRIVATE_KEY
        echo ""
        echo "$PRIVATE_KEY" > "$PROJECT_PATH/.sparkle-private-key"
        chmod 600 "$PROJECT_PATH/.sparkle-private-key"
    fi
fi

# Step 2: Check current version
echo "📋 Step 2: Current Version Info"
echo "--------------------------------"
CURRENT_VERSION=$(defaults read "$PROJECT_PATH/RTOTracker/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")
CURRENT_BUILD=$(defaults read "$PROJECT_PATH/RTOTracker/Info.plist" CFBundleVersion 2>/dev/null || echo "1")
echo "Current Version: $CURRENT_VERSION (build $CURRENT_BUILD)"
echo ""

# Step 3: Ask for new version
echo "📝 Step 3: New Version"
echo "----------------------"
read -p "Enter new version number (e.g., 1.1): " NEW_VERSION
read -p "Enter new build number (e.g., 2): " NEW_BUILD
echo ""

# Step 4: Build new version
echo "🏗️  Step 4: Building Version $NEW_VERSION"
echo "----------------------------------------"
mkdir -p "$BUILD_PATH"

# Update version numbers
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$PROJECT_PATH/RTOTracker/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$PROJECT_PATH/RTOTracker/Info.plist"

# Build archive
echo "Building archive..."
xcodebuild -project "$PROJECT_PATH/RTOTracker.xcodeproj" \
           -scheme RTOTracker \
           -configuration Release \
           -archivePath "$BUILD_PATH/RTOTracker-v$NEW_VERSION.xcarchive" \
           archive \
           2>&1 | grep -E "Build succeeded|error:" || true

if [ ! -d "$BUILD_PATH/RTOTracker-v$NEW_VERSION.xcarchive" ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build succeeded"
echo ""

# Step 5: Create update package
echo "📦 Step 5: Creating Update Package"
echo "-----------------------------------"
cd "$BUILD_PATH"

# Create zip
ditto -c -k --sequesterRsrc --keepParent \
    "RTOTracker-v$NEW_VERSION.xcarchive/Products/Applications/RTOTracker.app" \
    "RTOTracker-$NEW_VERSION.zip"

FILE_SIZE=$(stat -f%z "RTOTracker-$NEW_VERSION.zip")
echo "✅ Created RTOTracker-$NEW_VERSION.zip ($FILE_SIZE bytes)"
echo ""

# Step 6: Sign the update
echo "✍️  Step 6: Signing Update"
echo "--------------------------"
cd "$SPARKLE_PATH"

SIGNATURE=$(./bin/sign_update "$BUILD_PATH/RTOTracker-$NEW_VERSION.zip" \
    --ed-key-file "$PROJECT_PATH/.sparkle-private-key" | grep "sparkle:edSignature" | cut -d'"' -f2)

echo "✅ Signature: $SIGNATURE"
echo ""

# Step 7: Create test appcast
echo "📄 Step 7: Creating Test Appcast"
echo "---------------------------------"
cat > "$BUILD_PATH/test-appcast.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>RTO Tracker Test Updates</title>
        <description>Local test updates</description>

        <item>
            <title>Version $NEW_VERSION</title>
            <pubDate>$(date -u +"%a, %d %b %Y %H:%M:%S +0000")</pubDate>
            <sparkle:version>$NEW_BUILD</sparkle:version>
            <sparkle:shortVersionString>$NEW_VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <enclosure
                url="file://$BUILD_PATH/RTOTracker-$NEW_VERSION.zip"
                sparkle:edSignature="$SIGNATURE"
                length="$FILE_SIZE"
                type="application/octet-stream" />
            <description><![CDATA[
                <h2>Test Update - Version $NEW_VERSION</h2>
                <ul>
                    <li>This is a test update</li>
                    <li>Built on $(date)</li>
                </ul>
            ]]></description>
        </item>
    </channel>
</rss>
EOF

echo "✅ Created test-appcast.xml"
echo ""

# Step 8: Setup for testing
echo "🧪 Step 8: Setup for Testing"
echo "-----------------------------"
echo "To test the update:"
echo ""
echo "1. Temporarily update Info.plist SUFeedURL:"
echo "   <string>file://$BUILD_PATH/test-appcast.xml</string>"
echo ""
echo "2. Build and run the CURRENT version ($CURRENT_VERSION)"
echo ""
echo "3. Click 'Check for Updates...' in the menu"
echo ""
echo "4. You should see update to version $NEW_VERSION!"
echo ""

read -p "Would you like to update SUFeedURL now? (y/n): " UPDATE_FEED

if [ "$UPDATE_FEED" = "y" ]; then
    # Backup original Info.plist
    cp "$PROJECT_PATH/RTOTracker/Info.plist" "$PROJECT_PATH/RTOTracker/Info.plist.backup"

    # Update SUFeedURL
    /usr/libexec/PlistBuddy -c "Set :SUFeedURL file://$BUILD_PATH/test-appcast.xml" "$PROJECT_PATH/RTOTracker/Info.plist"

    echo "✅ SUFeedURL updated (backup saved to Info.plist.backup)"
    echo ""
    echo "⚠️  Remember to restore it after testing with:"
    echo "   mv \"$PROJECT_PATH/RTOTracker/Info.plist.backup\" \"$PROJECT_PATH/RTOTracker/Info.plist\""
fi

echo ""
echo "🎉 Test setup complete!"
echo ""
echo "📁 Files created:"
echo "   - $BUILD_PATH/RTOTracker-$NEW_VERSION.zip"
echo "   - $BUILD_PATH/test-appcast.xml"
echo "   - $PROJECT_PATH/.sparkle-private-key (keep secret!)"
echo ""
echo "Next: Build and run version $CURRENT_VERSION, then check for updates!"
