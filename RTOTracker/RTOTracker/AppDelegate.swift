import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var menuWindow: NSPanel?
    var officeDetectionService: OfficeDetectionService?
    var dataManager: DataManager?
    var achievementManager: AchievementManager?
    var settingsWindow: NSWindow?
    var calendarWindow: NSWindow?
    var achievementsWindow: NSWindow?
    var eventMonitor: Any?
    var hotKeyEventHandler: Any?

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize services
        dataManager = DataManager()
        achievementManager = AchievementManager()
        dataManager?.achievementManager = achievementManager
        officeDetectionService = OfficeDetectionService(dataManager: dataManager!)

        // Setup activation policy based on settings
        updateActivationPolicy()

        // Setup menu bar
        setupMenuBar()

        // Setup global keyboard shortcut
        setupGlobalHotKey()

        // Start detection
        officeDetectionService?.startDetection()

        // Check achievements on launch
        achievementManager?.checkAchievements(dataManager: dataManager!)
    }

    func applicationWillTerminate(_ notification: Notification) {
        officeDetectionService?.stopDetection()

        // Auto-backup if enabled
        if dataManager?.settings.autoBackupEnabled == true,
           let dataManager = dataManager,
           let achievementManager = achievementManager {
            let backupManager = BackupManager()
            let group = DispatchGroup()

            group.enter()
            Task { @MainActor in
                do {
                    try await backupManager.createAutoBackup(
                        dataManager: dataManager,
                        achievementManager: achievementManager
                    )
                    backupManager.pruneOldAutoBackups(keepLast: 5)
                    print("✅ Auto-backup created on quit")
                } catch {
                    print("❌ Auto-backup failed: \(error)")
                }
                group.leave()
            }

            // Wait up to 2 seconds for backup to complete
            _ = group.wait(timeout: .now() + 2.0)
        }

        if let eventHandler = hotKeyEventHandler {
            NSEvent.removeMonitor(eventHandler)
        }
    }

    // MARK: - Global Hotkey Setup

    @MainActor
    private func setupGlobalHotKey() {
        // Register global hotkey: Control + Option + R
        hotKeyEventHandler = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check for Ctrl+Opt+R
            if event.modifierFlags.contains([.control, .option]) && event.charactersIgnoringModifiers == "r" {
                self?.togglePopover()
                return nil // Consume the event
            }
            return event
        }
    }

    // MARK: - Activation Policy

    @MainActor
    private func updateActivationPolicy() {
        let showInDock = dataManager?.settings.showInDock ?? false
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }

    @MainActor
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "building.2", accessibilityDescription: "RTO Tracker")
            button.action = #selector(togglePopover)
            button.target = self
        }

        updateMenuBarIcon()
    }

    @MainActor
    @objc private func togglePopover() {
        if let window = menuWindow, window.isVisible {
            closePopover()
        } else {
            showPopover()
        }
    }

    @MainActor
    private func showPopover() {
        guard let button = statusItem?.button else { return }

        let contentView = MenuView(
            dataManager: dataManager!,
            officeDetectionService: officeDetectionService!,
            achievementManager: achievementManager!,
            onOpenSettings: { [weak self] in
                self?.openSettings()
            },
            onOpenCalendar: { [weak self] in
                self?.openCalendar()
            },
            onOpenAchievements: { [weak self] in
                self?.openAchievements()
            }
        )

        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.frame.size = NSSize(width: 320, height: 400)

        // Create borderless panel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostingController
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Apply corner radius to panel itself
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = 10

        // Position below menu bar icon
        let buttonWindow = button.window!
        let buttonFrame = button.convert(button.bounds, to: nil)
        let screenFrame = buttonWindow.convertToScreen(buttonFrame)

        let panelX = screenFrame.origin.x - (panel.frame.width / 2) + (screenFrame.width / 2)
        let panelY = screenFrame.origin.y - panel.frame.height - 8

        panel.setFrameOrigin(NSPoint(x: panelX, y: panelY))
        panel.makeKeyAndOrderFront(nil)

        self.menuWindow = panel

        // Add event monitor to detect clicks outside the window
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let window = self?.menuWindow, window.isVisible {
                self?.closePopover()
            }
        }
    }

    @MainActor
    private func closePopover() {
        menuWindow?.close()
        menuWindow = nil

        // Remove event monitor
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }

    @MainActor
    func updateMenuBarIcon() {
        guard let button = statusItem?.button,
              let todayRecord = dataManager?.getTodayRecord() else { return }

        // Calculate current streak
        let currentStreak = calculateCurrentStreak()

        // Choose icon based on streak
        let iconName: String
        let iconColor: NSColor

        if currentStreak >= 3 {
            // Show flame icon for streaks
            iconName = "flame.fill"
            iconColor = streakColor(for: currentStreak)
        } else {
            // Regular building icon
            iconName = todayRecord.isConfirmed ? "building.2.fill" : "building.2"
            iconColor = .labelColor
        }

        // Create and configure the image
        let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "RTO Tracker")
        button.image = image

        // Set the tint color
        button.contentTintColor = iconColor

        // Update tooltip
        let progress = dataManager?.getCurrentQuarterProgress() ?? (0, 0)
        if currentStreak >= 3 {
            button.toolTip = "🔥 \(currentStreak)-day streak • \(progress.0)/\(progress.1) days this quarter"
        } else {
            button.toolTip = "\(progress.0)/\(progress.1) days this quarter"
        }
    }

    @MainActor
    private func calculateCurrentStreak() -> Int {
        guard let achievementManager = achievementManager,
              let dataManager = dataManager else { return 0 }

        // Use the existing streak calculation from AchievementManager
        let records = dataManager.dayRecords.sorted { $0.date > $1.date }

        var streak = 0
        var expectedDate = Calendar.current.startOfDay(for: Date())

        var recordMap: [Date: DayRecord] = [:]
        for record in records {
            recordMap[Calendar.current.startOfDay(for: record.date)] = record
        }

        while true {
            let weekday = Calendar.current.component(.weekday, from: expectedDate)

            // Skip weekends
            if weekday == 1 || weekday == 7 {
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
                continue
            }

            if let record = recordMap[expectedDate] {
                // Check day type - skip public holidays and annual leave
                if record.dayType.rawValue == "publicHoliday" || record.dayType.rawValue == "annualLeave" {
                    expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
                    continue
                }

                // Must be a workday - check if confirmed
                if record.isConfirmed {
                    streak += 1
                    expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
                } else {
                    break
                }
            } else {
                // No record for today - don't break streak if it's today
                let today = Calendar.current.startOfDay(for: Date())
                if Calendar.current.isDate(expectedDate, inSameDayAs: today) {
                    expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
                    continue
                } else {
                    break
                }
            }
        }

        return streak
    }

    @MainActor
    private func streakColor(for streak: Int) -> NSColor {
        switch streak {
        case 3...4:
            return NSColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1.0) // Yellow-Orange #FFA500
        case 5...9:
            return NSColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0) // Orange #FF6B35
        case 10...:
            return NSColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0) // Red #FF3B30
        default:
            return .labelColor
        }
    }

    @MainActor
    func openSettings() {
        print("AppDelegate.openSettings() called")

        // Activate app first (important for accessory apps)
        NSApp.activate(ignoringOtherApps: true)

        // Close the menu panel
        closePopover()

        // If settings window already exists, bring it to front
        if let window = settingsWindow, window.isVisible {
            print("Settings window already exists, bringing to front")
            window.makeKeyAndOrderFront(nil)
            return
        }

        print("Creating new settings window")

        // Create new settings window
        let settingsView = SettingsView(
            dataManager: dataManager!,
            officeDetectionService: officeDetectionService!,
            achievementManager: achievementManager!
        )
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 550, height: 550))
        window.minSize = NSSize(width: 550, height: 550)
        window.maxSize = NSSize(width: 550, height: 800)
        window.delegate = self
        window.center()

        self.settingsWindow = window

        print("Showing settings window")
        window.makeKeyAndOrderFront(nil)
    }

    @MainActor
    func openCalendar() {
        print("AppDelegate.openCalendar() called")

        // Activate app first (important for accessory apps)
        NSApp.activate(ignoringOtherApps: true)

        // Close the menu panel
        closePopover()

        // If calendar window already exists, bring it to front
        if let window = calendarWindow, window.isVisible {
            print("Calendar window already exists, bringing to front")
            window.makeKeyAndOrderFront(nil)
            return
        }

        print("Creating new calendar window")

        // Create new calendar window
        let calendarView = CalendarView(dataManager: dataManager!)
        let hostingController = NSHostingController(rootView: calendarView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "RTO Calendar"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 700, height: 600))
        window.minSize = NSSize(width: 650, height: 550)
        window.delegate = self
        window.center()

        self.calendarWindow = window

        print("Showing calendar window")
        window.makeKeyAndOrderFront(nil)
    }

    @MainActor
    func openAchievements() {
        print("AppDelegate.openAchievements() called")

        // Activate app first (important for accessory apps)
        NSApp.activate(ignoringOtherApps: true)

        // Close the menu panel
        closePopover()

        // If achievements window already exists, bring it to front
        if let window = achievementsWindow, window.isVisible {
            print("Achievements window already exists, bringing to front")
            window.makeKeyAndOrderFront(nil)
            return
        }

        print("Creating new achievements window")

        // Create new achievements window
        let achievementsView = AchievementsView(achievementManager: achievementManager!)
        let hostingController = NSHostingController(rootView: achievementsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Achievements"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 600, height: 500))
        window.minSize = NSSize(width: 600, height: 500)
        window.delegate = self
        window.center()

        self.achievementsWindow = window

        print("Showing achievements window")
        window.makeKeyAndOrderFront(nil)
    }

}

extension AppDelegate: NSWindowDelegate {
    @MainActor
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === settingsWindow {
            settingsWindow = nil
            // Update activation policy when settings window closes
            updateActivationPolicy()
        } else if notification.object as? NSWindow === calendarWindow {
            calendarWindow = nil
        } else if notification.object as? NSWindow === achievementsWindow {
            achievementsWindow = nil
        }
    }
}
