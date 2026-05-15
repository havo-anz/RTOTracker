import Testing
import Foundation
@testable import RTOTracker

@Suite("AchievementManager Tests")
@MainActor
final class AchievementManagerTests {
    var sut: AchievementManager
    var dataManager: DataManager
    var mockUserDefaults: UserDefaults
    var suiteName: String

    init() async {
        suiteName = "test.achievements.\(UUID().uuidString)"
        mockUserDefaults = UserDefaults(suiteName: suiteName)!
        sut = AchievementManager(userDefaults: mockUserDefaults)
        dataManager = DataManager(userDefaults: mockUserDefaults)
        dataManager.achievementManager = sut
    }

    deinit {
        mockUserDefaults.removePersistentDomain(forName: suiteName)
    }

    // MARK: - Initialization Tests

    @Test("All achievements are initialized on first launch")
    func achievementsInitialized() {
        #expect(sut.achievements.count == 8)
        #expect(sut.unlockedCount == 0)
    }

    @Test("Achievement categories are correctly assigned")
    func achievementCategories() {
        let milestones = sut.achievementsByCategory(.milestone)
        let streaks = sut.achievementsByCategory(.streak)
        let consistency = sut.achievementsByCategory(.consistency)

        #expect(milestones.count == 5)
        #expect(streaks.count == 2)
        #expect(consistency.count == 1)
    }

    // MARK: - First Day Achievement Tests

    @Test("First Day achievement unlocks on first confirmed day")
    func firstDayAchievement() {
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        dataManager.dayRecords = [
            DayRecord(date: apr1, isConfirmed: true)
        ]

        sut.checkAchievements(dataManager: dataManager)

        let firstDay = sut.achievements.first { $0.id == "first_day" }
        #expect(firstDay?.isUnlocked == true)
        #expect(firstDay?.unlockedDate != nil)
    }

    @Test("First Day achievement does not unlock with zero confirmed days")
    func firstDayNotUnlockedWithZeroDays() {
        dataManager.dayRecords = []

        sut.checkAchievements(dataManager: dataManager)

        let firstDay = sut.achievements.first { $0.id == "first_day" }
        #expect(firstDay?.isUnlocked == false)
    }

    @Test("First Day achievement does not unlock with unconfirmed days")
    func firstDayNotUnlockedWithUnconfirmedDays() {
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        dataManager.dayRecords = [
            DayRecord(date: apr1, isConfirmed: false)
        ]

        sut.checkAchievements(dataManager: dataManager)

        let firstDay = sut.achievements.first { $0.id == "first_day" }
        #expect(firstDay?.isUnlocked == false)
    }

    // MARK: - Quarter Champion Achievement Tests

    @Test("Quarter Champion achievement unlocks when target is met")
    func quarterChampionUnlocksAtTarget() {
        dataManager.dayRecords = createConfirmedRecordsInQ2(count: 36)

        sut.checkAchievements(dataManager: dataManager)

        let champion = sut.achievements.first { $0.id == "quarter_champion" }
        #expect(champion?.isUnlocked == true)
    }

    @Test("Quarter Champion achievement unlocks when target is exceeded")
    func quarterChampionUnlocksAboveTarget() {
        dataManager.dayRecords = createConfirmedRecordsInQ2(count: 40)

        sut.checkAchievements(dataManager: dataManager)

        let champion = sut.achievements.first { $0.id == "quarter_champion" }
        #expect(champion?.isUnlocked == true)
    }

    @Test("Quarter Champion achievement does not unlock below target")
    func quarterChampionDoesNotUnlockBelowTarget() {
        dataManager.dayRecords = createConfirmedRecordsInQ2(count: 35)

        sut.checkAchievements(dataManager: dataManager)

        let champion = sut.achievements.first { $0.id == "quarter_champion" }
        #expect(champion?.isUnlocked == false)
    }

    // MARK: - Overachiever Achievement Tests

    @Test("Overachiever achievement unlocks at target + 5")
    func overachieverUnlocksAtTargetPlusFive() {
        dataManager.dayRecords = createConfirmedRecordsInQ2(count: 41)

        sut.checkAchievements(dataManager: dataManager)

        let overachiever = sut.achievements.first { $0.id == "overachiever" }
        #expect(overachiever?.isUnlocked == true)
    }

    @Test("Overachiever achievement does not unlock at target + 4")
    func overachieverDoesNotUnlockAtTargetPlusFour() {
        dataManager.dayRecords = createConfirmedRecordsInQ2(count: 40)

        sut.checkAchievements(dataManager: dataManager)

        let overachiever = sut.achievements.first { $0.id == "overachiever" }
        #expect(overachiever?.isUnlocked == false)
    }

