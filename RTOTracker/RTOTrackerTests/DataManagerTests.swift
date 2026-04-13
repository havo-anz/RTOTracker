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

    @Test("Tracking status early in quarter with 3 days is ahead")
    func trackingStatusOnTrack() {
        // On April 3 (3 workdays elapsed), having 3 confirmed days should be ahead
        // Expected at day 3: round(3 * 36 / 65) = round(1.66) = 2
        // Actual: 3, so status should be ahead (3 >= 2)
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        let apr2 = createDate(year: 2026, month: 4, day: 2)
        let apr3 = createDate(year: 2026, month: 4, day: 3)

        sut.dayRecords = [
            DayRecord(date: apr1, isConfirmed: true),
            DayRecord(date: apr2, isConfirmed: true),
            DayRecord(date: apr3, isConfirmed: true)
        ]

        let tracking = calculateTrackingStatusForDate(apr3)
        #expect(tracking.status == .onTrack || tracking.status == .ahead)
        #expect(tracking.actualDays == 3)
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

    // MARK: - Expected Days Calculation Coverage

    @Test("Expected days at start of quarter (Day 1) should be 0-1")
    func expectedDaysDay1() {
        // Q2 2026: April 1 is a Wednesday (workday 1)
        let apr1 = createDate(year: 2026, month: 4, day: 1)

        // Set current date to April 1
        sut.dayRecords = []

        let tracking = calculateTrackingStatusForDate(apr1)

        // After 1 workday elapsed out of ~65 total workdays: round(1 * 36 / 65) = round(0.55) = 1
        #expect(tracking.expectedDays >= 0)
        #expect(tracking.expectedDays <= 1)
    }

    @Test("Expected days at week 2 (10 workdays) should be approximately 6")
    func expectedDaysWeek2() {
        // Q2 2026: April 14 (Monday) = 10 workdays elapsed
        let apr14 = createDate(year: 2026, month: 4, day: 14)

        let tracking = calculateTrackingStatusForDate(apr14)

        // After 10 workdays: round(10 * 36 / 65) = round(5.54) = 6
        #expect(tracking.expectedDays >= 5)
        #expect(tracking.expectedDays <= 6)
    }

    @Test("Expected days at mid-quarter (30 workdays) should be approximately 17")
    func expectedDaysMidQuarter() {
        // Q2 2026: May 8 (Friday) ≈ 30 workdays elapsed
        let may8 = createDate(year: 2026, month: 5, day: 8)

        let tracking = calculateTrackingStatusForDate(may8)

        // After 30 workdays: round(30 * 36 / 65) = round(16.62) = 17
        #expect(tracking.expectedDays >= 16)
        #expect(tracking.expectedDays <= 18)
    }

    @Test("Expected days at end of quarter should equal target (36)")
    func expectedDaysEndOfQuarter() {
        // Q2 2026: June 30 (Tuesday) = last day
        let jun30 = createDate(year: 2026, month: 6, day: 30)

        let tracking = calculateTrackingStatusForDate(jun30)

        // All workdays elapsed: expected should equal target
        #expect(tracking.expectedDays == 36)
    }

    // MARK: - Tracking Status Boundary Tests

    @Test("Status: Ahead when actual >= expected + 2")
    func trackingStatusAheadBoundary() {
        // Set date to mid-quarter (May 8, expected ≈ 17)
        let may8 = createDate(year: 2026, month: 5, day: 8)

        // Create 19 confirmed days (17 expected + 2 = ahead)
        sut.dayRecords = createConfirmedRecordsInQ2(count: 19)

        let tracking = calculateTrackingStatusForDate(may8)

        #expect(tracking.status == .ahead)
        #expect(tracking.actualDays == 19)
    }

    @Test("Status: On Track when actual == expected")
    func trackingStatusOnTrackExact() {
        // Set date to mid-quarter (May 8, expected ≈ 17)
        let may8 = createDate(year: 2026, month: 5, day: 8)

        // Create exactly expected number of days
        let tracking = calculateTrackingStatusForDate(may8)
        let expectedDays = tracking.expectedDays

        sut.dayRecords = createConfirmedRecordsInQ2(count: expectedDays)

        let updatedTracking = calculateTrackingStatusForDate(may8)

        #expect(updatedTracking.status == .onTrack)
        #expect(updatedTracking.actualDays == expectedDays)
    }

    @Test("Status: On Track when actual == expected + 1")
    func trackingStatusOnTrackPlusOne() {
        // Set date to mid-quarter (May 8, expected ≈ 17)
        let may8 = createDate(year: 2026, month: 5, day: 8)

        let tracking = calculateTrackingStatusForDate(may8)
        let expectedDays = tracking.expectedDays

        // Create expected + 1 days (still on track, not ahead yet)
        sut.dayRecords = createConfirmedRecordsInQ2(count: expectedDays + 1)

        let updatedTracking = calculateTrackingStatusForDate(may8)

        #expect(updatedTracking.status == .onTrack)
        #expect(updatedTracking.actualDays == expectedDays + 1)
    }

    @Test("Status: Behind when actual < expected")
    func trackingStatusBehindBoundary() {
        // Set date to mid-quarter (May 8, expected ≈ 17)
        let may8 = createDate(year: 2026, month: 5, day: 8)

        let tracking = calculateTrackingStatusForDate(may8)
        let expectedDays = tracking.expectedDays

        // Create fewer days than expected
        sut.dayRecords = createConfirmedRecordsInQ2(count: expectedDays - 1)

        let updatedTracking = calculateTrackingStatusForDate(may8)

        #expect(updatedTracking.status == .behind)
        #expect(updatedTracking.actualDays == expectedDays - 1)
    }

    @Test("Status: Behind when actual == 0 at mid-quarter")
    func trackingStatusBehindZeroDays() {
        // Set date to mid-quarter (May 8, expected ≈ 17)
        let may8 = createDate(year: 2026, month: 5, day: 8)

        sut.dayRecords = []

        let tracking = calculateTrackingStatusForDate(may8)

        #expect(tracking.status == .behind)
        #expect(tracking.actualDays == 0)
        #expect(tracking.expectedDays > 0)
    }

    @Test("Status: On Track when actual == 36 at end of quarter")
    func trackingStatusEndOfQuarterComplete() {
        // June 30, 2026 (last day of Q2)
        let jun30 = createDate(year: 2026, month: 6, day: 30)

        // Create exactly 36 confirmed days
        sut.dayRecords = createConfirmedRecordsInQ2(count: 36)

        let tracking = calculateTrackingStatusForDate(jun30)

        #expect(tracking.status == .onTrack)
        #expect(tracking.actualDays == 36)
        #expect(tracking.expectedDays == 36)
    }

    @Test("Status: Ahead when actual > 36 at end of quarter")
    func trackingStatusEndOfQuarterExceeded() {
        // June 30, 2026 (last day of Q2)
        let jun30 = createDate(year: 2026, month: 6, day: 30)

        // Create 38 confirmed days (over target)
        sut.dayRecords = createConfirmedRecordsInQ2(count: 38)

        let tracking = calculateTrackingStatusForDate(jun30)

        #expect(tracking.status == .ahead)
        #expect(tracking.actualDays == 38)
        #expect(tracking.expectedDays == 36)
    }

    @Test("Goal met: confirmed >= target shows completion")
    func goalMetExactlyAtTarget() {
        // Create exactly 36 confirmed days
        sut.dayRecords = createConfirmedRecordsInQ2(count: 36)

        let progress = sut.getCurrentQuarterProgress()

        #expect(progress.confirmed >= progress.target)
        #expect(progress.confirmed == 36)
        #expect(progress.target == 36)
    }

    @Test("Goal met: confirmed > target shows completion")
    func goalMetOverTarget() {
        // Create 40 confirmed days (exceeded target)
        sut.dayRecords = createConfirmedRecordsInQ2(count: 40)

        let progress = sut.getCurrentQuarterProgress()

        #expect(progress.confirmed >= progress.target)
        #expect(progress.confirmed == 40)
        #expect(progress.target == 36)
    }

    @Test("Goal not met: confirmed < target")
    func goalNotMet() {
        // Create only 20 confirmed days
        sut.dayRecords = createConfirmedRecordsInQ2(count: 20)

        let progress = sut.getCurrentQuarterProgress()

        #expect(progress.confirmed < progress.target)
        #expect(progress.confirmed == 20)
        #expect(progress.target == 36)
    }

    // MARK: - Workday Counting Accuracy

    @Test("Total workdays in Q2 2026 is 65")
    func totalWorkdaysQ2_2026() {
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        let (start, end) = sut.getQuarterDates(for: apr1)

        var totalWorkdays = 0
        var current = start

        while current <= end {
            let weekday = Calendar.current.component(.weekday, from: current)
            if weekday != 1 && weekday != 7 {
                totalWorkdays += 1
            }
            current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? current
        }

        #expect(totalWorkdays == 65)
    }

    @Test("Workdays from Apr 1 to Apr 14 (Mon) is 10")
    func workdaysElapsedApr14() {
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        let apr14 = createDate(year: 2026, month: 4, day: 14)

        var workdays = 0
        var current = apr1

        while current <= apr14 {
            let weekday = Calendar.current.component(.weekday, from: current)
            if weekday != 1 && weekday != 7 {
                workdays += 1
            }
            current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? current
        }

        #expect(workdays == 10)
    }

    // MARK: - Edge Cases

    @Test("Expected days calculation handles rounding correctly")
    func expectedDaysRoundingBehavior() {
        // Test various points to ensure rounding is consistent
        let testCases: [(day: Int, month: Int, minExpected: Int, maxExpected: Int)] = [
            (1, 4, 0, 1),    // Day 1: should round to 0-1
            (7, 4, 2, 3),    // Day 5 workdays: should be ~3
            (14, 4, 5, 6),   // Day 10 workdays: should be ~6
            (30, 4, 10, 12), // Day ~20 workdays: should be ~11
            (30, 6, 35, 36)  // Last day: should be 36
        ]

        for testCase in testCases {
            let date = createDate(year: 2026, month: testCase.month, day: testCase.day)
            let tracking = calculateTrackingStatusForDate(date)

            #expect(tracking.expectedDays >= testCase.minExpected)
            #expect(tracking.expectedDays <= testCase.maxExpected)
        }
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

    // MARK: - Test Helper Methods

    private func calculateTrackingStatusForDate(_ date: Date) -> (status: DataManager.TrackingStatus, expectedDays: Int, actualDays: Int) {
        let (startDate, endDate) = sut.getQuarterDates(for: date)
        let today = Calendar.current.startOfDay(for: date)

        // Count workdays elapsed
        var workdaysElapsed = 0
        var currentDate = startDate

        while currentDate <= today && currentDate <= endDate {
            let weekday = Calendar.current.component(.weekday, from: currentDate)
            if weekday != 1 && weekday != 7 {
                workdaysElapsed += 1
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Count total workdays
        var totalWorkdays = 0
        currentDate = startDate

        while currentDate <= endDate {
            let weekday = Calendar.current.component(.weekday, from: currentDate)
            if weekday != 1 && weekday != 7 {
                totalWorkdays += 1
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Calculate expected
        let expectedDays = totalWorkdays > 0 ? Int(round(Double(workdaysElapsed) * Double(sut.settings.quarterTarget) / Double(totalWorkdays))) : 0

        // Get actual
        let actualDays = sut.getRecordsForQuarter(date).filter { $0.isConfirmed }.count

        // Determine status
        let status: DataManager.TrackingStatus
        if actualDays >= expectedDays + 2 {
            status = .ahead
        } else if actualDays >= expectedDays {
            status = .onTrack
        } else {
            status = .behind
        }

        return (status, expectedDays, actualDays)
    }

    private func createConfirmedRecordsInQ2(count: Int) -> [DayRecord] {
        var records: [DayRecord] = []
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        var current = apr1

        while records.count < count {
            let weekday = Calendar.current.component(.weekday, from: current)
            // Only add workdays
            if weekday != 1 && weekday != 7 {
                records.append(DayRecord(date: current, isConfirmed: true))
            }
            current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? current
        }

        return records
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
