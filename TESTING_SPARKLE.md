# Testing Sparkle Auto-Updates

## Prerequisites

✅ Sparkle is at: `/Users/voha/Downloads/Sparkle-2.x`
✅ Current version: 1.0 (build 1)

## Step 1: Generate EdDSA Keys

```bash
cd /Users/voha/Downloads/Sparkle-2.x
./bin/generate_keys
```

This will output:
- **Public Key** (SUPublicEDKey) - Goes in Info.plist
- **Private Key** (edDSA key) - Keep this SECRET! Use for signing updates

**IMPORTANT**: Save the private key somewhere safe (like 1Password or .env file)

## Step 2: Update Info.plist with Public Key

1. Open `RTOTracker/RTOTracker/Info.plist`
2. Replace `PLACEHOLDER_GENERATE_KEYS_FIRST` with the public key
3. Save and rebuild the app

## Step 3: Build Version 1.0 (Current Release)

```bash
cd "/Users/voha/Source/RTO Tracker/RTOTracker"

# Build and archive
xcodebuild -project RTOTracker.xcodeproj \
           -scheme RTOTracker \
           -configuration Release \
           -archivePath ./build/RTOTracker-v1.0.xcarchive \
           archive

# Export the app
xcodebuild -exportArchive \
           -archivePath ./build/RTOTracker-v1.0.xcarchive \
           -exportPath ./build/Release-v1.0 \
           -exportOptionsPlist exportOptions.plist
```

## Step 4: Create a Test Update (Version 1.1)

### 4a. Bump the version

In Xcode:
1. Select RTOTracker target
2. General → Version: `1.1`
3. Build: `2`

Or via command line:
```bash
# Update version in project.pbxproj or use agvtool
xcrun agvtool new-marketing-version 1.1
xcrun agvtool new-version -all 2
```

### 4b. Make a visible change

Add something obvious like a new menu item:

```swift
// In MenuView.swift, add to actionsView:
Text("✨ Updated to v1.1!")
    .font(.caption)
    .foregroundColor(.green)
```

### 4c. Build version 1.1

```bash
xcodebuild -project RTOTracker.xcodeproj \
           -scheme RTOTracker \
           -configuration Release \
           -archivePath ./build/RTOTracker-v1.1.xcarchive \
           archive
```

## Step 5: Create Update Package

```bash
cd build

# Create a zip of the v1.1 app
ditto -c -k --sequesterRsrc --keepParent \
    RTOTracker-v1.1.xcarchive/Products/Applications/RTOTracker.app \
    RTOTracker-1.1.zip

# Get file size for appcast
ls -l RTOTracker-1.1.zip
```

## Step 6: Sign the Update

```bash
cd /Users/voha/Downloads/Sparkle-2.x

# Sign the update (replace YOUR_PRIVATE_KEY with the key from Step 1)
./bin/sign_update "/Users/voha/Source/RTO Tracker/RTOTracker/build/RTOTracker-1.1.zip" \
    --ed-key-file <(echo "YOUR_PRIVATE_KEY_HERE")
```

This outputs the EdDSA signature needed for appcast.xml.

## Step 7: Create appcast.xml

Create or update `appcast.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>RTO Tracker Updates</title>
        <link>https://raw.githubusercontent.com/havo-anz/RTOTracker/main/appcast.xml</link>
        <description>Updates for RTO Tracker</description>
        <language>en</language>
        
        <item>
            <title>Version 1.1</title>
            <pubDate>Tue, 08 Apr 2026 00:00:00 +0000</pubDate>
            <sparkle:version>2</sparkle:version>
            <sparkle:shortVersionString>1.1</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <enclosure 
                url="https://raw.githubusercontent.com/havo-anz/RTOTracker/main/releases/RTOTracker-1.1.zip"
                sparkle:edSignature="SIGNATURE_FROM_STEP_6"
                length="FILE_SIZE_FROM_STEP_5"
                type="application/octet-stream" />
            <description><![CDATA[
                <h2>What's New in 1.1</h2>
                <ul>
                    <li>Fixed menu panel closing when opening Calendar/Settings</li>
                    <li>Fixed tracking status logic (now requires meeting expectations)</li>
                    <li>Fixed quarter date boundaries (Q2 now ends June 30, not July 1)</li>
                    <li>Improved calendar day tap area</li>
                    <li>Added comprehensive unit tests</li>
                </ul>
            ]]></description>
        </item>
    </channel>
</rss>
```

## Step 8: Test Locally (Option A - Easiest)

### Test with local appcast.xml

