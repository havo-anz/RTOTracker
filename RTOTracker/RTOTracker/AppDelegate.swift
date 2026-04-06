import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var officeDetectionService: OfficeDetectionService?
    var dataManager: DataManager?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon for menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // Initialize services
        dataManager = DataManager()
        officeDetectionService = OfficeDetectionService(dataManager: dataManager!)

        // Setup menu bar
        setupMenuBar()

        // Start detection
        officeDetectionService?.startDetection()
    }

    func applicationWillTerminate(_ notification: Notification) {
        officeDetectionService?.stopDetection()
    }

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
        if let popover = popover, popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    @MainActor
    private func showPopover() {
        guard let button = statusItem?.button else { return }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuView(
                dataManager: dataManager!,
                officeDetectionService: officeDetectionService!,
                onOpenSettings: { [weak self] in
                    self?.openSettings()
                }
            )
        )

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        self.popover = popover
    }

    private func closePopover() {
        popover?.close()
        popover = nil
    }

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

        // If settings window already exists, bring it to front
        if let window = settingsWindow, window.isVisible {
            print("Settings window already exists, bringing to front")
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
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
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === settingsWindow {
            settingsWindow = nil
        }
    }
}
