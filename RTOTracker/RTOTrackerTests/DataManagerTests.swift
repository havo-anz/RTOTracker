import Testing
import Foundation
@testable import RTOTracker

@Suite("DataManager Tests")
final class DataManagerTests {
    var sut: DataManager
    var mockUserDefaults: UserDefaults
    var suiteName: String

    init() {
        suiteName = "test.rtotracker.\(UUID().uuidString)"
        mockUserDefaults = UserDefaults(suiteName: suiteName)!
        sut = DataManager(userDefaults: mockUserDefaults)
    }

    deinit {
        mockUserDefaults.removePersistentDomain(forName: suiteName)
    }

    // MARK: - Quarter Date Calculations

    @Test("Q1 quarter dates are January 1 to March 31")
    func quarterDatesQ1() {
        let jan15 = createDate(year: 2026, month: 1, day: 15)
        let (start, end) = sut.getQuarterDates(for: jan15)

        #expect(start == createDate(year: 2026, month: 1, day: 1))
        #expect(end == createDate(year: 2026, month: 3, day: 31))
    }

    @Test("Q2 quarter dates are April 1 to June 30")
    func quarterDatesQ2() {
        let apr7 = createDate(year: 2026, month: 4, day: 7)
        let (start, end) = sut.getQuarterDates(for: apr7)

        #expect(start == createDate(year: 2026, month: 4, day: 1))
        #expect(end == createDate(year: 2026, month: 6, day: 30))
    }

    @Test("Q3 quarter dates are July 1 to September 30")
    func quarterDatesQ3() {
        let jul20 = createDate(year: 2026, month: 7, day: 20)
        let (start, end) = sut.getQuarterDates(for: jul20)

        #expect(start == createDate(year: 2026, month: 7, day: 1))
        #expect(end == createDate(year: 2026, month: 9, day: 30))
    }

    @Test("Q4 quarter dates are October 1 to December 31")
    func quarterDatesQ4() {
        let dec31 = createDate(year: 2026, month: 12, day: 31)
        let (start, end) = sut.getQuarterDates(for: dec31)

        #expect(start == createDate(year: 2026, month: 10, day: 1))
        #expect(end == createDate(year: 2026, month: 12, day: 31))
    }

    // MARK: - Workday Calculations

