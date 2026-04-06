import SwiftUI

struct MenuView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var officeDetectionService: OfficeDetectionService
    var onOpenSettings: () -> Void

    @State private var showingDetailView = false
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView

            Divider()

            // Progress Section
            progressView

            Divider()

            // Actions
            actionsView
        }
        .padding()
        .frame(width: 320)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RTO Tracker")
                .font(.headline)

            if officeDetectionService.isAtOffice {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("At office")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Circle()
                        .fill(.gray)
                        .frame(width: 8, height: 8)
                    Text("Not at office")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Today's status
            Text(todayStatusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var progressView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quarter progress
            var progress = dataManager.getCurrentQuarterProgress()

            HStack {
                Text("This Quarter")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(progress.confirmed)/\(progress.target) days")
                    .font(.headline)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(progressColor)
                        .frame(width: min(geometry.size.width * CGFloat(progress.confirmed) / CGFloat(progress.target), geometry.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)

            // Stats
            VStack(alignment: .leading, spacing: 4) {
                Text(daysRemainingText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(requiredPaceText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var actionsView: some View {
        VStack(spacing: 8) {
            Button("View Calendar") {
                openCalendarWindow()
            }
            .buttonStyle(.bordered)

            Button("Settings") {
                openSettingsWindow()
            }
            .buttonStyle(.bordered)

            Divider()

            Button("Quit RTO Tracker") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
    }

    private func openSettingsWindow() {
        print("Opening settings")
        onOpenSettings()
    }

    private func openCalendarWindow() {
        // TODO: Implement calendar view
        let alert = NSAlert()
        alert.messageText = "Calendar View"
        alert.informativeText = "Calendar view coming soon!"
        alert.alertStyle = .informational
        alert.runModal()
    }

    // MARK: - Computed Properties

    private var todayStatusText: String {
        let record = dataManager.getTodayRecord()
        if record.isConfirmed {
            if let checkinTime = record.firstCheckinTime {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Today: ✓ Confirmed (since \(formatter.string(from: checkinTime)))"
            }
            return "Today: ✓ Confirmed"
        } else {
            return "Today: Not checked in"
        }
    }

    private var progressColor: Color {
        let progress = dataManager.getCurrentQuarterProgress()
        let percentage = Double(progress.confirmed) / Double(progress.target)

        if percentage >= 0.8 {
            return .green
        } else if percentage >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    private var daysRemainingText: String {
        let progress = dataManager.getCurrentQuarterProgress()
        let daysNeeded = max(0, progress.target - progress.confirmed)
        let workdaysLeft = dataManager.getWorkdaysRemainingInQuarter()

        return "Need \(daysNeeded) more days • \(workdaysLeft) workdays left in quarter"
    }

    private var requiredPaceText: String {
        let progress = dataManager.getCurrentQuarterProgress()
        let daysNeeded = max(0, progress.target - progress.confirmed)
        let workdaysLeft = max(1, dataManager.getWorkdaysRemainingInQuarter())

        let weeksLeft = Double(workdaysLeft) / 5.0
        let daysPerWeek = weeksLeft > 0 ? Double(daysNeeded) / weeksLeft : 0

        return String(format: "Required pace: %.1f days/week", daysPerWeek)
    }
}
