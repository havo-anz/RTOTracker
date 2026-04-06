# RTO Tracker - Installation Guide for Users

## 📥 Installation (5 minutes)

### Step 1: Download & Install
1. Download the `RTO-Tracker-Installer-v1.0.dmg` file
2. Double-click the DMG file to open it
3. Drag **RTO Tracker** to the **Applications** folder
4. Eject the DMG (right-click → Eject)

### Step 2: First Launch
1. Open **Finder** → **Applications**
2. Find **RTO Tracker**
3. **Right-click** → **Open** (important for first launch!)
4. Click **Open** when macOS asks "Are you sure?"
   - This is normal for apps not from the App Store

### Step 3: Configure Settings
1. Look for the building icon (🏢) in your menu bar (top right)
2. Click the icon → **Settings**
3. Click **Test Connection**
4. Verify your IP address is shown
5. Update **IP Prefix** if your office network is not `10.78.`

That's it! The app is now running and tracking.

---

## ⚙️ Configuration

### Finding Your Office IP Prefix

**Option 1: Use the app**
- Settings → Test Connection → note your IP when at office

**Option 2: Terminal**
```bash
ifconfig en0 | grep "inet " | awk '{print $2}'
```

Example: If your IP is `10.78.123.45`, the prefix is `10.78.`

### Recommended Settings

| Setting | Recommended Value | Notes |
|---------|------------------|-------|
| IP Prefix | `10.78.` | Change based on your office network |
| Quarter Target | `36` | Standard RTO requirement |
| Reminders | Enabled @ 9:15 AM | Morning reminder works best |
| Launch at Login | ✅ Enabled | Auto-track without manual start |

---

## 🚀 Daily Usage

### Normal Operation
**You don't need to do anything!** The app works automatically:

1. App runs in background (menu bar icon)
2. Checks your IP every 5 minutes
3. Marks day as "office day" when connected to office network
4. Shows progress in menu bar dropdown

### Checking Your Progress
1. Click the menu bar icon
2. See current quarter progress
3. View days remaining
4. Check required pace

### Manual Override (if needed)
Use this if detection fails or you worked from a different device:
1. Click menu bar icon → View Calendar
2. Click on a day to manually mark it

---

## ⚠️ Important Notes

### VPN Usage
- **VPN from home does NOT count** as an office day
- Only physical presence at office is tracked
- If your VPN uses the same IP range, tracking may be inaccurate

### Privacy & Security
- ✅ All data stored locally on your Mac
- ✅ No cloud sync or data upload
- ✅ Only reads your local IP address
- ✅ No permissions required
- ✅ Open source - you can review the code

### Data Backup
Your tracking data is stored at:
```
~/Library/Preferences/com.rtotracker.RTOTracker.plist
```

To backup: Copy this file to a safe location

---

## 🔧 Troubleshooting

### App Won't Open
**Problem:** macOS blocks the app  
**Solution:** Right-click → Open (don't double-click)

### Menu Bar Icon Missing
**Problem:** App crashed or closed  
**Solution:** Relaunch from Applications folder

### Not Tracking Days
**Problem:** IP prefix is incorrect  
**Solution:**
1. Settings → Test Connection
2. Verify your current IP
3. Update IP Prefix to match

### Want to Start Fresh
**Solution:**
```bash
defaults delete com.rtotracker.RTOTracker
```
Then relaunch the app

---

## 🆘 Support

### Check Logs
Open **Console.app** → search for "RTOTracker"

### Common Questions

**Q: Do I need to keep the app open?**  
A: No, it runs in the menu bar. Don't quit it!

**Q: Will it drain my battery?**  
A: No, it only checks IP every 5 minutes (very light)

**Q: Can I use it on multiple Macs?**  
A: Yes, but each Mac tracks independently (no sync)

**Q: What if I forget to launch it?**  
A: Enable "Launch at login" in Settings

**Q: How do I uninstall?**  
A: Drag from Applications to Trash

---

## 📊 Understanding Your Data

### Quarter Dates
- Q1: January 1 - March 31
- Q2: April 1 - June 30
- Q3: July 1 - September 30
- Q4: October 1 - December 31

### Required Pace
The app calculates: `(Days Needed) / (Weeks Left)`

Example:
- Target: 36 days
- Current: 20 days
- Weeks left: 4
- Pace needed: 4 days/week

---

## 🎯 Best Practices

1. **Enable "Launch at login"** - Never miss tracking
2. **Check weekly** - Stay on pace
3. **Test IP when traveling** - New office location?
4. **Manual override sparingly** - Use only when detection fails
5. **Keep app updated** - Check for new versions quarterly

---

## 📞 Getting Help

For issues or questions:
1. Check this guide first
2. Ask the person who shared the app
3. Check Console.app logs for errors

---

**Version:** 1.0  
**Last Updated:** April 2026  
**For Internal Use Only**
