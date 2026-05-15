import Foundation
import AppKit

enum ImportMode {
    case fullRestore      // Replace all data (for disaster recovery)
    case merge            // Add missing records, preserve existing
    case settingsOnly     // Import only settings/preferences
}

enum BackupError: Error, LocalizedError {
    case creationFailed(String)
    case saveFailed(String)
    case loadFailed(String)
    case autoBackupFolderCreationFailed

    var errorDescription: String? {
        switch self {
        case .creationFailed(let reason):
            return "Failed to create backup: \(reason)"
        case .saveFailed(let reason):
            return "Failed to save backup: \(reason)"
        case .loadFailed(let reason):
            return "Failed to load backup: \(reason)"
        case .autoBackupFolderCreationFailed:
            return "Failed to create auto-backup folder"
        }
    }
}

@MainActor
final class BackupManager {
    private let validator = BackupValidator()
    private let appVersion = "1.3"

    // MARK: - Auto-Backup Folder

    private var autoBackupFolder: URL {
        get throws {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let folder = appSupport.appendingPathComponent("RTOTracker/AutoBackups", isDirectory: true)

            if !FileManager.default.fileExists(atPath: folder.path) {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            }

            return folder
        }
    }

    // MARK: - Create Backup

    func createBackup(
        dayRecords: [DayRecord],
        settings: AppSettings,
        achievements: [Achievement],
        achievementMetadata: AchievementMetadata
    ) throws -> BackupData {
        let backup = BackupData(
            dayRecords: dayRecords,
            settings: settings,
            achievements: achievements,
            quartersCompleted: achievementMetadata.quartersCompleted,
            previousTrackingStatus: achievementMetadata.previousTrackingStatus,
            appVersion: appVersion
        )

        // Validate before returning
        try validator.validate(backup)

        return backup
    }

    // MARK: - Save/Load Backup