    // MARK: - Perfect Quarter Achievement Tests

    @Test("Perfect Quarter achievement unlocks with no manual overrides")
    func perfectQuarterUnlocksWithNoManualOverrides() {
        dataManager.dayRecords = createConfirmedRecordsInQ2(count: 36, isManualOverride: false)

        sut.checkAchievements(dataManager: dataManager)

        let perfect = sut.achievements.first { $0.id == "perfect_quarter" }
        #expect(perfect?.isUnlocked == true)
    }

    @Test("Perfect Quarter achievement does not unlock with manual overrides")
    func perfectQuarterDoesNotUnlockWithManualOverrides() {
        var records = createConfirmedRecordsInQ2(count: 35, isManualOverride: false)
        let apr30 = createDate(year: 2026, month: 4, day: 30)
        records.append(DayRecord(date: apr30, isConfirmed: true, isManualOverride: true))

        dataManager.dayRecords = records

        sut.checkAchievements(dataManager: dataManager)

        let perfect = sut.achievements.first { $0.id == "perfect_quarter" }
        #expect(perfect?.isUnlocked == false)
    }

    @Test("Perfect Quarter achievement requires target to be met")
    func perfectQuarterRequiresTargetMet() {
        dataManager.dayRecords = createConfirmedRecordsInQ2(count: 30, isManualOverride: false)

        sut.checkAchievements(dataManager: dataManager)

        let perfect = sut.achievements.first { $0.id == "perfect_quarter" }
        #expect(perfect?.isUnlocked == false)
    }

    // MARK: - Veteran Achievement Tests

    @Test("Veteran achievement unlocks after 2 quarters completed")
    func veteranUnlocksAfterTwoQuarters() {
        // Simulate completing first quarter
        dataManager.dayRecords = createConfirmedRecordsInQ2(count: 36)
        sut.checkAchievements(dataManager: dataManager)

        // Set quarters completed manually
        mockUserDefaults.set(2, forKey: "quartersCompleted")

        sut.checkAchievements(dataManager: dataManager)

        let veteran = sut.achievements.first { $0.id == "veteran" }
        #expect(veteran?.isUnlocked == true)
    }

    @Test("Veteran achievement does not unlock after 1 quarter")
    func veteranDoesNotUnlockAfterOneQuarter() {
        mockUserDefaults.set(1, forKey: "quartersCompleted")

        sut.checkAchievements(dataManager: dataManager)

        let veteran = sut.achievements.first { $0.id == "veteran" }
        #expect(veteran?.isUnlocked == false)
    }

    // MARK: - Streak Achievement Tests

    @Test("On a Roll achievement unlocks with 5-day streak")
    func onARollUnlocksWithFiveDayStreak() {
        let records = createConsecutiveWorkdayRecords(count: 5)
        dataManager.dayRecords = records

        sut.checkAchievements(dataManager: dataManager)

        let onARoll = sut.achievements.first { $0.id == "on_a_roll" }
        #expect(onARoll?.isUnlocked == true)
    }

    @Test("On a Roll achievement does not unlock with 4-day streak")
    func onARollDoesNotUnlockWithFourDayStreak() {
        let records = createConsecutiveWorkdayRecords(count: 4)
        dataManager.dayRecords = records

        sut.checkAchievements(dataManager: dataManager)

        let onARoll = sut.achievements.first { $0.id == "on_a_roll" }
        #expect(onARoll?.isUnlocked == false)
    }

    @Test("Unstoppable achievement unlocks with 10-day streak")
    func unstoppableUnlocksWithTenDayStreak() {
        let records = createConsecutiveWorkdayRecords(count: 10)
        dataManager.dayRecords = records

        sut.checkAchievements(dataManager: dataManager)

        let unstoppable = sut.achievements.first { $0.id == "unstoppable" }
        #expect(unstoppable?.isUnlocked == true)
    }

    @Test("Unstoppable achievement does not unlock with 9-day streak")
    func unstoppableDoesNotUnlockWithNineDayStreak() {
        let records = createConsecutiveWorkdayRecords(count: 9)
        dataManager.dayRecords = records

        sut.checkAchievements(dataManager: dataManager)

        let unstoppable = sut.achievements.first { $0.id == "unstoppable" }
        #expect(unstoppable?.isUnlocked == false)
    }

