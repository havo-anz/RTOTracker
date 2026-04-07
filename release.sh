#!/bin/bash

# RTO Tracker - Release Script
# Usage: ./release.sh <version>
# Example: ./release.sh 1.1

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "❌ Error: Version number required"
    echo "Usage: ./release.sh <version>"
    echo "Example: ./release.sh 1.1"
    exit 1
fi

PROJECT_DIR="/Users/voha/Source/RTO Tracker/RTOTracker"
RELEASES_DIR="/Users/voha/Source/RTO Tracker/releases"
DMG_NAME="RTO-Tracker-Installer-v${VERSION}.dmg"
DMG_PATH="${RELEASES_DIR}/${DMG_NAME}"

echo "🚀 Releasing RTO Tracker v${VERSION}"
echo ""

# Step 1: Build release DMG
echo "📦 Step 1: Building release DMG..."
cd "/Users/voha/Source/RTO Tracker"
./build-release.sh

# Check if DMG exists
if [ ! -f "$DMG_PATH" ]; then
    echo "❌ Error: DMG not found at $DMG_PATH"
    echo "Please run build-release.sh first or check the version number"
    exit 1
fi

echo "✅ DMG built: $DMG_PATH"
echo ""

# Step 2: Sign the DMG with EdDSA (requires Sparkle tools)
echo "🔐 Step 2: Signing DMG with EdDSA..."
echo ""
echo "⚠️  NOTE: You need to sign the DMG manually with:"
echo "   sign_update \"$DMG_PATH\""
echo ""
echo "This will generate the EdDSA signature needed for Sparkle."
echo "The signature will be displayed - copy it to appcast.xml"
echo ""

# Get file size
FILE_SIZE=$(stat -f%z "$DMG_PATH")
echo "📊 File size: $FILE_SIZE bytes"
echo ""

# Step 3: Generate appcast entry template
echo "📝 Step 3: Appcast.xml entry template:"
echo ""
echo "Add this to appcast.xml:"
echo ""
cat << EOF
        <item>
            <title>Version ${VERSION}</title>
            <description><![CDATA[
                <h2>What's New in ${VERSION}</h2>
                <ul>
                    <li>Feature 1</li>
                    <li>Feature 2</li>
                    <li>Bug fixes and improvements</li>
                </ul>
            ]]></description>
            <pubDate>$(date -u +"%a, %d %b %Y %H:%M:%S %z")</pubDate>
            <sparkle:version>${VERSION}.0</sparkle:version>
            <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
            <enclosure
                url="https://github.com/havo-anz/RTOTracker/releases/download/v${VERSION}/${DMG_NAME}"
                sparkle:edSignature="PASTE_SIGNATURE_HERE"
                length="${FILE_SIZE}"
                type="application/octet-stream"
            />
            <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
        </item>
EOF
echo ""

# Step 4: Instructions for GitHub release
echo "📤 Step 4: Create GitHub Release"
echo ""
echo "Manual steps:"
echo "  1. Sign the DMG:"
echo "     sign_update \"$DMG_PATH\""
echo ""
echo "  2. Go to: https://github.com/havo-anz/RTOTracker/releases/new"
echo "  3. Tag: v${VERSION}"
echo "  4. Title: RTO Tracker v${VERSION}"
echo "  5. Upload: $DMG_PATH"
echo "  6. Publish release"
echo ""
echo "  7. Update appcast.xml with the entry above"
echo "  8. Commit and push appcast.xml"
echo ""

# Step 5: Automated GitHub release (if gh CLI is available)
if command -v gh &> /dev/null; then
    echo "🎉 GitHub CLI detected!"
    echo ""
    read -p "Create GitHub release now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Creating release..."
        gh release create "v${VERSION}" \
            "$DMG_PATH" \
            --title "RTO Tracker v${VERSION}" \
            --notes "See appcast.xml for release notes"

        echo "✅ GitHub release created!"
        echo ""
        echo "Don't forget to:"
        echo "  1. Sign the DMG with sign_update"
        echo "  2. Update appcast.xml with signature"
        echo "  3. git add appcast.xml && git commit && git push"
    fi
else
    echo "💡 Tip: Install GitHub CLI for automated releases:"
    echo "   brew install gh"
fi

echo ""
echo "✅ Release preparation complete!"
echo ""
echo "📋 Checklist:"
echo "  [ ] Sign DMG with sign_update"
echo "  [ ] Upload DMG to GitHub Releases"
echo "  [ ] Update appcast.xml with new entry"
echo "  [ ] Commit and push appcast.xml"
echo "  [ ] Test auto-update on a different Mac"
echo ""
