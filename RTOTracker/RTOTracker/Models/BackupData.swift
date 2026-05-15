import Foundation
import CryptoKit

struct BackupData: Codable {
    // Core data
    let dayRecords: [DayRecord]
    let settings: AppSettings
    let achievements: [Achievement]

    // Achievement metadata (CRITICAL: missing in current implementation)
    let quartersCompleted: Int
    let previousTrackingStatus: String

    // Metadata
    let schemaVersion: String
    let exportDate: Date
    let appVersion: String
    let recordCount: Int
    let checksum: String

    // Computed properties
    var dateRange: String {
        guard let first = dayRecords.sorted(by: { $0.date < $1.date }).first,
              let last = dayRecords.sorted(by: { $0.date < $1.date }).last else {
            return "No records"
        }
        return "\(first.date.formatted(date: .abbreviated, time: .omitted)) - \(last.date.formatted(date: .abbreviated, time: .omitted))"
    }

    // Custom init for creating backups
    init(
        dayRecords: [DayRecord],
        settings: AppSettings,
        achievements: [Achievement],
        quartersCompleted: Int,
        previousTrackingStatus: String,
        appVersion: String
    ) {
        self.dayRecords = dayRecords
        self.settings = settings
        self.achievements = achievements
        self.quartersCompleted = quartersCompleted
        self.previousTrackingStatus = previousTrackingStatus
        self.schemaVersion = "2.0"
        self.exportDate = Date()
        self.appVersion = appVersion
        self.recordCount = dayRecords.count

        // Calculate checksum
        self.checksum = Self.calculateChecksum(
            dayRecords: dayRecords,
            settings: settings,
            achievements: achievements
        )
    }

    // Checksum calculation
    static func calculateChecksum(
        dayRecords: [DayRecord],
        settings: AppSettings,
        achievements: [Achievement]
    ) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        var checksumData = Data()

        if let recordsData = try? encoder.encode(dayRecords) {
            checksumData.append(recordsData)
        }
        if let settingsData = try? encoder.encode(settings) {
            checksumData.append(settingsData)
        }
        if let achievementsData = try? encoder.encode(achievements) {
            checksumData.append(achievementsData)
        }

        let hash = SHA256.hash(data: checksumData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // Verify checksum
    func verifyChecksum() -> Bool {
        let calculated = Self.calculateChecksum(
            dayRecords: dayRecords,
            settings: settings,
            achievements: achievements
        )
        return calculated == checksum
    }
}

// Achievement metadata structure
struct AchievementMetadata: Codable {
    let quartersCompleted: Int
    let previousTrackingStatus: String
}