    @Test("Streak skips weekends correctly")
    func streakSkipsWeekends() {
        // Apr 1-11, 2026 (Wed-Sat) should be 8 workdays with weekend skipped
        let apr1 = createDate(year: 2026, month: 4, day: 1)  // Wed
        let apr2 = createDate(year: 2026, month: 4, day: 2)  // Thu
        let apr3 = createDate(year: 2026, month: 4, day: 3)  // Fri
        // Apr 4-5 = Weekend (skip)
        let apr6 = createDate(year: 2026, month: 4, day: 6)  // Mon
        let apr7 = createDate(year: 2026, month: 4, day: 7)  // Tue
        let apr8 = createDate(year: 2026, month: 4, day: 8)  // Wed
        let apr9 = createDate(year: 2026, month: 4, day: 9)  // Thu
        let apr10 = createDate(year: 2026, month: 4, day: 10) // Fri

        dataManager.dayRecords = [
            DayRecord(date: apr1, isConfirmed: true),
            DayRecord(date: apr2, isConfirmed: true),
            DayRecord(date: apr3, isConfirmed: true),
            DayRecord(date: apr6, isConfirmed: true),
            DayRecord(date: apr7, isConfirmed: true),
            DayRecord(date: apr8, isConfirmed: true),
            DayRecord(date: apr9, isConfirmed: true),
            DayRecord(date: apr10, isConfirmed: true)
        ]

        sut.checkAchievements(dataManager: dataManager)

        let onARoll = sut.achievements.first { $0.id == "on_a_roll" }
        #expect(onARoll?.isUnlocked == true)
    }

    @Test("Streak skips public holidays")
    func streakSkipsPublicHolidays() {
        let apr1 = createDate(year: 2026, month: 4, day: 1)  // Wed
        let apr2 = createDate(year: 2026, month: 4, day: 2)  // Thu
        let apr3 = createDate(year: 2026, month: 4, day: 3)  // Fri - Public Holiday
        let apr6 = createDate(year: 2026, month: 4, day: 6)  // Mon
        let apr7 = createDate(year: 2026, month: 4, day: 7)  // Tue
        let apr8 = createDate(year: 2026, month: 4, day: 8)  // Wed

        dataManager.dayRecords = [
            DayRecord(date: apr1, isConfirmed: true),
            DayRecord(date: apr2, isConfirmed: true),
            DayRecord(date: apr3, isConfirmed: false, dayType: .publicHoliday),
            DayRecord(date: apr6, isConfirmed: true),
            DayRecord(date: apr7, isConfirmed: true),
            DayRecord(date: apr8, isConfirmed: true)
        ]

        sut.checkAchievements(dataManager: dataManager)

        let onARoll = sut.achievements.first { $0.id == "on_a_roll" }
        #expect(onARoll?.isUnlocked == true)
    }

    @Test("Streak skips annual leave")
    func streakSkipsAnnualLeave() {
        let apr1 = createDate(year: 2026, month: 4, day: 1)  // Wed
        let apr2 = createDate(year: 2026, month: 4, day: 2)  // Thu
        let apr3 = createDate(year: 2026, month: 4, day: 3)  // Fri - Annual Leave
        let apr6 = createDate(year: 2026, month: 4, day: 6)  // Mon
        let apr7 = createDate(year: 2026, month: 4, day: 7)  // Tue
        let apr8 = createDate(year: 2026, month: 4, day: 8)  // Wed

        dataManager.dayRecords = [
            DayRecord(date: apr1, isConfirmed: true),
            DayRecord(date: apr2, isConfirmed: true),
            DayRecord(date: apr3, isConfirmed: false, dayType: .annualLeave),
            DayRecord(date: apr6, isConfirmed: true),
            DayRecord(date: apr7, isConfirmed: true),
            DayRecord(date: apr8, isConfirmed: true)
        ]

        sut.checkAchievements(dataManager: dataManager)

        let onARoll = sut.achievements.first { $0.id == "on_a_roll" }
        #expect(onARoll?.isUnlocked == true)
    }

    @Test("Streak breaks on missing workday")
    func streakBreaksOnMissingWorkday() {
        let apr1 = createDate(year: 2026, month: 4, day: 1)  // Wed
        let apr2 = createDate(year: 2026, month: 4, day: 2)  // Thu
        // Apr 3 = Missing (should break streak)
        let apr6 = createDate(year: 2026, month: 4, day: 6)  // Mon
        let apr7 = createDate(year: 2026, month: 4, day: 7)  // Tue
        let apr8 = createDate(year: 2026, month: 4, day: 8)  // Wed

        dataManager.dayRecords = [
            DayRecord(date: apr1, isConfirmed: true),
            DayRecord(date: apr2, isConfirmed: true),
            // Apr 3 missing
            DayRecord(date: apr6, isConfirmed: true),
            DayRecord(date: apr7, isConfirmed: true),
            DayRecord(date: apr8, isConfirmed: true)
        ]

        sut.checkAchievements(dataManager: dataManager)

        let onARoll = sut.achievements.first { $0.id == "on_a_roll" }
        #expect(onARoll?.isUnlocked == false)
    }

