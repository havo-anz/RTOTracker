import Foundation

struct DayRecord: Codable, Identifiable {
    var id: String { date.formatted(date: .complete, time: .omitted) }
    var date: Date
    var isConfirmed: Bool
    var firstCheckinTime: Date?
    var lastCheckinTime: Date?
    var isManualOverride: Bool

    init(
        date: Date = Date(),
        isConfirmed: Bool = false,
        firstCheckinTime: Date? = nil,
        lastCheckinTime: Date? = nil,
        isManualOverride: Bool = false
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.isConfirmed = isConfirmed
        self.firstCheckinTime = firstCheckinTime
        self.lastCheckinTime = lastCheckinTime
        self.isManualOverride = isManualOverride
    }

}