    func saveBackup(_ backup: BackupData, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(backup)
            try data.write(to: url, options: [.atomic])
            print("📤 Backup saved to: \(url.path)")
        } catch {
            throw BackupError.saveFailed(error.localizedDescription)
        }
    }

    func saveToData(_ backup: BackupData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            return try encoder.encode(backup)
        } catch {
            throw BackupError.saveFailed(error.localizedDescription)
        }
    }

    func loadBackup(from url: URL) throws -> BackupData {
        do {
            let data = try Data(contentsOf: url)
            return try loadBackup(from: data)
        } catch {
            throw BackupError.loadFailed(error.localizedDescription)
        }
    }

    func loadBackup(from data: Data) throws -> BackupData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Try new format first (v2.0)
        if let backup = try? decoder.decode(BackupData.self, from: data) {
            return backup
        }

        // Fall back to legacy ExportData format (v1.3)
        if let legacy = try? decoder.decode(ExportData.self, from: data) {
            print("⚠️ Migrating legacy backup format (v1.3 → v2.0)")
            return migrateFromLegacy(legacy)
        }

        throw BackupError.loadFailed("Unsupported backup format")
    }

    // MARK: - Legacy Migration

    private func migrateFromLegacy(_ legacy: ExportData) -> BackupData {
        BackupData(
            dayRecords: legacy.dayRecords,
            settings: legacy.settings,
            achievements: [],  // Not in legacy format
            quartersCompleted: 0,  // Reset
            previousTrackingStatus: "",  // Reset
            appVersion: legacy.appVersion
        )
    }

    // MARK: - Restore Backup

    func restoreBackup(
        _ backup: BackupData,
        mode: ImportMode,
        dataManager: DataManager,
        achievementManager: AchievementManager
    ) throws {
        // Validate first
        try validator.validate(backup)

        switch mode {
        case .fullRestore:
            try fullRestore(backup, dataManager: dataManager, achievementManager: achievementManager)

        case .merge:
            try mergeRestore(backup, dataManager: dataManager, achievementManager: achievementManager)

        case .settingsOnly:
            dataManager.settings = backup.settings
            print("✅ Settings restored")
        }
    }

    private func fullRestore(
        _ backup: BackupData,
        dataManager: DataManager,
        achievementManager: AchievementManager
    ) throws {
        // Clear all existing data
        dataManager.dayRecords = []
        achievementManager.achievements = []

        // Restore everything
        dataManager.dayRecords = backup.dayRecords.sorted { $0.date < $1.date }
        dataManager.settings = backup.settings
        achievementManager.importAchievements(backup.achievements)

        let metadata = AchievementMetadata(
            quartersCompleted: backup.quartersCompleted,
            previousTrackingStatus: backup.previousTrackingStatus
        )
        achievementManager.importMetadata(metadata)

        print("✅ Full restore complete: \(backup.dayRecords.count) records, \(backup.achievements.count) achievements")
    }

    private func mergeRestore(
        _ backup: BackupData,
        dataManager: DataManager,
        achievementManager: AchievementManager
    ) throws {
        // Build map of existing records
        var recordMap: [Date: DayRecord] = [:]
        for record in dataManager.dayRecords {
            let key = Calendar.current.startOfDay(for: record.date)
            recordMap[key] = record
        }

        // Add new records from backup (don't overwrite existing)
        var addedCount = 0
        for record in backup.dayRecords {
            let key = Calendar.current.startOfDay(for: record.date)
            if recordMap[key] == nil {
                recordMap[key] = record
                addedCount += 1
            }
        }

        dataManager.dayRecords = Array(recordMap.values).sorted { $0.date < $1.date }

        // Merge achievements (unlock any that are unlocked in backup)
        for backupAchievement in backup.achievements where backupAchievement.isUnlocked {
            if let index = achievementManager.achievements.firstIndex(where: { $0.id == backupAchievement.id }) {
                if !achievementManager.achievements[index].isUnlocked {
                    achievementManager.achievements[index].isUnlocked = true
                    achievementManager.achievements[index].unlockedDate = backupAchievement.unlockedDate
                }
            }
        }

        print("✅ Merge complete: Added \(addedCount) new records")
    }

    // MARK: - Safety Backup

    func createSafetyBackup(
        dataManager: DataManager,
        achievementManager: AchievementManager
    ) throws -> URL {
        let metadata = achievementManager.exportMetadata()
        let backup = try createBackup(
            dayRecords: dataManager.dayRecords,
            settings: dataManager.settings,
            achievements: achievementManager.achievements,
            achievementMetadata: metadata
        )

        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())
        let safetyURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Safety_Before_Import_\(timestamp).json")

        try saveBackup(backup, to: safetyURL)
        print("🛡️ Safety backup created: \(safetyURL.path)")

        return safetyURL
    }

    // MARK: - Auto-Backup

    func createAutoBackup(
        dataManager: DataManager,
        achievementManager: AchievementManager
    ) async throws {
        let folder = try autoBackupFolder

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        let timestamp = formatter.string(from: Date())

        let filename = "AutoBackup_\(timestamp).json"
        let url = folder.appendingPathComponent(filename)

        let metadata = achievementManager.exportMetadata()
        let backup = try createBackup(
            dayRecords: dataManager.dayRecords,
            settings: dataManager.settings,
            achievements: achievementManager.achievements,
            achievementMetadata: metadata
        )

        try saveBackup(backup, to: url)
        print("🔄 Auto-backup created: \(filename)")
    }

    func pruneOldAutoBackups(keepLast: Int) {
        do {
            let folder = try autoBackupFolder
            let files = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            // Filter to only JSON backups
            let backups = files.filter { $0.pathExtension == "json" && $0.lastPathComponent.hasPrefix("AutoBackup_") }

            // Sort by creation date (newest first)
            let sortedBackups = backups.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }

            // Delete old backups
            for (index, backup) in sortedBackups.enumerated() {
                if index >= keepLast {
                    try FileManager.default.removeItem(at: backup)
                    print("🗑️ Removed old backup: \(backup.lastPathComponent)")
                }
            }
        } catch {
            print("⚠️ Failed to prune old backups: \(error)")
        }
    }

    func openAutoBackupFolder() {
        do {
            let folder = try autoBackupFolder
            NSWorkspace.shared.open(folder)
        } catch {
            print("❌ Failed to open auto-backup folder: \(error)")
        }
    }
}