1. **Create test appcast**:
```bash
cd "/Users/voha/Source/RTO Tracker/RTOTracker/build"
cat > test-appcast.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>RTO Tracker Test Updates</title>
        <item>
            <title>Version 1.1 (Test)</title>
            <sparkle:version>2</sparkle:version>
            <sparkle:shortVersionString>1.1</sparkle:shortVersionString>
            <enclosure 
                url="file:///Users/voha/Source/RTO%20Tracker/RTOTracker/build/RTOTracker-1.1.zip"
                sparkle:edSignature="YOUR_SIGNATURE_HERE"
                length="FILE_SIZE"
                type="application/octet-stream" />
            <description><![CDATA[<h2>Test Update</h2>]]></description>
        </item>
    </channel>
</rss>
EOF
```

2. **Temporarily change SUFeedURL in Info.plist**:
```xml
<key>SUFeedURL</key>
<string>file:///Users/voha/Source/RTO%20Tracker/RTOTracker/build/test-appcast.xml</string>
```

3. **Build and run v1.0**
4. **Click "Check for Updates..."** in menu
5. **Update should be detected!**

## Step 9: Test in Production (Option B)

1. **Push to GitHub**:
```bash
# Create releases directory
mkdir -p releases
mv build/RTOTracker-1.1.zip releases/

# Commit appcast.xml
git add appcast.xml releases/
git commit -m "Add version 1.1 update"
git push
```

2. **Wait a few minutes** for GitHub to serve the files

3. **Run v1.0 and check for updates**

## Testing Checklist

- [ ] Manual update check works (Click "Check for Updates...")
- [ ] Update dialog shows correct version (1.1)
- [ ] Release notes display properly
- [ ] Download progress shows
- [ ] Installation succeeds
- [ ] App relaunches automatically
- [ ] New version is running (shows "✨ Updated to v1.1!")
- [ ] Background check works (wait 24 hours or reduce SUScheduledCheckInterval)

## Debugging Tips

### If update check shows "No updates available":

```bash
# Check if keys match
cd /Users/voha/Downloads/Sparkle-2.x
./bin/sign_update --verify \
    "/Users/voha/Source/RTO Tracker/RTOTracker/build/RTOTracker-1.1.zip" \
    --ed-key-file <(echo "YOUR_PRIVATE_KEY") \
    --pub-key "PUBLIC_KEY_FROM_INFO_PLIST"
```

### View Sparkle logs:

```bash
# Console.app → search for "Sparkle" or "RTOTracker"
# Or check system log:
log show --predicate 'process == "RTOTracker"' --last 1h | grep -i sparkle
```

### Common issues:

1. **Signature mismatch** - Public key in Info.plist doesn't match private key used for signing
2. **Version not higher** - CFBundleVersion must be greater (1 → 2)
3. **URL not accessible** - File:// paths need proper encoding, HTTPS must be reachable
4. **Keys not generated** - Check console for "EdDSA keys not generated yet" message

## Advanced: Test with Python HTTP Server

```bash
# Serve appcast locally
cd "/Users/voha/Source/RTO Tracker/RTOTracker/build"
python3 -m http.server 8080

# Update Info.plist temporarily:
# <string>http://localhost:8080/test-appcast.xml</string>

# Update test-appcast.xml URL:
# url="http://localhost:8080/RTOTracker-1.1.zip"
```

Then run the app and check for updates!

## Quick Test Script

```bash
#!/bin/bash
# quick-test-sparkle.sh

echo "🔑 Step 1: Generate keys"
cd /Users/voha/Downloads/Sparkle-2.x
./bin/generate_keys

echo ""
echo "📝 Step 2: Copy the PUBLIC KEY above and paste it in Info.plist"
echo "Press Enter when done..."
read

echo ""
echo "🏗️  Step 3: Building v1.0..."
cd "/Users/voha/Source/RTO Tracker/RTOTracker"
xcodebuild -project RTOTracker.xcodeproj -scheme RTOTracker -configuration Release clean build

echo ""
echo "✏️  Step 4: Update version to 1.1 in Xcode"
echo "Press Enter when done..."
read

echo ""
echo "🏗️  Step 5: Building v1.1..."
mkdir -p build
xcodebuild -project RTOTracker.xcodeproj -scheme RTOTracker -configuration Release -archivePath ./build/RTOTracker-v1.1.xcarchive archive

echo ""
echo "📦 Step 6: Creating update package..."
cd build
ditto -c -k --sequesterRsrc --keepParent RTOTracker-v1.1.xcarchive/Products/Applications/RTOTracker.app RTOTracker-1.1.zip

echo ""
echo "✍️  Step 7: Sign the update with your PRIVATE KEY"
echo "Paste your private key and press Enter:"
read PRIVATE_KEY

cd /Users/voha/Downloads/Sparkle-2.x
./bin/sign_update "/Users/voha/Source/RTO Tracker/RTOTracker/build/RTOTracker-1.1.zip" --ed-key-file <(echo "$PRIVATE_KEY")

echo ""
echo "✅ Done! Copy the signature above to appcast.xml"
```

Save this as `quick-test-sparkle.sh` and run: `chmod +x quick-test-sparkle.sh && ./quick-test-sparkle.sh`
