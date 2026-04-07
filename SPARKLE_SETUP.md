# Sparkle Auto-Update Setup Guide

## 📦 Step 1: Add Sparkle Framework to Xcode

### Via Swift Package Manager (Recommended):

1. **Open Xcode** → Open `RTOTracker.xcodeproj`
2. **File** → **Add Package Dependencies...**
3. **Enter URL:** `https://github.com/sparkle-project/Sparkle`
4. **Version:** `2.6.0` (or "Up to Next Major Version")
5. **Click "Add Package"**
6. **Select:** Check `Sparkle` and click "Add Package"

### Verify Installation:
- In Project Navigator, you should see "Sparkle" under "Package Dependencies"
- Build the project (⌘B) to ensure Sparkle compiles

---

## 🔧 Step 2: Configuration (Already Done!)

I've already created these files for you:
- ✅ `UpdateChecker.swift` - Service to manage updates
- ✅ Updated `Info.plist` - Sparkle configuration
- ✅ Updated `AppDelegate.swift` - Integrated update checker
- ✅ Updated `MenuView.swift` - Added "Check for Updates" button

---

## 📝 Step 3: Update Info.plist

Add these keys to your `Info.plist`:

```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/havo-anz/RTOTracker/main/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_HERE</string>
<key>SUEnableAutomaticChecks</key>
<true/>
<key>SUScheduledCheckInterval</key>
<integer>86400</integer>
```

**What they mean:**
- `SUFeedURL` - Where to check for updates (appcast.xml location)
- `SUPublicEDKey` - EdDSA public key for verifying updates (security)
- `SUEnableAutomaticChecks` - Check for updates automatically
- `SUScheduledCheckInterval` - Check every 86400 seconds (24 hours)

---

## 🔐 Step 4: Generate Signing Keys (For Security)

Sparkle uses EdDSA signing to ensure updates are legitimate.

### Generate Keys:

```bash
# This will be installed when you add Sparkle
# Run from your project directory
cd "/Users/voha/Source/RTO Tracker"

# Generate key pair
./Pods/Sparkle/bin/generate_keys

# OR if using SPM:
swift run --package-path /path/to/Sparkle generate_keys
```

**Output:**
```
A key has been generated and saved in your Keychain.

Public key:
[BASE64_STRING_HERE]

Add this to your Info.plist as SUPublicEDKey
```

**Important:** 
- Copy the **public key** to Info.plist (`SUPublicEDKey`)
- The **private key** stays in your Keychain (used to sign releases)

---

## 📱 Step 5: Create Appcast.xml

This file lists all available versions. Host it on GitHub.

**Location:** `https://raw.githubusercontent.com/havo-anz/RTOTracker/main/appcast.xml`

**Template:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>RTO Tracker Updates</title>
        <link>https://github.com/havo-anz/RTOTracker</link>
        <description>RTO Tracker automatic updates</description>
        <language>en</language>

        <!-- Version 1.1 -->
        <item>
            <title>Version 1.1</title>
            <description><![CDATA[
                <h2>What's New in 1.1</h2>
                <ul>
                    <li>Added calendar view with monthly grid</li>
                    <li>Tracking status indicator (ahead/on track/behind)</li>
                    <li>Wake-from-sleep detection</li>
                    <li>Manual day override capability</li>
                </ul>
            ]]></description>
            <pubDate>Mon, 07 Apr 2026 10:00:00 +0000</pubDate>
            <sparkle:version>1.1.0</sparkle:version>
            <sparkle:shortVersionString>1.1</sparkle:shortVersionString>
            <enclosure 
                url="https://github.com/havo-anz/RTOTracker/releases/download/v1.1/RTO-Tracker-v1.1.dmg"
                sparkle:edSignature="SIGNATURE_HERE"
                length="1234567"
                type="application/octet-stream"
            />
            <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
        </item>

        <!-- Version 1.0 -->
        <item>
            <title>Version 1.0</title>
            <description><![CDATA[
                <h2>Initial Release</h2>
                <ul>
                    <li>Automatic office detection via IP</li>
                    <li>Quarterly progress tracking</li>
                    <li>Menu bar integration</li>
                </ul>
            ]]></description>
            <pubDate>Sun, 06 Apr 2026 14:00:00 +0000</pubDate>
            <sparkle:version>1.0.0</sparkle:version>
            <sparkle:shortVersionString>1.0</sparkle:shortVersionString>
            <enclosure 
                url="https://github.com/havo-anz/RTOTracker/releases/download/v1.0/RTO-Tracker-v1.0.dmg"
                sparkle:edSignature="SIGNATURE_HERE"
                length="1234567"
                type="application/octet-stream"
            />
            <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
        </item>
    </channel>
</rss>
```

---

## 🚀 Step 6: Release Process

### When releasing a new version:

1. **Update version in Xcode:**
   - Target → General → Version: `1.1`
   - Build: `1`

2. **Build release DMG:**
   ```bash
   cd "/Users/voha/Source/RTO Tracker"
   ./build-release.sh
   ```

3. **Sign the DMG** (generates EdDSA signature):
   ```bash
   # Sign with your private key
   sign_update releases/RTO-Tracker-Installer-v1.1.dmg
   ```

4. **Upload to GitHub Releases:**
   - Create new release on GitHub
   - Tag: `v1.1`
   - Upload the DMG file
   - Copy the download URL

5. **Update appcast.xml:**
   - Add new `<item>` entry
   - Set the `url` to GitHub release DMG
   - Add the `sparkle:edSignature` from step 3
   - Set the `length` (file size in bytes)
   - Commit and push appcast.xml

6. **Users get notified!**
   - Next time they launch the app or check for updates
   - They'll see the update dialog
   - One-click install

---

## 🛠️ Helper Script: Sign & Publish

I'll create a script to automate this:

```bash
./release.sh 1.1
```

This will:
1. Build the DMG
2. Sign it with EdDSA
3. Get file size
4. Generate appcast.xml entry
5. Upload to GitHub (with `gh` CLI)

---

## ✅ Testing Auto-Update

### Test locally:

1. **Lower your app version** to 1.0 in Xcode
2. **Build and run**
3. **Click "Check for Updates"**
4. **Should see:** "Version 1.1 is available"

### Test appcast:

```bash
# Validate appcast.xml
curl https://raw.githubusercontent.com/havo-anz/RTOTracker/main/appcast.xml
```

---

## 🔒 Security Notes

**Why signing is important:**
- Prevents malicious updates
- Users can trust the update source
- Sparkle verifies signature before installing

**Keys:**
- **Public key** → In app (Info.plist)
- **Private key** → On your Mac only (in Keychain)
- Never share private key!

---

## 📚 Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Sparkle GitHub](https://github.com/sparkle-project/Sparkle)
- [EdDSA Signing Guide](https://sparkle-project.org/documentation/signing/)

---

## 🎯 Next Steps

1. ✅ Add Sparkle via Xcode SPM (see Step 1 above)
2. ✅ Build project to verify Sparkle compiles
3. ✅ Generate EdDSA keys
4. ✅ Update Info.plist with public key
5. ✅ Create appcast.xml on GitHub
6. ✅ Test "Check for Updates" menu item

Once done, your users will get automatic update notifications! 🎉
