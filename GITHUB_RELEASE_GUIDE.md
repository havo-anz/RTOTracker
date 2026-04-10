# Creating GitHub Releases for RTO Tracker

## Quick Release with Script

The easiest way to create a DMG:

```bash
cd "/Users/voha/Source/RTO Tracker"
./build-release.sh
```

This creates `releases/RTO-Tracker-Installer-v1.0.dmg`

---

## Manual Build Steps

### 1. Build Release Archive

```bash
cd "/Users/voha/Source/RTO Tracker/RTOTracker"

# Update version in Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.1" RTOTracker/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 2" RTOTracker/Info.plist

# Build
xcodebuild -project RTOTracker.xcodeproj \
           -scheme RTOTracker \
           -configuration Release \
           -archivePath ./build/RTOTracker.xcarchive \
           archive
```

### 2. Create DMG

```bash
cd "/Users/voha/Source/RTO Tracker/RTOTracker/build"

# Create temp folder
mkdir DMG_Temp
cp -r RTOTracker.xcarchive/Products/Applications/RTOTracker.app DMG_Temp/
ln -s /Applications DMG_Temp/Applications

# Create DMG
hdiutil create -volname "RTO Tracker 1.1" \
               -srcfolder DMG_Temp \
               -ov -format UDZO \
               RTOTracker-1.1.dmg

rm -rf DMG_Temp
```

---

## Creating GitHub Release

### Option 1: GitHub CLI

```bash
cd "/Users/voha/Source/RTO Tracker/RTOTracker/build"

gh release create v1.1 \
    RTOTracker-1.1.dmg \
    --repo havo-anz/RTOTracker \
    --title "RTO Tracker v1.1" \
    --notes "Bug fixes and improvements"
```

### Option 2: GitHub Web UI

1. Go to: https://github.com/havo-anz/RTOTracker/releases
2. Click **"Draft a new release"**
3. Tag: `v1.1`
4. Title: `RTO Tracker v1.1`
5. Upload `RTOTracker-1.1.dmg`
6. Add release notes
7. Click **"Publish release"**

---

## Release Checklist

- [ ] Version updated in Info.plist
- [ ] Release archive built successfully
- [ ] DMG created and tested
- [ ] GitHub release created with DMG attached
- [ ] Release notes added
- [ ] Tested installation on fresh Mac

---

## Version Naming

Use semantic versioning:
- `v1.0.0` - Major release
- `v1.1.0` - Minor update (new features)
- `v1.0.1` - Patch (bug fixes)
