import Testing
import Foundation
@testable import RTOTracker

@Suite("Day Record Tests")
struct DayRecordTests {

    // MARK: - Initialization Tests

    @Test("Default initialization creates unconfirmed record")
    func defaultInitialization() {
        let record = DayRecord()

        #expect(record.isConfirmed == false)
        #expect(record.firstCheckinTime == nil)
        #expect(record.lastCheckinTime == nil)
        #expect(record.isManualOverride == false)
    }

    @Test("Custom initialization sets all properties")
    func customInitialization() {
        let testDate = Date()
        let checkinTime = Date()

        let record = DayRecord(
            date: testDate,
            isConfirmed: true,
            firstCheckinTime: checkinTime,
            lastCheckinTime: checkinTime,
            isManualOverride: true
        )

        #expect(record.isConfirmed == true)
        #expect(record.firstCheckinTime == checkinTime)
        #expect(record.lastCheckinTime == checkinTime)
        #expect(record.isManualOverride == true)
    }

    @Test("Date is normalized to start of day")
    func dateNormalizationToStartOfDay() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 7
        components.hour = 15
        components.minute = 30
        components.second = 45

        let dateWithTime = calendar.date(from: components)!
        let record = DayRecord(date: dateWithTime)

        let recordDate = record.date
        let hour = calendar.component(.hour, from: recordDate)
        let minute = calendar.component(.minute, from: recordDate)
        let second = calendar.component(.second, from: recordDate)

        #expect(hour == 0)
        #expect(minute == 0)
        #expect(second == 0)
    }

    // MARK: - Identifiable Tests

    @Test("Different dates have different IDs")
    func hasUniqueID() {
        let date1 = createDate(year: 2026, month: 4, day: 1)
        let date2 = createDate(year: 2026, month: 4, day: 2)

        let record1 = DayRecord(date: date1)
        let record2 = DayRecord(date: date2)

        #expect(record1.id != record2.id)
    }

    @Test("Same date produces same ID regardless of other properties")
    func sameDateSameID() {
        let date = createDate(year: 2026, month: 4, day: 1)

        let record1 = DayRecord(date: date, isConfirmed: true)
        let record2 = DayRecord(date: date, isConfirmed: false)

        #expect(record1.id == record2.id)
    }

    // MARK: - Codable Tests

    @Test("Encoding and decoding preserves all properties")
    func encodingDecoding() throws {
        let originalDate = createDate(year: 2026, month: 4, day: 7)
        let checkinTime = Date()

        let original = DayRecord(
            date: originalDate,
            isConfirmed: true,
            firstCheckinTime: checkinTime,
            lastCheckinTime: checkinTime,
            isManualOverride: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DayRecord.self, from: data)

        #expect(decoded.isConfirmed == original.isConfirmed)
        #expect(decoded.isManualOverride == original.isManualOverride)
        #expect(decoded.firstCheckinTime != nil)
        #expect(decoded.lastCheckinTime != nil)
    }

    @Test("Encoding and decoding handles nil values")
    func encodingDecodingWithNilValues() throws {
        let originalDate = createDate(year: 2026, month: 4, day: 7)

        let original = DayRecord(
            date: originalDate,
            isConfirmed: false,
            firstCheckinTime: nil,
            lastCheckinTime: nil,
            isManualOverride: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DayRecord.self, from: data)

        #expect(decoded.isConfirmed == false)
        #expect(decoded.firstCheckinTime == nil)
        #expect(decoded.lastCheckinTime == nil)
        #expect(decoded.isManualOverride == false)
    }

    // MARK: - State Combinations

    @Test("Auto-confirmed day has check-in times and no manual flag")
    func autoConfirmedDay() {
        let record = DayRecord(
            date: Date(),
            isConfirmed: true,
            firstCheckinTime: Date(),
            lastCheckinTime: Date(),
            isManualOverride: false
        )

        #expect(record.isConfirmed == true)
        #expect(record.isManualOverride == false)
        #expect(record.firstCheckinTime != nil)
    }

    @Test("Manually confirmed day has manual flag and no check-in times")
    func manuallyConfirmedDay() {
        let record = DayRecord(
            date: Date(),
            isConfirmed: true,
            firstCheckinTime: nil,
            lastCheckinTime: nil,
            isManualOverride: true
        )

        #expect(record.isConfirmed == true)
        #expect(record.isManualOverride == true)
        #expect(record.firstCheckinTime == nil)
    }

    @Test("Unconfirmed day has no flags or times")
    func unconfirmedDay() {
        let record = DayRecord()

        #expect(record.isConfirmed == false)
        #expect(record.isManualOverride == false)
        #expect(record.firstCheckinTime == nil)
        #expect(record.lastCheckinTime == nil)
    }

    // MARK: - Mutation Tests

    @Test("DayRecord is mutable and properties can be changed")
    func isMutable() {
        var record = DayRecord()

        #expect(record.isConfirmed == false)

        record.isConfirmed = true
        record.isManualOverride = true
        record.firstCheckinTime = Date()

        #expect(record.isConfirmed == true)
        #expect(record.isManualOverride == true)
        #expect(record.firstCheckinTime != nil)
    }

    // MARK: - Helper Methods

    private func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }
}
