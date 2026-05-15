import Foundation

struct Achievement: Codable, Identifiable {
    var id: String
    var title: String
    var description: String
    var icon: String // SF Symbol name
    var isUnlocked: Bool
    var unlockedDate: Date?
    var category: AchievementCategory

    enum AchievementCategory: String, Codable {
        case milestone
        case streak
        case consistency
        case special
    }

    // Define all achievements
    static var allAchievements: [Achievement] {
        [
            // Milestone Achievements
            Achievement(
                id: "first_day",
                title: "First Day",
                description: "Confirm your first office day",
                icon: "star.fill",
                isUnlocked: false,
                category: .milestone
            ),
            Achievement(
                id: "quarter_champion",
                title: "Quarter Champion",
                description: "Meet your 36-day quarter target",
                icon: "trophy.fill",
                isUnlocked: false,
                category: .milestone
            ),
            Achievement(
                id: "overachiever",
                title: "Overachiever",
                description: "Exceed quarter target by 5+ days",
                icon: "star.circle.fill",
                isUnlocked: false,
                category: .milestone
            ),
            Achievement(
                id: "perfect_quarter",
                title: "Perfect Quarter",
                description: "Meet target with zero manual overrides",
                icon: "checkmark.seal.fill",
                isUnlocked: false,
                category: .milestone
            ),
            Achievement(
                id: "veteran",
                title: "Veteran",
                description: "Complete 2 quarters successfully",
                icon: "medal.fill",
                isUnlocked: false,
                category: .milestone
            ),

            // Streak Achievements
            Achievement(
                id: "on_a_roll",
                title: "On a Roll",
                description: "5 consecutive office days",
                icon: "flame.fill",
                isUnlocked: false,
                category: .streak
            ),
            Achievement(
                id: "unstoppable",
                title: "Unstoppable",
                description: "10 consecutive office days",
                icon: "bolt.fill",
                isUnlocked: false,
                category: .streak
            ),

            // Consistency Achievements
            Achievement(
                id: "comeback_kid",
                title: "Comeback Kid",
                description: "Go from 'Behind' to 'On Track' status",
                icon: "arrow.turn.up.right",
                isUnlocked: false,
                category: .consistency
            )
        ]
    }
}
