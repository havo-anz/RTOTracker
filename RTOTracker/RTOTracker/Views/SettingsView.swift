import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var officeDetectionService: OfficeDetectionService
    @Environment(\.dismiss) private var dismiss

    @State private var testResult: String = ""

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
}
