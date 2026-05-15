import SwiftUI

struct AchievementsView: View {
    @ObservedObject var achievementManager: AchievementManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView
                .padding()

            Divider()

            // Achievement Grid
            ScrollView {
                VStack(spacing: 24) {
                    achievementSection(
                        title: "Milestones",
                        category: .milestone,
                        description: "Major progress achievements"
                    )

                    achievementSection(
                        title: "Streaks",
                        category: .streak,
                        description: "Consecutive day challenges"
                    )

                    achievementSection(
                        title: "Consistency",
                        category: .consistency,
                        description: "Stay on track rewards"
                    )
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title)
                    .foregroundColor(.yellow)

                Text("Achievements")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                // Progress badge
                HStack(spacing: 4) {
                    Text("\(achievementManager.unlockedCount)")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    Text("/ \(achievementManager.totalCount)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
            }

            Text("Unlock achievements by tracking your office days")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func achievementSection(title: String, category: Achievement.AchievementCategory, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(achievementManager.achievementsByCategory(category)) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
        }
    }
}

struct AchievementCard: View {
    var achievement: Achievement

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.icon)
                    .font(.system(size: 28))
                    .foregroundColor(achievement.isUnlocked ? .accentColor : .gray)
            }

            // Title and description
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)

                Text(achievement.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            // Unlocked date
            if achievement.isUnlocked, let unlockedDate = achievement.unlockedDate {
                Text(formatDate(unlockedDate))
                    .font(.caption2)
                    .foregroundColor(.green)
            } else {
                Text("Locked")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.isUnlocked ? Color(NSColor.controlBackgroundColor) : Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.isUnlocked ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Unlocked \(formatter.string(from: date))"
    }
}

#Preview {
    var manager = AchievementManager()
    manager.achievements[0].isUnlocked = true
    manager.achievements[0].unlockedDate = Date()
    return AchievementsView(achievementManager: manager)
}
