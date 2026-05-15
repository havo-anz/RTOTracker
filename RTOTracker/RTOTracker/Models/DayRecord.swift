import Foundation

struct DayRecord: Codable, Identifiable {
    var id: String { date.formatted(date: .complete, time: .omitted) }
    var date: Date
    var isConfirmed: Bool
    var firstCheckinTime: Date?
    var lastCheckinTime: Date?
    var isManualOverride: Bool
    var dayType: DayType

    enum DayType: String, Codable {
        case workday
        case weekend
        case publicHoliday
        case annualLeave
    }

    init(
        date: Date = Date(),
        isConfirmed: Bool = false,
        firstCheckinTime: Date? = nil,
        lastCheckinTime: Date? = nil,
        isManualOverride: Bool = false,
        dayType: DayType = .workday
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.isConfirmed = isConfirmed
        self.firstCheckinTime = firstCheckinTime
        self.lastCheckinTime = lastCheckinTime
        self.isManualOverride = isManualOverride

        // Auto-detect weekend
        let weekday = Calendar.current.component(.weekday, from: self.date)
        if weekday == 1 || weekday == 7 {
            self.dayType = .weekend
        } else {
            self.dayType = dayType
        }
    }

    var isWorkday: Bool {
        dayType == .workday
    }

}
