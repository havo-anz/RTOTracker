# Quick Sparkle Testing Guide

## Before You Start

Current status:
- Version 1.0 (build 1) is your baseline
- You'll create version 1.1 (build 2) as the update

## Step-by-Step Test

### 1. Generate Keys (One-Time Setup)

```bash
cd /Users/voha/Downloads/Sparkle-2.x
./bin/generate_keys
```

**Save both keys securely!**

Copy the **PUBLIC KEY** to Info.plist:
```xml
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_HERE</string>
```

Save the **PRIVATE KEY** to a file:
```bash
cd "/Users/voha/Source/RTO Tracker/RTOTracker"
echo "YOUR_PRIVATE_KEY_HERE" > .sparkle-private-key
chmod 600 .sparkle-private-key
```

### 2. Build Version 1.1

Update version in Info.plist:
```xml
<key>CFBundleShortVersionString</key>
<string>1.1</string>
<key>CFBundleVersion</key>
<string>2</string>
```

Build archive:
```bash
cd "/Users/voha/Source/RTO Tracker/RTOTracker"
mkdir -p build

xcodebuild -project RTOTracker.xcodeproj \
           -scheme RTOTracker \
           -configuration Release \
           -archivePath ./build/RTOTracker-v1.1.xcarchive \
           archive
```

### 3. Create Update Package

```bash
cd build

# Create zip
ditto -c -k --sequesterRsrc --keepParent \
    RTOTracker-v1.1.xcarchive/Products/Applications/RTOTracker.app \
    RTOTracker-1.1.zip

# Get file size
ls -l RTOTracker-1.1.zip
# Note the file size (e.g., 4567890 bytes)
```

### 4. Sign the Update

```bash
cd /Users/voha/Downloads/Sparkle-2.x

./bin/sign_update \
    "/Users/voha/Source/RTO Tracker/RTOTracker/build/RTOTracker-1.1.zip" \
    --ed-key-file "/Users/voha/Source/RTO Tracker/RTOTracker/.sparkle-private-key"
```

**Copy the signature output** (looks like: `MC0CFG...`)

### 5. Create Test Appcast

```bash
cd "/Users/voha/Source/RTO Tracker/RTOTracker/build"

cat > test-appcast.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>RTO Tracker Test</title>
        <item>
            <title>Version 1.1</title>
            <pubDate>Wed, 09 Apr 2026 00:00:00 +0000</pubDate>
            <sparkle:version>2</sparkle:version>
            <sparkle:shortVersionString>1.1</sparkle:shortVersionString>
            <enclosure
                url="file:///Users/voha/Source/RTO%20Tracker/RTOTracker/build/RTOTracker-1.1.zip"
                sparkle:edSignature="PASTE_SIGNATURE_HERE"
                length="PASTE_FILE_SIZE_HERE"
                type="application/octet-stream" />
            <description><![CDATA[
                <h2>Test Update v1.1</h2>
                <ul><li>Testing Sparkle updates!</li></ul>
            ]]></description>
        </item>
    </channel>
</rss>
EOF
```

Replace:
- `PASTE_SIGNATURE_HERE` with signature from step 4
- `PASTE_FILE_SIZE_HERE` with file size from step 3

### 6. Point App to Test Feed

Backup Info.plist:
```bash
cd "/Users/voha/Source/RTO Tracker/RTOTracker/RTOTracker"
cp Info.plist Info.plist.backup
```

Update SUFeedURL:
```bash
/usr/libexec/PlistBuddy -c "Set :SUFeedURL file:///Users/voha/Source/RTO%20Tracker/RTOTracker/build/test-appcast.xml" Info.plist
```

### 7. Test the Update Flow

**Important:** Revert to version 1.0 first:
```bash
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.0" Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1" Info.plist
```

Build and run in Xcode:
```bash
open RTOTracker.xcodeproj
# Press ⌘R
```

In the running app:
1. Click menu bar icon
2. Click "Check for Updates..."
3. **You should see update dialog!** ✅

### 8. Verify Update

After clicking "Install Update":
- App downloads update
- Shows installation progress
- Relaunches automatically
- Check About → should show version 1.1

### 9. Cleanup

Restore original Info.plist:
```bash
cd "/Users/voha/Source/RTO Tracker/RTOTracker/RTOTracker"
mv Info.plist.backup Info.plist
```

---

## Troubleshooting

### "No updates available"

**Check signature:**
```bash
cd /Users/voha/Downloads/Sparkle-2.x

./bin/sign_update --verify \
    "/Users/voha/Source/RTO Tracker/RTOTracker/build/RTOTracker-1.1.zip" \
    --ed-key-file "/Users/voha/Source/RTO Tracker/RTOTracker/.sparkle-private-key"
```

Should output: `Signature verified`

**Check public key in Info.plist matches:**
```bash
grep "SUPublicEDKey" "/Users/voha/Source/RTO Tracker/RTOTracker/RTOTracker/Info.plist"
```

### "Keys not generated"

Check console output when app launches:
```bash
# Run app, then check logs:
log show --predicate 'process == "RTOTracker"' --last 5m | grep -i sparkle
```

If you see "EdDSA keys not generated yet" - public key in Info.plist is still placeholder.

### Version not updating

Make sure:
- CFBundleVersion is higher (1 → 2)
- Test appcast uses `sparkle:version="2"`
- Running app is version 1, update is version 2

### File not found

Check file URL encoding:
```bash
# Should be:
file:///Users/voha/Source/RTO%20Tracker/RTOTracker/build/RTOTracker-1.1.zip

# Note: Spaces are encoded as %20
```

---

## Quick Debug Commands

```bash
# View current version
defaults read "/Users/voha/Source/RTO Tracker/RTOTracker/RTOTracker/Info.plist" CFBundleShortVersionString

# Check if keys exist
cat "/Users/voha/Source/RTO Tracker/RTOTracker/.sparkle-private-key"
grep "SUPublicEDKey" "/Users/voha/Source/RTO Tracker/RTOTracker/RTOTracker/Info.plist"

# Test appcast is valid
cat "/Users/voha/Source/RTO Tracker/RTOTracker/build/test-appcast.xml"

# File exists and has size
ls -lh "/Users/voha/Source/RTO Tracker/RTOTracker/build/RTOTracker-1.1.zip"
```

---

## Testing Checklist

- [ ] Keys generated and saved
- [ ] Public key in Info.plist
- [ ] Private key in .sparkle-private-key
- [ ] Version 1.1 built successfully
- [ ] RTOTracker-1.1.zip created
- [ ] Update signed (signature obtained)
- [ ] test-appcast.xml created with correct signature and size
- [ ] SUFeedURL points to test-appcast.xml
- [ ] App reverted to version 1.0
- [ ] App launched and "Check for Updates" works
- [ ] Update dialog appears
- [ ] Update downloads and installs
- [ ] App relaunches as version 1.1

---

## Next: Production Testing

Once local testing works, push to GitHub:

1. Create `appcast.xml` in repo root
2. Upload `RTOTracker-1.1.zip` to releases/
3. Update SUFeedURL to GitHub URL:
   ```
   https://raw.githubusercontent.com/havo-anz/RTOTracker/main/appcast.xml
   ```
4. Commit and push
5. Test with real URL!
