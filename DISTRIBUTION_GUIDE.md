# RTO Tracker - Distribution Guide

## 📦 Building for Distribution

Run the build script:
```bash
cd "/Users/voha/Source/RTO Tracker"
./build-release.sh
```

This creates: `releases/RTO-Tracker-Installer-v1.0.dmg` (~126 KB)

---

## 📤 How to Share

### Option 1: Email (Small Groups)

Attach `RTO-Tracker-Installer-v1.0.dmg` and include:

```
Hi team,

Here's the RTO Tracker app for automatic office attendance tracking.

QUICK START:
1. Download the DMG file
2. Double-click to open
3. Drag "RTO Tracker" to Applications
4. Right-click → Open (first time only)
5. Look for building icon in menu bar
6. Go to Settings → Test Connection to verify your office IP

Default IP prefix: 10.78.x.x (update if different)
```

### Option 2: Shared Drive

Upload to OneDrive/Google Drive and share the link.

### Option 3: GitHub Releases

See `GITHUB_RELEASE_GUIDE.md` for creating releases.

---

## ⚠️ Important Notes for Users

### First Launch

**Unsigned App Warning:**
- The app is unsigned (no Apple Developer ID)
- Users must **Right-click → Open** on first launch
- This is normal for internal tools

### Configuration

Users should:
1. Click menu bar icon → Settings
2. Click "Test Connection" to see their IP
3. Update IP Prefix if office network is different from `10.78.`
4. Enable "Launch at login" for automatic tracking

### Privacy

- All data stored locally on their Mac
- No cloud sync or uploads
- Only reads local IP address
- No permissions required

---

## 🔄 Distributing Updates

1. Update version in `Info.plist`
2. Run `./build-release.sh`
3. Email new DMG to users
4. Users can install over existing app (data preserved)

---

## 🎯 Recommended Rollout

**Phase 1: Pilot (3-5 people)**
- Gather feedback
- Fix critical bugs

**Phase 2: Department**
- Roll out to team
- Create FAQ

**Phase 3: Wider Distribution**
- Share via email/Slack
- Provide support channel

---

## Sample Distribution Email

```
Subject: RTO Tracker - Automatic Office Attendance Tracking

Hi everyone,

To make RTO tracking easier, here's a Mac app that automatically tracks office days.

📥 DOWNLOAD:
[Attach RTO-Tracker-Installer-v1.0.dmg]

⚡ QUICK INSTALL:
1. Open DMG → drag to Applications
2. Right-click app → Open (first time)
3. Configure office IP in Settings

🎯 FEATURES:
• Automatic tracking via IP detection
• Runs in menu bar
• Shows quarterly progress
• 100% local - no data uploaded

Note: Right-click → Open on first launch (unsigned app)

Questions? Reply to this email.
```