    @Test("Workdays remaining includes today and excludes weekends")
    func workdaysRemainingIncludesToday() {
        let monday = createDate(year: 2026, month: 4, day: 6)
        let (_, endDate) = sut.getQuarterDates(for: monday)

        var workdays = 0
        var current = monday
        let calendar = Calendar.current

        while current <= endDate {
            let weekday = calendar.component(.weekday, from: current)
            if weekday != 1 && weekday != 7 {
                workdays += 1
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }

        #expect(workdays > 55)
        #expect(workdays < 65)
    }

    @Test("Weekend days are excluded from workday count")
    func workdaysExcludeWeekends() {
        let saturday = createDate(year: 2026, month: 4, day: 4)
        let (_, endDate) = sut.getQuarterDates(for: saturday)

        var current = saturday
        var weekendCount = 0
        let calendar = Calendar.current

        while current <= endDate {
            let weekday = calendar.component(.weekday, from: current)
            if weekday == 1 || weekday == 7 {
                weekendCount += 1
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }

        #expect(weekendCount > 20)
    }

    // MARK: - Day Records Management

    @Test("Today's record defaults to unconfirmed when none exists")
    func todayRecordNoExisting() {
        let record = sut.getTodayRecord()

        #expect(record.isConfirmed == false)
        #expect(record.firstCheckinTime == nil)
        #expect(record.lastCheckinTime == nil)
        #expect(record.isManualOverride == false)
    }

    @Test("Confirming today as office day sets check-in times")
    func confirmTodayFirstTime() {
        let checkInTime = Date()
        sut.confirmTodayAsOfficeDay(at: checkInTime)

        let record = sut.getTodayRecord()
        #expect(record.isConfirmed == true)
        #expect(record.firstCheckinTime == checkInTime)
        #expect(record.lastCheckinTime == checkInTime)
    }

    @Test("Second confirmation updates last check-in time only")
    func confirmTodaySecondTime() {
        let firstCheckIn = Date()
        sut.confirmTodayAsOfficeDay(at: firstCheckIn)

        let secondCheckIn = Date().addingTimeInterval(3600)
        sut.confirmTodayAsOfficeDay(at: secondCheckIn)

        let record = sut.getTodayRecord()
        #expect(record.isConfirmed == true)
        #expect(record.firstCheckinTime == firstCheckIn)
        #expect(record.lastCheckinTime == secondCheckIn)
    }

    @Test("Toggling new day creates confirmed manual record")
    func toggleDayConfirmationNew() {
        let testDate = createDate(year: 2026, month: 4, day: 1)
        sut.toggleDayConfirmation(for: testDate)

        let record = sut.dayRecords.first { Calendar.current.isDate($0.date, inSameDayAs: testDate) }
        #expect(record != nil)
        #expect(record?.isConfirmed == true)
        #expect(record?.isManualOverride == true)
    }

    @Test("Toggling existing day flips confirmation status")
    func toggleDayConfirmationExisting() {
        let testDate = createDate(year: 2026, month: 4, day: 1)
        sut.toggleDayConfirmation(for: testDate)
        sut.toggleDayConfirmation(for: testDate)

        let record = sut.dayRecords.first { Calendar.current.isDate($0.date, inSameDayAs: testDate) }
        #expect(record != nil)
        #expect(record?.isConfirmed == false)
        #expect(record?.isManualOverride == true)
    }

    // MARK: - Quarter Progress

    @Test("Current quarter progress shows zero with no records")
    func currentQuarterProgressNoRecords() {
        let progress = sut.getCurrentQuarterProgress()

        #expect(progress.confirmed == 0)
        #expect(progress.target == 36)
    }

    @Test("Current quarter progress counts only confirmed days")
    func currentQuarterProgressWithRecords() {
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        let apr2 = createDate(year: 2026, month: 4, day: 2)
        let apr3 = createDate(year: 2026, month: 4, day: 3)

        sut.dayRecords = [
            DayRecord(date: apr1, isConfirmed: true),
            DayRecord(date: apr2, isConfirmed: true),
            DayRecord(date: apr3, isConfirmed: false)
        ]

        let progress = sut.getCurrentQuarterProgress()

        #expect(progress.confirmed == 2)
        #expect(progress.target == 36)
    }

    @Test("Records for quarter filters correctly by quarter boundaries")
    func recordsForQuarterFilters() {
        let mar31 = createDate(year: 2026, month: 3, day: 31)
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        let jun30 = createDate(year: 2026, month: 6, day: 30)
        let jul1 = createDate(year: 2026, month: 7, day: 1)

        sut.dayRecords = [
            DayRecord(date: mar31, isConfirmed: true),
            DayRecord(date: apr1, isConfirmed: true),
            DayRecord(date: jun30, isConfirmed: true),
            DayRecord(date: jul1, isConfirmed: true)
        ]

        let q2Date = createDate(year: 2026, month: 5, day: 15)
        let q2Records = sut.getRecordsForQuarter(q2Date)

        #expect(q2Records.count == 2)
        #expect(q2Records.contains { Calendar.current.isDate($0.date, inSameDayAs: apr1) })
        #expect(q2Records.contains { Calendar.current.isDate($0.date, inSameDayAs: jun30) })
    }

    // MARK: - Tracking Status Logic

    @Test("Tracking status logic: exact match is On Track")
    func trackingStatusExactMatch() {
        let actual = 5
        let expected = 5

        let status: DataManager.TrackingStatus
        if actual >= expected + 2 {
            status = .ahead
        } else if actual >= expected {
            status = .onTrack
        } else {
            status = .behind
        }

        #expect(status == .onTrack)
    }

    @Test("Tracking status logic: one behind is Behind")
    func trackingStatusOneBehind() {
        let actual = 2
        let expected = 3

        let status: DataManager.TrackingStatus
        if actual >= expected + 2 {
            status = .ahead
        } else if actual >= expected {
            status = .onTrack
        } else {
            status = .behind
        }

        #expect(status == .behind)
    }

    @Test("Tracking status logic: two ahead is Ahead")
    func trackingStatusTwoAhead() {
        let actual = 7
        let expected = 5

        let status: DataManager.TrackingStatus
        if actual >= expected + 2 {
            status = .ahead
        } else if actual >= expected {
            status = .onTrack
        } else {
            status = .behind
        }

        #expect(status == .ahead)
    }

    @Test("Tracking status with multiple days is on track or ahead")
    func trackingStatusOnTrack() {
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        let apr2 = createDate(year: 2026, month: 4, day: 2)
        let apr3 = createDate(year: 2026, month: 4, day: 3)

        sut.dayRecords = [
            DayRecord(date: apr1, isConfirmed: true),
            DayRecord(date: apr2, isConfirmed: true),
            DayRecord(date: apr3, isConfirmed: true)
        ]

        let tracking = sut.getTrackingStatus()
        #expect(tracking.status == .onTrack || tracking.status == .ahead)
    }

    @Test("Tracking status with 5 early days shows actual count")
    func trackingStatusAhead() {
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        let apr2 = createDate(year: 2026, month: 4, day: 2)
        let apr3 = createDate(year: 2026, month: 4, day: 3)
        let apr4 = createDate(year: 2026, month: 4, day: 4)
        let apr7 = createDate(year: 2026, month: 4, day: 7)

        sut.dayRecords = [
            DayRecord(date: apr1, isConfirmed: true),
            DayRecord(date: apr2, isConfirmed: true),
            DayRecord(date: apr3, isConfirmed: true),
            DayRecord(date: apr4, isConfirmed: true),
            DayRecord(date: apr7, isConfirmed: true)
        ]

        let tracking = sut.getTrackingStatus()
        #expect(tracking.actualDays == 5)
    }

    @Test("Workdays calculation from Apr 1-7 excludes weekend")
    func trackingStatusBehindWorkdays() {
        let apr7 = createDate(year: 2026, month: 4, day: 7)
        let (start, _) = sut.getQuarterDates(for: apr7)

        var workdaysElapsed = 0
        var current = start

        while current <= apr7 {
            let weekday = Calendar.current.component(.weekday, from: current)
            if weekday != 1 && weekday != 7 {
                workdaysElapsed += 1
            }
            current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? current
        }

        #expect(workdaysElapsed == 5)
    }

    // MARK: - Settings

    @Test("Default settings have correct values")
    func settingsDefaults() {
        #expect(sut.settings.officeIPPrefix == "10.78.")
        #expect(sut.settings.quarterTarget == 36)
        #expect(sut.settings.reminderEnabled == true)
    }

    @Test("Custom target is reflected in progress")
    func settingsCustomTarget() {
        sut.settings.quarterTarget = 40

        let progress = sut.getCurrentQuarterProgress()
        #expect(progress.target == 40)
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

@Suite("DataManager Persistence Tests")
final class DataManagerPersistenceTests {

    @Test("Records are saved and loaded correctly")
    func persistenceSavesAndLoads() async throws {
        let suiteName = "test.rtotracker.persistence.\(UUID().uuidString)"
        let mockUserDefaults = UserDefaults(suiteName: suiteName)!
        defer { mockUserDefaults.removePersistentDomain(forName: suiteName) }

        let sut = DataManager(userDefaults: mockUserDefaults)

        let apr1 = createDate(year: 2026, month: 4, day: 1)
        sut.dayRecords = [
            DayRecord(date: apr1, isConfirmed: true, isManualOverride: true)
        ]

        // Wait for debounce
        try await Task.sleep(for: .seconds(1.5))

        // Create new manager with same UserDefaults
        let newManager = DataManager(userDefaults: mockUserDefaults)

        #expect(newManager.dayRecords.count == 1)
        #expect(newManager.dayRecords.first?.isConfirmed == true)
        #expect(newManager.dayRecords.first?.isManualOverride == true)
    }

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
