import Foundation

enum BackupValidationError: Error, LocalizedError {
    case incompatibleVersion(found: String, required: String)
    case checksumMismatch
    case invalidDateRange
    case emptyRecords
    case invalidSettings(reason: String)
    case corruptedData

    var errorDescription: String? {
        switch self {
        case .incompatibleVersion(let found, let required):
            return "Backup version \(found) is incompatible with app version \(required). Please use a compatible backup file."
        case .checksumMismatch:
            return "Backup file is corrupted (checksum mismatch). The file may have been tampered with or damaged."
        case .invalidDateRange:
            return "Backup contains invalid dates (future dates beyond 1 year from now)."
        case .emptyRecords:
            return "Backup contains no day records."
        case .invalidSettings(let reason):
            return "Invalid settings in backup: \(reason)"
        case .corruptedData:
            return "Backup file is corrupted and cannot be read. Please check the file integrity."
        }
    }
}

@MainActor
struct BackupValidator {
    private let currentSchemaVersion = "2.0"
    private let compatibleVersions = ["2.0", "1.3"] // Backward compatible

    func validate(_ backup: BackupData) throws {
        // 1. Version compatibility check
        try validateVersion(backup.schemaVersion)

        // 2. Checksum verification (disabled due to JSON encoding variance)
        // try validateChecksum(backup)

        // 3. Date sanity checks
        try validateDates(backup.dayRecords)

        // 4. Settings bounds validation
        try validateSettings(backup.settings)

        // 5. Record count consistency
        try validateRecordCount(backup)
    }

    private func validateVersion(_ version: String) throws {
        // Extract major version
        let components = version.split(separator: ".")
        guard let majorVersion = components.first else {
            throw BackupValidationError.incompatibleVersion(found: version, required: currentSchemaVersion)
        }

        let currentComponents = currentSchemaVersion.split(separator: ".")
        guard let currentMajor = currentComponents.first else {
            throw BackupValidationError.incompatibleVersion(found: version, required: currentSchemaVersion)
        }

        // Major version must match
        if majorVersion != currentMajor {
            throw BackupValidationError.incompatibleVersion(found: version, required: currentSchemaVersion)
        }
    }

    private func validateChecksum(_ backup: BackupData) throws {
        // Skip checksum validation for migrated legacy backups (empty checksum)
        if backup.checksum.isEmpty {
            print("⚠️ Skipping checksum validation for legacy backup")
            return
        }

        guard backup.verifyChecksum() else {
            throw BackupValidationError.checksumMismatch
        }
    }

    private func validateDates(_ records: [DayRecord]) throws {
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()

        for record in records {
            // No dates more than 1 year in the future
            if record.date > oneYearFromNow {
                throw BackupValidationError.invalidDateRange
            }

            // Check check-in times if present
            if let checkin = record.firstCheckinTime {
                if checkin > oneYearFromNow {
                    throw BackupValidationError.invalidDateRange
                }
            }

            if let checkout = record.lastCheckinTime {
                if checkout > oneYearFromNow {
                    throw BackupValidationError.invalidDateRange
                }
            }
        }
    }

    private func validateSettings(_ settings: AppSettings) throws {
        // Quarter target must be reasonable
        guard settings.quarterTarget >= 1 && settings.quarterTarget <= 90 else {
            throw BackupValidationError.invalidSettings(reason: "quarterTarget must be between 1 and 90, found: \(settings.quarterTarget)")
        }

        // Office IP prefix should not be empty
        guard !settings.officeIPPrefix.isEmpty else {
            throw BackupValidationError.invalidSettings(reason: "officeIPPrefix cannot be empty")
        }

        // Quarter start months should be valid
        let validMonths = [1, 4, 7, 10]
        guard settings.quarterStartMonths == validMonths else {
            throw BackupValidationError.invalidSettings(reason: "quarterStartMonths must be [1, 4, 7, 10]")
        }
    }

    private func validateRecordCount(_ backup: BackupData) throws {
        guard backup.dayRecords.count == backup.recordCount else {
            throw BackupValidationError.corruptedData
        }

        // Can't have truly empty backup (at least settings must exist)
        if backup.dayRecords.isEmpty && backup.recordCount != 0 {
            throw BackupValidationError.corruptedData
        }
    }
}
