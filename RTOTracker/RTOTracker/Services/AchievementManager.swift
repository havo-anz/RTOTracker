import Foundation
import Combine
import UserNotifications

@MainActor
final class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []

    private var userDefaults: UserDefaults
    private var achievementsKey: String { "achievements" }
    private var quartersCompletedKey: String { "quartersCompleted" }
    private var previousTrackingStatusKey: String { "previousTrackingStatus" }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadAchievements()
        requestNotificationPermission()
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Achievement notifications enabled")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    private func sendNotification(for achievement: Achievement) {
        let content = UNMutableNotificationContent()
        content.title = "🏆 Achievement Unlocked!"
        content.subtitle = achievement.title
        content.body = achievement.description
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "achievement-\(achievement.id)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending achievement notification: \(error)")
            }
        }
    }

    // MARK: - Persistence

    private func loadAchievements() {
        if let data = userDefaults.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        } else {
            // First time - initialize with all achievements
            achievements = Achievement.allAchievements
            saveAchievements()
        }
    }

    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            userDefaults.set(encoded, forKey: achievementsKey)
        }
    }

    // MARK: - Achievement Checking

    func checkAchievements(dataManager: DataManager) {
        // Check each achievement and update its status dynamically
        updateFirstDay(dataManager: dataManager)
        updateQuarterChampion(dataManager: dataManager)
        updateOverachiever(dataManager: dataManager)
        updatePerfectQuarter(dataManager: dataManager)
        updateVeteran(dataManager: dataManager)
        updateStreakAchievements(dataManager: dataManager)
        updateComebackKid(dataManager: dataManager)
    }

    private func updateFirstDay(dataManager: DataManager) {
        let confirmedDays = dataManager.dayRecords.filter { $0.isConfirmed }
        let shouldBeUnlocked = confirmedDays.count >= 1

        updateAchievementStatus("first_day", shouldBeUnlocked: shouldBeUnlocked)
    }

    private func updateQuarterChampion(dataManager: DataManager) {
        let progress = dataManager.getCurrentQuarterProgress()
        let shouldBeUnlocked = progress.confirmed >= progress.target

        let wasLocked = isAchievementLocked("quarter_champion")
        updateAchievementStatus("quarter_champion", shouldBeUnlocked: shouldBeUnlocked)

        // Increment quarters completed only on first unlock
        if wasLocked && shouldBeUnlocked {
            incrementQuartersCompleted()
        }
    }

    private func updateOverachiever(dataManager: DataManager) {
        let progress = dataManager.getCurrentQuarterProgress()
        let shouldBeUnlocked = progress.confirmed >= progress.target + 5

        updateAchievementStatus("overachiever", shouldBeUnlocked: shouldBeUnlocked)
    }

    private func updatePerfectQuarter(dataManager: DataManager) {
        let progress = dataManager.getCurrentQuarterProgress()
        let quarterRecords = dataManager.getRecordsForQuarter()
        let hasManualOverrides = quarterRecords.contains { $0.isManualOverride }

        let shouldBeUnlocked = progress.confirmed >= progress.target && hasManualOverrides == false

        updateAchievementStatus("perfect_quarter", shouldBeUnlocked: shouldBeUnlocked)
    }

    private func updateVeteran(dataManager: DataManager) {
        let quartersCompleted = userDefaults.integer(forKey: quartersCompletedKey)
        let shouldBeUnlocked = quartersCompleted >= 2

        updateAchievementStatus("veteran", shouldBeUnlocked: shouldBeUnlocked)
    }

    private func updateStreakAchievements(dataManager: DataManager) {
        let currentStreak = calculateCurrentStreak(dataManager: dataManager)

        updateAchievementStatus("on_a_roll", shouldBeUnlocked: currentStreak >= 5)
        updateAchievementStatus("unstoppable", shouldBeUnlocked: currentStreak >= 10)
    }

    private func updateComebackKid(dataManager: DataManager) {
        let currentStatus = dataManager.getTrackingStatus().status
        let previousStatusRaw = userDefaults.string(forKey: previousTrackingStatusKey) ?? ""

        let shouldBeUnlocked = previousStatusRaw == "behind" && (currentStatus == .onTrack || currentStatus == .ahead)

        // Only unlock if transitioning from behind, never lock this achievement
        if shouldBeUnlocked && isAchievementLocked("comeback_kid") {
            updateAchievementStatus("comeback_kid", shouldBeUnlocked: true)
        }

        // Save current status for next check
        let statusString: String
        switch currentStatus {
        case .ahead:
            statusString = "ahead"
        case .onTrack:
            statusString = "onTrack"
        case .behind:
            statusString = "behind"
        }
        userDefaults.set(statusString, forKey: previousTrackingStatusKey)
    }

    // MARK: - Helper Methods

    private func calculateCurrentStreak(dataManager: DataManager) -> Int {
        let allRecords = dataManager.dayRecords.sorted { $0.date > $1.date } // Most recent first

        var streak = 0
        var expectedDate = Calendar.current.startOfDay(for: Date())

        // Build a map of all records for quick lookup
        var recordMap: [Date: DayRecord] = [:]
        for record in allRecords {
            recordMap[Calendar.current.startOfDay(for: record.date)] = record
        }

        // Count backwards from today
        while true {
            let weekday = Calendar.current.component(.weekday, from: expectedDate)

            // Check if this day is a weekend
            if weekday == 1 || weekday == 7 {
                // Skip weekend, move to previous day
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
                continue
            }

            // Check if we have a record for this date
            if let record = recordMap[expectedDate] {
                // Check day type
                if record.dayType == DayRecord.DayType.publicHoliday || record.dayType == DayRecord.DayType.annualLeave {
                    // Skip public holiday or annual leave, move to previous day
                    expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
                    continue
                }

                // Must be a workday - check if confirmed
                if record.isConfirmed {
                    streak += 1
                    // Move to previous day
                    expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
                } else {
                    // Not confirmed on a workday - streak broken
                    break
                }
            } else {
                // No record for today - streak broken (unless it's today and we haven't checked in yet)
                let today = Calendar.current.startOfDay(for: Date())
                if Calendar.current.isDate(expectedDate, inSameDayAs: today) {
                    // It's today and we haven't checked in yet - don't break streak
                    expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
                    continue
                } else {
                    // Missing workday - streak broken
                    break
                }
            }
        }

        return streak
    }

    private func isAchievementLocked(_ id: String) -> Bool {
        if let achievement = achievements.first(where: { $0.id == id }) {
            return achievement.isUnlocked == false
        }
        return false
    }

    private func updateAchievementStatus(_ id: String, shouldBeUnlocked: Bool) {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return }

        let wasUnlocked = achievements[index].isUnlocked

        if shouldBeUnlocked && wasUnlocked == false {
            // Unlock achievement
            achievements[index].isUnlocked = true
            achievements[index].unlockedDate = Date()
            saveAchievements()

            // Send push notification
            sendNotification(for: achievements[index])
        } else if shouldBeUnlocked == false && wasUnlocked {
            // Lock achievement (for testing - remove if earned)
            achievements[index].isUnlocked = false
            achievements[index].unlockedDate = nil
            saveAchievements()
        }
    }

    private func incrementQuartersCompleted() {
        let current = userDefaults.integer(forKey: quartersCompletedKey)
        userDefaults.set(current + 1, forKey: quartersCompletedKey)
    }

    // MARK: - Public Helpers

    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var totalCount: Int {
        achievements.count
    }

    func achievementsByCategory(_ category: Achievement.AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }

    // MARK: - Export/Import Metadata

    func exportMetadata() -> AchievementMetadata {
        AchievementMetadata(
            quartersCompleted: userDefaults.integer(forKey: quartersCompletedKey),
            previousTrackingStatus: userDefaults.string(forKey: previousTrackingStatusKey) ?? ""
        )
    }

    func importMetadata(_ metadata: AchievementMetadata) {
        userDefaults.set(metadata.quartersCompleted, forKey: quartersCompletedKey)
        userDefaults.set(metadata.previousTrackingStatus, forKey: previousTrackingStatusKey)
        print("✅ Achievement metadata imported: \(metadata.quartersCompleted) quarters, status: \(metadata.previousTrackingStatus)")
    }

    func importAchievements(_ achievements: [Achievement]) {
        self.achievements = achievements
        saveAchievements()
        print("✅ Achievements imported: \(achievements.filter { $0.isUnlocked }.count)/\(achievements.count) unlocked")
    }

    // MARK: - Reset (for testing)

    func resetAllAchievements() {
        for index in achievements.indices {
            achievements[index].isUnlocked = false
            achievements[index].unlockedDate = nil
        }
        saveAchievements()

        // Reset quarters completed
        userDefaults.set(0, forKey: quartersCompletedKey)
        userDefaults.removeObject(forKey: previousTrackingStatusKey)
    }
}
