# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RTO Tracker is a macOS menu bar application that automatically tracks Return-to-Office (RTO) days by detecting office network presence via IP address. Built with SwiftUI and AppKit, it provides quarter-based tracking against a configurable target (default: 36 days per quarter).

## Build & Run Commands

### Development
```bash
# Open project
open "/Users/voha/Source/RTO Tracker/RTOTracker/RTOTracker.xcodeproj"

# Build from command line
cd "/Users/voha/Source/RTO Tracker/RTOTracker"
xcodebuild -project RTOTracker.xcodeproj -scheme RTOTracker -configuration Debug build

# Run from Xcode: ⌘R
# The app appears as a building icon in the menu bar (not in Dock)
```

### Release Build
```bash
cd "/Users/voha/Source/RTO Tracker/RTOTracker"
xcodebuild -project RTOTracker.xcodeproj \
           -scheme RTOTracker \
           -configuration Release \
           -archivePath ./build/RTOTracker.xcarchive \
           archive
```

### Bundle Configuration
- Bundle ID: `com.rtotracker.RTOTracker`
- Version: `1.0` (MARKETING_VERSION)
- Build: `1` (CURRENT_PROJECT_VERSION)

## Architecture

### App Structure Pattern

**Menu Bar Only App** (no Dock icon):
- Uses `NSApp.setActivationPolicy(.accessory)` in AppDelegate
- Main UI is an `NSPanel` that drops down from menu bar icon
- Secondary windows (Settings, Calendar) use standard `NSWindow`

**State Management**:
- `AppDelegate` owns all services and manages window lifecycle
- `DataManager` is the single source of truth (`@Published` properties)
- SwiftUI views observe `DataManager` via `@ObservedObject`

### Core Components

**AppDelegate** (AppKit):
- Menu bar management with `NSStatusItem`
- Owns `OfficeDetectionService`, `DataManager`
- Creates and manages `NSPanel` for dropdown menu
- Handles global event monitoring for click-outside-to-close

**Models**:
- `DayRecord`: Daily attendance record (date, confirmation status, check-in times, manual override flag)
- `AppSettings`: Configuration (IP prefix, quarter target, reminder settings)

**Services**:
- `OfficeDetectionService`: Polls every 5 minutes, reads en0 IPv4 via `getifaddrs()`, confirms days when IP matches prefix
- `DataManager`: Persists to UserDefaults, calculates quarter boundaries, tracking status (ahead/on track/behind)

**Views** (SwiftUI):
- `MenuView`: Dropdown panel with progress, stats, quick actions
- `SettingsView`: Configuration panel in separate `NSWindow`
- `CalendarView`: Monthly grid showing confirmed days

## Key Technical Details

### Office Detection Logic

The app detects office presence by reading the IPv4 address from the `en0` interface:
- Uses C API `getifaddrs()` to enumerate network interfaces (no permissions required)
- Checks if IP starts with configured prefix (default: `10.78.`)
- Polls every 5 minutes + immediately on wake from sleep
- When at office: calls `DataManager.confirmTodayAsOfficeDay()` which sets `isConfirmed = true` and tracks check-in times

**Important**: This is cumulative time-based, not continuous. Each check updates `lastCheckinTime`. There's no 30-minute threshold in the current implementation—any detection confirms the day.

### Quarter Tracking Algorithm

Calendar quarters: Jan-Mar (Q1), Apr-Jun (Q2), Jul-Sep (Q3), Oct-Dec (Q4)

**Tracking Status Calculation** (`DataManager.getTrackingStatus()`):
1. Count workdays elapsed from quarter start to today (excluding weekends)
2. Count total workdays in quarter
3. Calculate expected days: `workdaysElapsed * quarterTarget / totalWorkdays`
4. Compare actual confirmed days vs expected:
   - `≥ expected + 2` → Ahead
   - `≥ expected - 1` → On Track
   - Otherwise → Behind

### Data Persistence

All data stored in `UserDefaults` with auto-save debouncing (1 second):
- `dayRecords` → Array of `DayRecord` (JSON encoded)
- `appSettings` → `AppSettings` (JSON encoded)

**Manual Override**: Users can toggle any day's confirmation status via calendar view. When toggled, `isManualOverride = true` flag is set to distinguish from automatic detection.

## Important Patterns

### Window Management

**Dropdown Menu Panel**:
```swift
// Borderless NSPanel with .popUpMenu level
let panel = NSPanel(styleMask: [.nonactivatingPanel, .borderless], ...)
panel.level = .popUpMenu
// Positioned below menu bar icon, closes on click outside
```

**Settings/Calendar Windows**:
```swift
// Standard window, retained in AppDelegate
let window = NSWindow(contentViewController: hostingController)
window.styleMask = [.titled, .closable, .resizable]
self.settingsWindow = window  // Keep strong reference
```

### Notification Pattern

Services post notifications for cross-component communication:
```swift
// OfficeDetectionService → AppDelegate
NotificationCenter.default.post(name: .officeStatusChanged, object: nil)
```

AppDelegate listens and updates menu bar icon accordingly.

### SwiftUI + AppKit Bridge

Views receive AppDelegate methods as closures:
```swift
MenuView(
    dataManager: dataManager!,
    onOpenSettings: { [weak self] in self?.openSettings() }
)
```

This keeps SwiftUI views testable and decoupled from AppKit.

## Known Limitations

- **VPN Consideration**: If company VPN assigns IPs in the same prefix (10.78.x.x), VPN from home will incorrectly count as office days. User must manually override those days.
- **Single Interface**: Only checks `en0` (primary ethernet/WiFi). Does not handle multiple active interfaces.
- **No Threshold Enforcement**: Despite README mentioning "30-minute cumulative threshold," the current implementation confirms a day on any single detection. The `firstCheckinTime`/`lastCheckinTime` are tracked but not used for validation.

## Development Notes

- All services are initialized in `AppDelegate.applicationDidFinishLaunching`
- Menu bar icon updates on `@Published` changes via `updateMenuBarIcon()`
- Settings window and calendar window are single-instance (bring to front if already open)
- The app uses `@NSApplicationDelegateAdaptor` to bridge SwiftUI App lifecycle to AppKit AppDelegate
