import Foundation
import Combine

final class DataManager: ObservableObject {
    @Published var dayRecords: [DayRecord] = []
    @Published var settings: AppSettings

    private var userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

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

        if record.firstCheckinTime == nil {
            record.firstCheckinTime = time
        }
        record.lastCheckinTime = time
        record.isConfirmed = true

        updateTodayRecord(record)
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
        if let data = userDefaults.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([DayRecord].self, from: data) {
            dayRecords = decoded
        }
    }

    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(dayRecords) {
            userDefaults.set(encoded, forKey: recordsKey)
        }
    }

    private func saveSettings(_ settings: AppSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
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
    }
}
