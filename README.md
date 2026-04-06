# RTO Tracker - macOS Menu Bar App

## ✅ What's Been Built

### Core Functionality
- ✅ Menu bar app with automatic office detection via IP address
- ✅ Auto-detection service that polls every 5 minutes
- ✅ Data persistence using UserDefaults
- ✅ Quarter-based tracking (calendar quarters)
- ✅ Progress tracking against 36-day KPI target

### Components Implemented
1. **AppDelegate** - Menu bar management and app lifecycle
2. **Models**
   - `DayRecord` - Tracks daily office attendance
   - `AppSettings` - Configuration (IP prefix, threshold, targets)

3. **Services**
   - `DataManager` - Data persistence and quarter calculations
   - `OfficeDetectionService` - IP detection via en0 interface

4. **Views**
   - `MenuView` - Main dropdown showing progress and stats
   - `SettingsView` - Configuration panel

### Features
- Real-time office detection based on IP prefix (default: 10.78.)
- 30-minute cumulative threshold for confirming a day
- Quarter progress tracking with visual progress bar
- Required pace calculation
- Manual day override capability
- Configurable IP prefix and threshold

## 🚧 What Still Needs to Be Done

### High Priority
1. **Test IP Prefix** - You need to verify the office IP prefix:
   - Click the menu bar icon
   - Go to Settings
   - Click "Test Connection" to see your current IP
   - Update the IP prefix if it's not 10.78.x.x

2. **Assets & Icon** - Create app icon
   - Need to add app icon to Assets catalog
   - Currently using SF Symbol "building.2"

3. **Calendar Detail View**
   - Complete the calendar view to show monthly/weekly breakdown
   - Visual history of confirmed days

### Medium Priority
4. **Smart Reminders** - Implement notification logic
   - Calculate when falling behind pace
   - Send UserNotifications at configured time

5. **Launch at Login** - Configure SMAppService
   - Requires entitlements
   - Currently toggle exists but not functional

6. **Better UI/UX**
   - Add animations to menu bar icon when counting
   - Improve progress visualization
   - Add keyboard shortcuts

### Low Priority
7. **Export Features** (decided NO for v1, but could add later)
8. **Widget** (v2 feature)
9. **iCloud Sync** (v2 feature)

## 🏃 How to Run

### From Xcode
1. Open `RTOTracker.xcodeproj`
2. Build and run (⌘R)
3. Look for the building icon in menu bar

### Build for Distribution
```bash
cd "/Users/voha/Source/RTO Tracker/RTOTracker"
xcodebuild -project RTOTracker.xcodeproj \
           -scheme RTOTracker \
           -configuration Release \
           -archivePath ./build/RTOTracker.xcarchive \
           archive
```

## ⚙️ Configuration

### Default Settings
- **IP Prefix**: `10.78.` (needs verification!)
- **Threshold**: 30 minutes cumulative
- **Quarter Target**: 36 days
- **Quarter Type**: Calendar quarters (Jan-Mar, Apr-Jun, Jul-Sep, Oct-Dec)
- **Polling Interval**: 5 minutes

### VPN Consideration
**IMPORTANT**: Based on your input, VPN from home does NOT count as office day. However, if your VPN assigns IPs in the same 10.78.x.x range, the app will currently count it. You may need to:
- Use a different detection method, OR
- Be aware and manually override those days, OR
- Configure VPN to use a different IP range

## 📁 Project Structure
```
RTOTracker/
├── RTOTracker/
│   ├── RTOTrackerApp.swift      # Main app entry
│   ├── AppDelegate.swift        # Menu bar management
│   ├── Models/
│   │   ├── DayRecord.swift      # Daily attendance record
│   │   └── Settings.swift       # App configuration
│   ├── Services/
│   │   ├── DataManager.swift    # Data persistence
│   │   └── OfficeDetectionService.swift  # IP detection
│   ├── Views/
│   │   ├── MenuView.swift       # Main dropdown menu
│   │   └── SettingsView.swift   # Settings panel
│   └── Info.plist
└── RTOTracker.xcodeproj
```

## 🔧 Technical Details

### IP Detection
Uses `getifaddrs()` C API to read IPv4 address from `en0` interface. No permissions required.

### Data Storage
All data stored locally in UserDefaults:
- `dayRecords` - Array of DayRecord
- `appSettings` - AppSettings object

### Edge Cases Handled
✅ Cumulative 30 minutes (not continuous)
✅ Sleep/wake cycles
✅ DHCP renewal
✅ Weekend tracking
✅ Manual overrides

## 📝 Next Steps

1. **Test the IP detection** immediately
2. **Run it for a day** to verify counting works
3. **Add app icon** for better menu bar appearance
4. **Implement reminders** before end of week
5. **Test quarter boundaries** to ensure proper reset

## 🐛 Known Issues
- Settings window not showing (need to implement sheet presentation)
- Calendar detail view not implemented
- Launch at login toggle not functional yet
- No app icon (using SF Symbol placeholder)

## 📞 Support
This is an internal tool. For issues or questions, check the code or modify as needed!
