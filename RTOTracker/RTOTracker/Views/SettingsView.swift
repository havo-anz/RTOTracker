import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var officeDetectionService: OfficeDetectionService
    @ObservedObject var achievementManager: AchievementManager
    @Environment(\.dismiss) private var dismiss

    @State private var testResult: String = ""
    @State private var showResetConfirmation = false
    @State private var exportMessage: String = ""
    @State private var showBulkAddSheet = false
    @State private var bulkAddDates: String = ""
    @State private var bulkAddMessage: String = ""
    @State private var showRestoreDialog = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    NSApplication.shared.keyWindow?.close()
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Office Detection Section
                    settingsSection(title: "Office Detection") {
                        VStack(alignment: .leading, spacing: 12) {
                            settingRow(label: "IP Prefix:") {
                                TextField("e.g., 10.78.", text: $dataManager.settings.officeIPPrefix)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 200)
                            }

                            settingRow(label: "Current IP:") {
                                Text(officeDetectionService.currentIP.isEmpty ? "Not detected" : officeDetectionService.currentIP)
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .monospaced))
                            }

                            HStack {
                                Button("Test Connection") {
                                    testConnection()
                                }

                                if testResult.isEmpty == false {
                                    Text(testResult)
                                        .font(.caption)
                                        .foregroundColor(testResult.contains("✓") ? .green : .red)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }

                    Divider()

                    // Quarter Settings Section
                    settingsSection(title: "Quarter Settings") {
                        VStack(alignment: .leading, spacing: 8) {
                            settingRow(label: "Target days:") {
                                Stepper(value: $dataManager.settings.quarterTarget, in: 1...90) {
                                    Text("\(dataManager.settings.quarterTarget) days")
                                        .frame(width: 60, alignment: .trailing)
                                }
                            }

                            Text("Using calendar quarters (Jan-Mar, Apr-Jun, Jul-Sep, Oct-Dec)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 140)
                        }
                    }

                    Divider()

                    // Reminders Section
                    settingsSection(title: "Reminders") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Enable reminders", isOn: $dataManager.settings.reminderEnabled)
                                .toggleStyle(.switch)

                            if dataManager.settings.reminderEnabled {
                                settingRow(label: "Reminder time:") {
                                    DatePicker(
                                        "",
                                        selection: $dataManager.settings.reminderTime,
                                        displayedComponents: .hourAndMinute
                                    )
                                    .labelsHidden()
                                }
                            }

                            Text("Get notified when falling behind target")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Appearance Section
                    settingsSection(title: "Appearance") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Show in Dock", isOn: $dataManager.settings.showInDock)
                                .toggleStyle(.switch)

                            Text("When enabled, app appears in Dock. When disabled, app is menu bar only.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Keyboard Shortcuts
                    settingsSection(title: "Keyboard Shortcuts") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Show Menu:")
                                    .frame(width: 120, alignment: .trailing)
                                Text("⌃⌥R")
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                                Text("(Control + Option + R)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }

                            Text("Use this shortcut anytime to show the menu, even when the menu bar is hidden")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 140)
                        }
                    }

                    Divider()

                    // Achievements Section (for testing)
                    settingsSection(title: "Achievements") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Unlocked: \(achievementManager.unlockedCount) / \(achievementManager.totalCount)")
                                        .font(.subheadline)
                                    Text("Achievements are dynamically updated based on your progress")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button("Reset All") {
                                    showResetConfirmation = true
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                    .confirmationDialog(
                        "Reset all achievements?",
                        isPresented: $showResetConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Reset", role: .destructive) {
                            achievementManager.resetAllAchievements()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will remove all unlocked achievements. They will be re-earned when you meet the criteria again.")
                    }

                    Divider()

                    // Data Management Section
                    settingsSection(title: "Data Management") {
                        VStack(alignment: .leading, spacing: 12) {
                            // Status
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(dataManager.dayRecords.count) day records")
                                        .font(.subheadline)
                                    Text("\(achievementManager.unlockedCount) achievements unlocked")
                                        .font(.subheadline)
                                }
                                Spacer()
                            }

                            Divider()

                            // Manual backup/restore
                            HStack(spacing: 12) {
                                Button("Add Days") {
                                    showBulkAddSheet = true
                                }

                                Button("Create Backup") {
                                    exportCompleteData()
                                }

                                Button("Restore Backup") {
                                    showRestoreDialog = true
                                }
                            }

                            Divider()

                            // Auto-backup settings
                            Toggle("Auto-backup on quit", isOn: $dataManager.settings.autoBackupEnabled)

                            if dataManager.settings.autoBackupEnabled {
                                HStack {
                                    Text("Location:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("~/Library/Application Support/RTOTracker/AutoBackups/")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button("Show") {
                                        openAutoBackupFolder()
                                    }
                                    .font(.caption)
                                }
                            }

                            if !exportMessage.isEmpty {
                                Text(exportMessage)
                                    .font(.caption)
                                    .foregroundColor(exportMessage.contains("✅") ? .green : .red)
                            }
                        }
                    }
                    .sheet(isPresented: $showBulkAddSheet) {
                        bulkAddView
                    }
                    .sheet(isPresented: $showRestoreDialog) {
                        RestoreDialogView(
                            dataManager: dataManager,
                            achievementManager: achievementManager,
                            onComplete: { message in
                                exportMessage = message
                            }
                        )
                    }

                    Divider()

                    // System Section
                    settingsSection(title: "System") {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Launch at login", isOn: $dataManager.settings.launchAtLogin)
                                .toggleStyle(.switch)
                                .onChange(of: dataManager.settings.launchAtLogin) { _, newValue in
                                    configureLaunchAtLogin(newValue)
                                }
                        }
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content()
        }
    }

    @ViewBuilder
    private func settingRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .frame(width: 120, alignment: .trailing)
                .foregroundColor(.primary)

            content()

            Spacer()
        }
    }

    private func testConnection() {
        let result = officeDetectionService.testCurrentConnection()
        if result.isOffice {
            testResult = "✓ Connected to office network\nIP: \(result.ip)"
        } else if result.ip.isEmpty {
            testResult = "✗ No network connection detected"
        } else {
            testResult = "✗ Not on office network\nIP: \(result.ip)"
        }
    }

    private func configureLaunchAtLogin(_ enabled: Bool) {
        // TODO: Implement SMAppService registration
        // This requires proper entitlements and app structure
    }

    private func exportCompleteData() {
        do {
            let data = try dataManager.exportCompleteData(achievementManager: achievementManager)

            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HHmm"
            savePanel.nameFieldStringValue = "RTO_Backup_\(formatter.string(from: Date())).json"
            savePanel.message = "Export your complete RTO tracking data"

            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try data.write(to: url)
                        self.exportMessage = "✅ Complete backup saved to \(url.lastPathComponent)"
                    } catch {
                        self.exportMessage = "❌ Failed to write file: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            exportMessage = "❌ Export failed: \(error.localizedDescription)"
        }
    }

    private func openAutoBackupFolder() {
        let backupManager = BackupManager()
        backupManager.openAutoBackupFolder()
    }

    private var bulkAddView: some View {
        VStack(spacing: 20) {
            Text("Add Historical Office Days")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Enter dates (one per line) in format: YYYY-MM-DD")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Example:\n2026-04-15\n2026-04-16\n2026-04-22")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)

            TextEditor(text: $bulkAddDates)
                .font(.system(.body, design: .monospaced))
                .frame(height: 200)
                .border(Color.secondary.opacity(0.3))

            if !bulkAddMessage.isEmpty {
                Text(bulkAddMessage)
                    .font(.caption)
                    .foregroundColor(bulkAddMessage.contains("✅") ? .green : .red)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    showBulkAddSheet = false
                    bulkAddDates = ""
                    bulkAddMessage = ""
                }
                .keyboardShortcut(.escape)

                Button("Add Days") {
                    addBulkDays()
                }
                .keyboardShortcut(.return)
            }
        }
        .padding(30)
        .frame(width: 500, height: 450)
    }

    private func addBulkDays() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let lines = bulkAddDates.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var dates: [Date] = []
        var errors: [String] = []

        for line in lines {
            if let date = dateFormatter.date(from: line) {
                dates.append(date)
            } else {
                errors.append(line)
            }
        }

        if !errors.isEmpty {
            bulkAddMessage = "❌ Invalid dates: \(errors.joined(separator: ", "))"
            return
        }

        if dates.isEmpty {
            bulkAddMessage = "❌ No valid dates entered"
            return
        }

        dataManager.addMultipleDays(dates)
        bulkAddMessage = "✅ Added \(dates.count) office days"

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showBulkAddSheet = false
            bulkAddDates = ""
            bulkAddMessage = ""
            exportMessage = "✅ Added \(dates.count) historical days"
        }
    }
}
