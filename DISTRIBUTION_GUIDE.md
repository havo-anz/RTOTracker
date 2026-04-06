# RTO Tracker - Distribution Guide

## 📦 What You Have

Your installation package is ready:
```
/Users/voha/Source/RTO Tracker/releases/RTO-Tracker-Installer-v1.0.dmg
```

**File size:** ~126 KB  
**Format:** Compressed DMG (Universal, works on all Macs)

---

## 📤 How to Share with Colleagues

### Option 1: Email (Recommended for Small Groups)
1. Attach `RTO-Tracker-Installer-v1.0.dmg` to email
2. Include `INSTALLATION_GUIDE.md` in the email body
3. Add this quick start:

```
Hi team,

Here's the RTO Tracker app to help track office attendance automatically.

QUICK START:
1. Download the attached DMG file
2. Double-click to open it
3. Drag "RTO Tracker" to Applications
4. Right-click the app → Open (first time only)
5. Look for building icon in menu bar

IMPORTANT: Click "Test Connection" in Settings to verify your office IP.
Default is set to 10.78.x.x - update if different.

See attached guide for full instructions.
```

### Option 2: Shared Drive
1. Upload to company shared drive (OneDrive, Google Drive, etc.)
2. Share the link with your team
3. Include installation instructions

### Option 3: Internal Software Repository
If your company has an internal software repo:
```bash
# File to upload
/Users/voha/Source/RTO Tracker/releases/RTO-Tracker-Installer-v1.0.dmg

# Documentation
/Users/voha/Source/RTO Tracker/INSTALLATION_GUIDE.md
```

---

## 🔄 Building Future Updates

### Quick Rebuild
```bash
cd "/Users/voha/Source/RTO Tracker"
./build-release.sh
```

This will create a new DMG in the `releases/` folder.

### Before Distributing Updates
1. Update version number in:
   - `build-release.sh` (VERSION variable)
   - `Info.plist` (CFBundleShortVersionString)
2. Test the app thoroughly
3. Update release notes

### Version Numbering
- v1.0 - Initial release
- v1.1 - Minor updates (bug fixes)
- v2.0 - Major updates (new features)

---

## ⚠️ Important Notes

### Security Considerations

**Unsigned App Warning:**
The app is currently **unsigned**, which means:
- Users will see a security warning on first launch
- They must **Right-click → Open** (not double-click)
- This is normal for internal tools

**To Sign the App (Optional):**
1. Get Apple Developer Account ($99/year)
2. Create Developer ID Application certificate
3. Update `build-release.sh` to add codesigning:
```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --options runtime \
  "$APP_PATH"
```

### Privacy & Data

**Users should know:**
- ✅ All data stays local on their Mac
- ✅ No cloud sync or external connections
- ✅ Only reads local IP address
- ✅ No analytics or tracking
- ✅ Open source - code can be reviewed

### Support Plan

**Before distributing:**
1. Set up a support channel (Slack, Teams, email)
2. Assign someone to answer questions
3. Have a troubleshooting guide ready

**Common first-time issues:**
- Wrong IP prefix → Show how to test in Settings
- App won't open → Guide through Right-click → Open
- Not tracking → Check Launch at Login is enabled

---

## 📊 Testing Before Distribution

### Test Checklist
- [ ] App opens without crashes
- [ ] Settings window opens
- [ ] IP detection works
- [ ] Menu bar icon visible
- [ ] Progress tracking accurate
- [ ] Data persists after restart
- [ ] Works on different macOS versions

### Test on Another Mac
```bash
# Copy DMG to test Mac
scp "/Users/voha/Source/RTO Tracker/releases/RTO-Tracker-Installer-v1.0.dmg" user@testmac:~/Downloads/

# Install and test as end user would
```

---

## 🎯 Recommended Rollout Plan

### Phase 1: Pilot (Week 1)
- Share with 3-5 trusted colleagues
- Gather feedback
- Fix any critical bugs
- Update documentation

### Phase 2: Department (Week 2)
- Share with your department
- Monitor for issues
- Create FAQ based on questions

### Phase 3: Company-Wide (Week 3+)
- Announce via email/Slack
- Provide installation support hours
- Collect feature requests

---

## 📝 Sample Distribution Email

```
Subject: RTO Tracker - Automatic Office Attendance Tracking

Hi everyone,

To make RTO tracking easier, I've created a simple Mac app that automatically tracks your office days.

📥 DOWNLOAD:
[Attach RTO-Tracker-Installer-v1.0.dmg]

⚡ QUICK INSTALL:
1. Open the DMG file
2. Drag "RTO Tracker" to Applications
3. Right-click app → Open (first time only)
4. Configure your office IP in Settings

🎯 FEATURES:
• Automatic tracking - no manual input needed
• Runs in menu bar - always visible
• Shows quarterly progress
• Reminds you when falling behind
• 100% local - no data uploaded

📖 FULL GUIDE:
See attached INSTALLATION_GUIDE.md for detailed instructions

❓ SUPPORT:
Questions? Message me or check #rto-tracker channel

Note: The app is internal-use only and not signed by Apple. 
You'll need to Right-click → Open on first launch.

Cheers!
```

---

## 🔧 Maintenance

### When to Release Updates

**Immediate (within 24h):**
- Security vulnerabilities
- Data loss bugs
- Crash on launch

**Next Week:**
- Wrong calculations
- UI glitches
- Minor bugs

**Next Quarter:**
- Feature requests
- Performance improvements
- UI enhancements

### Update Distribution
1. Build new DMG with updated version number
2. Email users with changelog
3. Users can install over existing app

---

## 📞 Getting Help

If you encounter issues during distribution:
1. Check build logs in Xcode
2. Verify DMG integrity: `hdiutil verify <dmg-file>`
3. Test on a fresh Mac
4. Review Console.app for crash logs

---

**Happy Distributing! 🚀**
