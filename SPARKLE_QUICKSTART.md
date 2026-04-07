# Sparkle Auto-Update - Quick Start

## 🚀 5-Minute Setup

### Step 1: Add Sparkle Framework (2 minutes)

1. **Open Xcode** - Open `RTOTracker.xcodeproj`

2. **Add Sparkle Package:**
   - File → Add Package Dependencies...
   - Paste: `https://github.com/sparkle-project/Sparkle`
   - Version: `2.6.0` or "Up to Next Major Version"
   - Click "Add Package"
   - Select "Sparkle" and click "Add Package"

3. **Build to verify:**
   ```bash
   cd "/Users/voha/Source/RTO Tracker/RTOTracker"
   xcodebuild -project RTOTracker.xcodeproj -scheme RTOTracker build
   ```

### Step 2: Generate EdDSA Keys (1 minute)

Run this after Sparkle is added:

```bash
# The generate_keys tool will be available after adding Sparkle
# Location varies by how Sparkle was added

# If using SPM, try:
cd ~/Library/Developer/Xcode/DerivedData/RTOTracker-*/SourcePackages/checkouts/Sparkle/
./bin/generate_keys
```

**Output will look like:**
```
A key has been generated and saved in your Keychain (RTOTracker Key)

Public key:
ABC123XYZ...base64string...

Add this to your Info.plist as SUPublicEDKey
```

**Copy the public key** (the long base64 string)

### Step 3: Update Info.plist (1 minute)

1. Open `RTOTracker/RTOTracker/Info.plist`
2. Find `SUPublicEDKey`
3. Replace `PLACEHOLDER_GENERATE_KEYS_FIRST` with your public key

### Step 4: Commit & Push Appcast (1 minute)

```bash
cd "/Users/voha/Source/RTO Tracker"
git add appcast.xml
git commit -m "Add appcast.xml for auto-updates"
git push
```

### Step 5: Test It!

1. **Build and run the app**
2. **Click menu bar icon** → **"Check for Updates..."**
3. **Should see:** "You're up to date!" (or update dialog if new version exists)

---

## ✅ You're Done!

**What works now:**
- ✅ "Check for Updates" button in menu
- ✅ Automatic background update checks (every 24 hours)
- ✅ Update notifications when new version is available
- ✅ One-click update & relaunch

**When you release a new version:**
1. Build DMG with `./build-release.sh`
2. Sign it: `sign_update path/to/app.dmg`
3. Upload to GitHub Releases
4. Update `appcast.xml` with new version entry
5. Users get notified automatically!

---

## 🔍 Troubleshooting

### "Cannot find module 'Sparkle'"
- Make sure you added Sparkle via Xcode SPM (File → Add Package Dependencies)
- Clean build folder: Product → Clean Build Folder
- Restart Xcode

### "generate_keys not found"
- The tool is in the Sparkle package
- Check: `~/Library/Developer/Xcode/DerivedData/RTOTracker-*/SourcePackages/checkouts/Sparkle/bin/`
- Or download from: https://github.com/sparkle-project/Sparkle/releases

### "Update check does nothing"
- Check Info.plist has valid `SUFeedURL` and `SUPublicEDKey`
- Make sure appcast.xml is accessible at the URL
- Check Console.app for Sparkle errors

---

## 📚 Full Documentation

See `SPARKLE_SETUP.md` for complete documentation including:
- Detailed signing instructions
- Appcast.xml format
- Release automation
- Security best practices

---

## 🎯 Next Steps

1. Add Sparkle framework (Step 1 above)
2. Generate keys and update Info.plist
3. Build and test
4. When ready to release v1.1:
   ```bash
   ./release.sh 1.1
   ```

That's it! Your users will get automatic updates! 🎉
