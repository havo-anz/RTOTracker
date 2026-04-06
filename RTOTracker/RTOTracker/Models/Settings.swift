import Foundation

struct AppSettings: Codable {
    var officeIPPrefix: String
    var quarterTarget: Int
    var quarterStartMonths: [Int]
    var reminderEnabled: Bool
    var reminderTime: Date
    var launchAtLogin: Bool

    static var `default`: AppSettings {
        AppSettings(
            officeIPPrefix: "10.78.",
            quarterTarget: 36,
            quarterStartMonths: [1, 4, 7, 10], // Calendar quarters
            reminderEnabled: true,
            reminderTime: createTime(hour: 9, minute: 15),
            launchAtLogin: false
        )
    }

    private static func createTime(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