    // MARK: - Comeback Kid Achievement Tests

    @Test("Comeback Kid achievement unlocks when going from behind to on track")
    func comebackKidUnlocksBehindToOnTrack() {
        // Set previous status to behind
        mockUserDefaults.set("behind", forKey: "previousTrackingStatus")

        // Create enough days to be on track
        let may8 = createDate(year: 2026, month: 5, day: 8)
        dataManager.dayRecords = createConfirmedRecordsInQ2(count: 17)

        sut.checkAchievements(dataManager: dataManager)

        let comeback = sut.achievements.first { $0.id == "comeback_kid" }
        #expect(comeback?.isUnlocked == true)
    }

    @Test("Comeback Kid achievement unlocks when going from behind to ahead")
    func comebackKidUnlocksBehindToAhead() {
        mockUserDefaults.set("behind", forKey: "previousTrackingStatus")

        dataManager.dayRecords = createConfirmedRecordsInQ2(count: 20)

        sut.checkAchievements(dataManager: dataManager)

        let comeback = sut.achievements.first { $0.id == "comeback_kid" }
        #expect(comeback?.isUnlocked == true)
    }

    @Test("Comeback Kid does not unlock when staying on track")
    func comebackKidDoesNotUnlockStayingOnTrack() {
        mockUserDefaults.set("onTrack", forKey: "previousTrackingStatus")

        dataManager.dayRecords = createConfirmedRecordsInQ2(count: 17)

        sut.checkAchievements(dataManager: dataManager)

        let comeback = sut.achievements.first { $0.id == "comeback_kid" }
        #expect(comeback?.isUnlocked == false)
    }

    // MARK: - Achievement Persistence Tests

    @Test("Unlocked achievements persist through save/load")
    func achievementsPersist() {
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        dataManager.dayRecords = [
            DayRecord(date: apr1, isConfirmed: true)
        ]

        sut.checkAchievements(dataManager: dataManager)

        // Force save
        let data = try? JSONEncoder().encode(sut.achievements)
        mockUserDefaults.set(data, forKey: "achievements")

        // Create new manager with same UserDefaults
        let newManager = AchievementManager(userDefaults: mockUserDefaults)

        let firstDay = newManager.achievements.first { $0.id == "first_day" }
        #expect(firstDay?.isUnlocked == true)
    }

    @Test("Achievement unlock date is recorded")
    func achievementUnlockDateRecorded() {
        let before = Date()
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        dataManager.dayRecords = [
            DayRecord(date: apr1, isConfirmed: true)
        ]

        sut.checkAchievements(dataManager: dataManager)
        let after = Date()

        let firstDay = sut.achievements.first { $0.id == "first_day" }
        #expect(firstDay?.unlockedDate != nil)
        #expect(firstDay!.unlockedDate! >= before)
        #expect(firstDay!.unlockedDate! <= after)
    }

    @Test("Achievement only unlocks once")
    func achievementOnlyUnlocksOnce() {
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        dataManager.dayRecords = [
            DayRecord(date: apr1, isConfirmed: true)
        ]

        sut.checkAchievements(dataManager: dataManager)

        let firstUnlockDate = sut.achievements.first { $0.id == "first_day" }?.unlockedDate

        // Check again
        sut.checkAchievements(dataManager: dataManager)

        let secondUnlockDate = sut.achievements.first { $0.id == "first_day" }?.unlockedDate

        #expect(firstUnlockDate == secondUnlockDate)
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

    private func createConfirmedRecordsInQ2(count: Int, isManualOverride: Bool = false) -> [DayRecord] {
        var records: [DayRecord] = []
        let apr1 = createDate(year: 2026, month: 4, day: 1)
        var current = apr1

        while records.count < count {
            let weekday = Calendar.current.component(.weekday, from: current)
            if weekday != 1 && weekday != 7 {
                records.append(DayRecord(date: current, isConfirmed: true, isManualOverride: isManualOverride))
            }
            current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? current
        }

        return records
    }

    private func createConsecutiveWorkdayRecords(count: Int) -> [DayRecord] {
        var records: [DayRecord] = []
        var current = Calendar.current.startOfDay(for: Date())

        // Start from today and go backwards to create a current streak
        var workdaysAdded = 0
        while workdaysAdded < count {
            let weekday = Calendar.current.component(.weekday, from: current)
            if weekday != 1 && weekday != 7 {
                records.append(DayRecord(date: current, isConfirmed: true))
                workdaysAdded += 1
            }
            current = Calendar.current.date(byAdding: .day, value: -1, to: current) ?? current
        }

        return records
    }
}
