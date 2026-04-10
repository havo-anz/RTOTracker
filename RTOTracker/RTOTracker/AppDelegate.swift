import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var menuWindow: NSPanel?
    var officeDetectionService: OfficeDetectionService?
    var dataManager: DataManager?
    var settingsWindow: NSWindow?
    var calendarWindow: NSWindow?
    var updateChecker: UpdateChecker?
    var eventMonitor: Any?

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon for menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // Initialize services
        dataManager = DataManager()
        officeDetectionService = OfficeDetectionService(dataManager: dataManager!)
        updateChecker = UpdateChecker()

        // Setup menu bar
        setupMenuBar()

        // Start detection
        officeDetectionService?.startDetection()

        // Check for updates in background (silent)
        updateChecker?.checkForUpdatesInBackground()
    }

    func applicationWillTerminate(_ notification: Notification) {
        officeDetectionService?.stopDetection()
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

        // Only enable update checking if Sparkle is properly configured
        let updateCheckClosure: (() -> Void)? = updateChecker?.isAvailable == true ? { [weak self] in
            self?.checkForUpdates()
        } : nil

        let contentView = MenuView(
            dataManager: dataManager!,
            officeDetectionService: officeDetectionService!,
            onOpenSettings: { [weak self] in
                self?.openSettings()
            },
            onOpenCalendar: { [weak self] in
                self?.openCalendar()
            },
            onCheckForUpdates: updateCheckClosure
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

        // Use filled icon if today is confirmed, outline otherwise
        let iconName = todayRecord.isConfirmed ? "building.2.fill" : "building.2"
        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "RTO Tracker")

        // Update tooltip
        let progress = dataManager?.getCurrentQuarterProgress() ?? (0, 0)
        button.toolTip = "\(progress.0)/\(progress.1) days this quarter"
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
            officeDetectionService: officeDetectionService!
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
    func checkForUpdates() {
        print("AppDelegate.checkForUpdates() called")

        // Close the menu panel first
        closePopover()

        // Activate app to bring update dialog to front
        NSApp.activate(ignoringOtherApps: true)

        updateChecker?.checkForUpdates()
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === settingsWindow {
            settingsWindow = nil
        } else if notification.object as? NSWindow === calendarWindow {
            calendarWindow = nil
        }
    }
}
