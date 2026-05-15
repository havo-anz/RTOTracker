import SwiftUI
import UniformTypeIdentifiers

struct RestoreDialogView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var achievementManager: AchievementManager
    var onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedFileURL: URL?
    @State private var backupPreview: BackupData?
    @State private var importMode: ImportMode = .merge
    @State private var importSettings: Bool = false
    @State private var statusMessage: String = ""
    @State private var isImporting: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Restore from Backup")
                .font(.title2)
                .fontWeight(.semibold)

            if let preview = backupPreview {
                // Preview Section
                previewSection(preview)

                Divider()

                // Import Mode Selection
                importModeSection

                // Warning for Full Restore
                if importMode == .fullRestore {
                    warningSection
                }

                Divider()

                // Action Buttons
                actionButtons
            } else {
                // File Selection
                fileSelectionSection
            }

            // Status Message
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(statusMessage.contains("✅") ? .green : .red)
                    .padding(.horizontal)
            }
        }
        .padding(30)
        .frame(width: 600, height: backupPreview != nil ? 550 : 300)
    }

    // MARK: - View Components

    private var fileSelectionSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.zipper")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Select a backup file to restore")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Choose Backup File") {
                selectBackupFile()
            }
            .buttonStyle(.borderedProminent)

            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
    }

    private func previewSection(_ preview: BackupData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Backup Preview")
                .font(.headline)

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    previewRow(label: "Export Date", value: preview.exportDate.formatted(date: .long, time: .shortened))
                    previewRow(label: "App Version", value: preview.appVersion)
                    previewRow(label: "Schema Version", value: preview.schemaVersion)
                    Divider()
                    previewRow(label: "Day Records", value: "\(preview.dayRecords.count) days")
                    previewRow(label: "Date Range", value: preview.dateRange)
                    previewRow(label: "Achievements", value: "\(preview.achievements.filter { $0.isUnlocked }.count) unlocked")
                    previewRow(label: "Quarters Completed", value: "\(preview.quartersCompleted)")
                }
                .padding(8)
            }
        }
    }

    private func previewRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .trailing)
            Text(value)
                .font(.caption)
            Spacer()
        }
    }

    private var importModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import Mode")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                importModeOption(
                    mode: .fullRestore,
                    title: "Full Restore",
                    description: "Replace ALL existing data with backup (for disaster recovery)"
                )

                importModeOption(
                    mode: .merge,
                    title: "Merge",
                    description: "Add missing records, preserve existing data"
                )

                if importMode == .merge {
                    Toggle("Also import settings", isOn: $importSettings)
                        .font(.caption)
                        .padding(.leading, 30)
                }

                importModeOption(
                    mode: .settingsOnly,
                    title: "Settings Only",
                    description: "Import only app settings and preferences"
                )
            }
        }
    }

    private func importModeOption(mode: ImportMode, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: importMode == mode ? "largecircle.fill.circle" : "circle")
                .foregroundColor(importMode == mode ? .accentColor : .secondary)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            importMode = mode
        }
    }

    private var warningSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 4) {
                Text("Warning: This will replace ALL existing data")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("A safety backup will be created automatically before restore.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape)
            .disabled(isImporting)

            Button("Start Restore") {
                performRestore()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return)
            .disabled(isImporting)
        }
    }

    // MARK: - Actions

    private func selectBackupFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Select a backup file to restore"
        openPanel.prompt = "Select"

        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                loadBackupPreview(from: url)
            }
        }
    }

    private func loadBackupPreview(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let backupManager = BackupManager()
            let backup = try backupManager.loadBackup(from: data)

            // Validate
            let validator = BackupValidator()
            try validator.validate(backup)

            self.selectedFileURL = url
            self.backupPreview = backup
            self.statusMessage = ""
        } catch {
            statusMessage = "❌ Invalid backup file: \(error.localizedDescription)"
        }
    }

    private func performRestore() {
        guard let url = selectedFileURL else { return }

        isImporting = true
        statusMessage = "⏳ Restoring backup..."

        Task { @MainActor in
            do {
                let data = try Data(contentsOf: url)

                // Determine actual import mode
                var actualMode = importMode
                if importMode == .merge && !importSettings {
                    // Will use custom merge without settings
                    actualMode = .merge
                }

                try dataManager.importCompleteData(
                    from: data,
                    mode: actualMode,
                    achievementManager: achievementManager,
                    importSettings: importSettings
                )

                statusMessage = "✅ Restore completed successfully!"

                // Notify parent and dismiss after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    let message = "✅ Restored from \(url.lastPathComponent)"
                    onComplete(message)
                    dismiss()
                }
            } catch {
                statusMessage = "❌ Restore failed: \(error.localizedDescription)"
                isImporting = false
            }
        }
    }
}

// Preview
#Preview {
    RestoreDialogView(
        dataManager: DataManager(),
        achievementManager: AchievementManager(),
        onComplete: { _ in }
    )
}
