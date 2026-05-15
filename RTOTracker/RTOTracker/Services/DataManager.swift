import Foundation
import Combine

@MainActor
final class DataManager: ObservableObject {
    @Published var dayRecords: [DayRecord] = []
    @Published var settings: AppSettings

    private var userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()
    weak var achievementManager: AchievementManager?

    private var recordsKey: String { "dayRecords" }
    private var settingsKey: String { "appSettings" }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Load settings
        if let data = userDefaults.data(forKey: "appSettings"),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }

        // Load records
        loadRecords()

        // Auto-save on changes
        $dayRecords
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveRecords()
            }
            .store(in: &cancellables)

        $settings
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.saveSettings(settings)
            }
            .store(in: &cancellables)
    }

    // MARK: - Records Management

    func getTodayRecord() -> DayRecord {
        let today = Calendar.current.startOfDay(for: Date())
        if let existing = dayRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return existing
        }
        return DayRecord(date: today)
    }

    func updateTodayRecord(_ record: DayRecord) {
        let today = Calendar.current.startOfDay(for: Date())
        if let index = dayRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            dayRecords[index] = record
        } else {
            dayRecords.append(record)
        }
    }

    func confirmTodayAsOfficeDay(at time: Date = Date()) {
        var record = getTodayRecord()
        let wasConfirmed = record.isConfirmed

        if record.firstCheckinTime == nil {
            record.firstCheckinTime = time
        }
        record.lastCheckinTime = time
        record.isConfirmed = true

        updateTodayRecord(record)

        // Only check achievements if status changed from unconfirmed to confirmed
        if wasConfirmed == false {
            achievementManager?.checkAchievements(dataManager: self)
        }
    }

    func getRecordsForQuarter(_ date: Date = Date()) -> [DayRecord] {
        let (startDate, endDate) = getQuarterDates(for: date)
        return dayRecords.filter { record in
            record.date >= startDate && record.date <= endDate
        }
    }

    func getCurrentQuarterProgress() -> (confirmed: Int, target: Int) {
        let confirmedDays = getRecordsForQuarter().filter { $0.isConfirmed }.count
        return (confirmedDays, settings.quarterTarget)
    }

    func getTrackingStatus() -> (status: TrackingStatus, expectedDays: Int, actualDays: Int) {
        let (startDate, endDate) = getQuarterDates(for: Date())
        let today = Calendar.current.startOfDay(for: Date())

        // Count workdays elapsed from quarter start to today
        var workdaysElapsed = 0
        var currentDate = startDate

        while currentDate <= today && currentDate <= endDate {
            let weekday = Calendar.current.component(.weekday, from: currentDate)
            // weekday: 1 = Sunday, 7 = Saturday
            if weekday != 1 && weekday != 7 {
                workdaysElapsed += 1
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Count total workdays in quarter
        var totalWorkdays = 0
        currentDate = startDate

        while currentDate <= endDate {
            let weekday = Calendar.current.component(.weekday, from: currentDate)
            if weekday != 1 && weekday != 7 {
                totalWorkdays += 1
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Calculate expected days by now
        let expectedDays = totalWorkdays > 0 ? Int(round(Double(workdaysElapsed) * Double(settings.quarterTarget) / Double(totalWorkdays))) : 0

        // Get actual confirmed days
        let actualDays = getRecordsForQuarter().filter { $0.isConfirmed }.count

        // Determine status
        let status: TrackingStatus
        if actualDays >= expectedDays + 2 {
            status = .ahead
        } else if actualDays >= expectedDays {
            status = .onTrack
        } else {
            status = .behind
        }

        return (status, expectedDays, actualDays)
    }

    enum TrackingStatus {
        case ahead
        case onTrack
        case behind

        var displayText: String {
            switch self {
            case .ahead: return "Ahead of Schedule"
            case .onTrack: return "On Track"
            case .behind: return "Behind Schedule"
            }
        }

        var color: String {
            switch self {
            case .ahead: return "green"
            case .onTrack: return "blue"
            case .behind: return "red"
            }
        }

        var icon: String {
            switch self {
            case .ahead: return "arrow.up.circle.fill"
            case .onTrack: return "checkmark.circle.fill"
            case .behind: return "exclamationmark.triangle.fill"
            }
        }
    }

    // MARK: - Quarter Calculations

    func getQuarterDates(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)

        // Find which quarter we're in
        let quarterStartMonth: Int
        if month >= 1 && month <= 3 {
            quarterStartMonth = 1
        } else if month >= 4 && month <= 6 {
            quarterStartMonth = 4
        } else if month >= 7 && month <= 9 {
            quarterStartMonth = 7
        } else {
            quarterStartMonth = 10
        }

        // Calculate start date
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = quarterStartMonth
        startComponents.day = 1

        guard let startDate = calendar.date(from: startComponents) else { return (date, date) }

        // Calculate end date by adding 3 months to start, then subtracting 1 day
        guard let nextQuarterStart = calendar.date(byAdding: .month, value: 3, to: startDate),
              let endDate = calendar.date(byAdding: .day, value: -1, to: nextQuarterStart) else {
            return (startDate, startDate)
        }

        return (calendar.startOfDay(for: startDate), calendar.startOfDay(for: endDate))
    }

    func getWorkdaysRemainingInQuarter() -> Int {
        let (_, endDate) = getQuarterDates(for: Date())
        var current = Calendar.current.startOfDay(for: Date())
        var workdays = 0

        while current <= endDate {
            let weekday = Calendar.current.component(.weekday, from: current)
            // weekday: 1 = Sunday, 7 = Saturday
            if weekday != 1 && weekday != 7 {
                workdays += 1
            }
            current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? current
        }

        return workdays
    }

    // MARK: - Persistence

    private func loadRecords() {
        if let data = userDefaults.data(forKey: recordsKey) {
            print("📦 Loading records from UserDefaults (\(data.count) bytes)")
            do {
                let decoded = try JSONDecoder().decode([DayRecord].self, from: data)
                dayRecords = decoded
                print("✅ Loaded \(decoded.count) day records")

                // Log first few records for debugging
                for (index, record) in decoded.prefix(3).enumerated() {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    print("  Record \(index + 1): \(formatter.string(from: record.date)) - Confirmed: \(record.isConfirmed)")
                }
            } catch {
                print("❌ Error decoding day records: \(error)")
                print("   Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                // Keep empty array on error
                dayRecords = []
            }
        } else {
            print("ℹ️ No existing day records found in UserDefaults")
            dayRecords = []
        }
    }

    private func saveRecords() {
        do {
            let encoded = try JSONEncoder().encode(dayRecords)
            userDefaults.set(encoded, forKey: recordsKey)
            print("💾 Saved \(dayRecords.count) day records (\(encoded.count) bytes)")
        } catch {
            print("❌ Error encoding day records: \(error)")
        }
    }

    private func saveSettings(_ settings: AppSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }

    // MARK: - Data Export/Import

    func exportData() -> Data? {
        let exportData = ExportData(
            dayRecords: dayRecords,
            settings: settings,
            exportDate: Date(),
            appVersion: "1.3"
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(exportData)
            print("📤 Exported \(dayRecords.count) records")
            return data
        } catch {
            print("❌ Export error: \(error)")
            return nil
        }
    }

    func importData(from data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let importedData = try decoder.decode(ExportData.self, from: data)

        // Merge records (keep existing if dates conflict)
        var recordMap: [Date: DayRecord] = [:]

        // Add existing records
        for record in dayRecords {
            let key = Calendar.current.startOfDay(for: record.date)
            recordMap[key] = record
        }

        // Add imported records (don't overwrite existing)
        var newCount = 0
        for record in importedData.dayRecords {
            let key = Calendar.current.startOfDay(for: record.date)
            if recordMap[key] == nil {
                recordMap[key] = record
                newCount += 1
            }
        }

        dayRecords = Array(recordMap.values).sorted { $0.date < $1.date }
        print("📥 Imported \(newCount) new records, total: \(dayRecords.count)")

        // Optionally import settings
        // settings = importedData.settings
    }

    // MARK: - Complete Data Export/Import (v2.0)

    func exportCompleteData(achievementManager: AchievementManager) throws -> Data {
        let backupManager = BackupManager()
        let metadata = achievementManager.exportMetadata()
        let backup = try backupManager.createBackup(
            dayRecords: dayRecords,
            settings: settings,
            achievements: achievementManager.achievements,
            achievementMetadata: metadata
        )
        return try backupManager.saveToData(backup)
    }

    func importCompleteData(
        from data: Data,
        mode: ImportMode,
        achievementManager: AchievementManager,
        importSettings: Bool = false
    ) throws {
        let backupManager = BackupManager()

        // Create safety backup before import
        let safetyURL = try backupManager.createSafetyBackup(
            dataManager: self,
            achievementManager: achievementManager
        )

        do {
            // Load and validate
            let backup = try backupManager.loadBackup(from: data)

            // For merge mode, respect importSettings flag
            var actualMode = mode
            if mode == .merge && !importSettings {
                // Custom merge without settings
                try customMergeWithoutSettings(backup, backupManager: backupManager, achievementManager: achievementManager)
                return
            }

            // Restore based on mode
            try backupManager.restoreBackup(
                backup,
                mode: actualMode,
                dataManager: self,
                achievementManager: achievementManager
            )

            print("✅ Import successful, safety backup at: \(safetyURL.path)")
        } catch {
            print("❌ Import failed: \(error.localizedDescription)")
            print("   Safety backup available at: \(safetyURL.path)")
            throw error
        }
    }

    private func customMergeWithoutSettings(
        _ backup: BackupData,
        backupManager: BackupManager,
        achievementManager: AchievementManager
    ) throws {
        // Merge records only, don't touch settings
        var recordMap: [Date: DayRecord] = [:]
        for record in dayRecords {
            let key = Calendar.current.startOfDay(for: record.date)
            recordMap[key] = record
        }

        var addedCount = 0
        for record in backup.dayRecords {
            let key = Calendar.current.startOfDay(for: record.date)
            if recordMap[key] == nil {
                recordMap[key] = record
                addedCount += 1
            }
        }

        dayRecords = Array(recordMap.values).sorted { $0.date < $1.date }

        // Merge achievements
        for backupAchievement in backup.achievements where backupAchievement.isUnlocked {
            if let index = achievementManager.achievements.firstIndex(where: { $0.id == backupAchievement.id }) {
                if !achievementManager.achievements[index].isUnlocked {
                    achievementManager.achievements[index].isUnlocked = true
                    achievementManager.achievements[index].unlockedDate = backupAchievement.unlockedDate
                }
            }
        }

        print("✅ Merge complete (settings preserved): Added \(addedCount) new records")
    }

    // MARK: - Manual Override

    func toggleDayConfirmation(for date: Date) {
        let targetDate = Calendar.current.startOfDay(for: date)
        if let index = dayRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: targetDate) }) {
            var record = dayRecords[index]
            record.isConfirmed.toggle()
            record.isManualOverride = true
            dayRecords[index] = record
        } else {
            var newRecord = DayRecord(date: targetDate)
            newRecord.isConfirmed = true
            newRecord.isManualOverride = true
            dayRecords.append(newRecord)
        }

        // Explicitly notify observers of the change
        objectWillChange.send()

        // Check achievements after manual toggle
        achievementManager?.checkAchievements(dataManager: self)
    }

    // MARK: - Bulk Add Days

    func addMultipleDays(_ dates: [Date]) {
        var addedCount = 0

        for date in dates {
            let targetDate = Calendar.current.startOfDay(for: date)

            // Skip if record already exists
            if dayRecords.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: targetDate) }) {
                continue
            }

            var newRecord = DayRecord(date: targetDate)
            newRecord.isConfirmed = true
            newRecord.isManualOverride = true
            dayRecords.append(newRecord)
            addedCount += 1
        }

        // Sort by date
        dayRecords.sort { $0.date < $1.date }

        print("✅ Added \(addedCount) historical office days")

        // Notify and check achievements
        objectWillChange.send()
        achievementManager?.checkAchievements(dataManager: self)
    }
}

// MARK: - Export Data Model

struct ExportData: Codable {
    let dayRecords: [DayRecord]
    let settings: AppSettings
    let exportDate: Date
    let appVersion: String
}
