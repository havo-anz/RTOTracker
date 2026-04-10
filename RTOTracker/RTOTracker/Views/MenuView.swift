import SwiftUI

struct MenuView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var officeDetectionService: OfficeDetectionService
    var onOpenSettings: () -> Void
    var onOpenCalendar: () -> Void

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
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.windowBackgroundColor))
        )
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
            let progress = dataManager.getCurrentQuarterProgress()

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

            // Tracking Status
            trackingStatusView

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
            // Primary actions
            Button(action: openCalendarWindow) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                    Text("View Calendar")
                        .font(.system(size: 13))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Button(action: openSettingsWindow) {
                HStack {
                    Image(systemName: "gear")
                        .font(.system(size: 13))
                    Text("Settings")
                        .font(.system(size: 13))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.vertical, 4)

            // Quit action
            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack {
                    Image(systemName: "power")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                    Text("Quit RTO Tracker")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
    }

    private func openSettingsWindow() {
        print("Opening settings")
        onOpenSettings()
    }

    private func openCalendarWindow() {
        print("Opening calendar")
        onOpenCalendar()
    }

    // MARK: - Views

    private var trackingStatusView: some View {
        let tracking = dataManager.getTrackingStatus()

        return HStack(spacing: 8) {
            Image(systemName: tracking.status.icon)
                .foregroundColor(statusColor(tracking.status))
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(tracking.status.displayText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor(tracking.status))

                Text("Expected: \(tracking.expectedDays) • Actual: \(tracking.actualDays)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(statusColor(tracking.status).opacity(0.1))
        .cornerRadius(8)
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

    private func statusColor(_ status: DataManager.TrackingStatus) -> Color {
        switch status {
        case .ahead:
            return .green
        case .onTrack:
            return .blue
        case .behind:
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
