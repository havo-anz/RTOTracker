import SwiftUI

struct CalendarView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedMonth = Date()
    @State private var selectedDate: Date?

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday = 2, Sunday = 1
        return cal
    }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with month navigation
            headerView

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Current quarter summary
                    quarterSummaryView

                    Divider()

                    // Monthly calendar
                    monthlyCalendarView
                        .padding(.horizontal, 20)

                    Divider()

                    // Legend
                    legendView
                }
                .padding()
            }
        }
        .frame(minWidth: 750, idealWidth: 800, minHeight: 650, idealHeight: 700)
    }

    private var headerView: some View {
        HStack {
            Text("RTO Calendar")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            // Month navigation
            HStack(spacing: 16) {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Text(monthYearString)
                    .font(.headline)
                    .frame(width: 180)

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button("Today") {
                selectedMonth = Date()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var quarterSummaryView: some View {
        let progress = dataManager.getCurrentQuarterProgress()
        let (startDate, endDate) = dataManager.getQuarterDates(for: Date())
        let tracking = dataManager.getTrackingStatus()

        return VStack(spacing: 16) {
            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Quarter Progress")
                        .font(.headline)

                    Text("\(progress.confirmed)/\(progress.target) days")
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text(quarterDateRangeString(startDate, endDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: min(Double(progress.confirmed) / Double(progress.target), 1.0))
                    .stroke(progressColor(progress), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                Text("\(Int((Double(progress.confirmed) / Double(progress.target)) * 100))%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            }

            // Tracking Status Badge
            HStack(spacing: 10) {
                Image(systemName: tracking.status.icon)
                    .foregroundColor(trackingStatusColor(tracking.status))
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tracking.status.displayText)
                        .font(.headline)
                        .foregroundColor(trackingStatusColor(tracking.status))

                    Text("Expected by today: \(tracking.expectedDays) days • Actual: \(tracking.actualDays) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(16)
            .background(trackingStatusColor(tracking.status).opacity(0.15))
            .cornerRadius(10)
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var monthlyCalendarView: some View {
        VStack(spacing: 16) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar days
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(getDaysInMonth().enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        dayCell(for: date)
                    } else {
                        Color.clear
                            .frame(height: 60)
                    }
                }
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let record = dataManager.dayRecords.first { calendar.isDate($0.date, inSameDayAs: date) }
        let isToday = calendar.isDateInToday(date)
        let isCurrentMonth = calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)
        let isSelected = selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!)

        return Button(action: {
            selectedDate = date
            toggleDayConfirmation(for: date)
        }) {
            VStack(spacing: 6) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 18, weight: isToday ? .bold : .regular, design: .rounded))
                    .foregroundColor(isCurrentMonth ? .primary : .secondary.opacity(0.5))

                // Indicator dot
                if let record = record, record.isConfirmed {
                    Circle()
                        .fill(record.isManualOverride ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isToday ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var legendView: some View {
        HStack(spacing: 32) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                Text("Office Day (Auto)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 12, height: 12)
                Text("Office Day (Manual)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("💡 Click a day to toggle manually")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(.horizontal)
    }

    // MARK: - Helper Functions

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        // Rearrange to start with Monday: [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
        return Array(symbols[1...]) + [symbols[0]]
    }

    private func getDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var currentDate = monthFirstWeek.start

        // Loop through all days in the month grid (usually 35 or 42 days)
        while days.count < 42 {
            if currentDate >= monthInterval.start && currentDate < monthInterval.end {
                days.append(currentDate)
            } else {
                days.append(nil)
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate

            // Stop if we've gone past the month and filled at least 5 weeks
            if currentDate >= monthInterval.end && days.count >= 35 {
                break
            }
        }

        return days
    }

    private func toggleDayConfirmation(for date: Date) {
        dataManager.toggleDayConfirmation(for: date)
    }

    private func previousMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
    }

    private func nextMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private func quarterDateRangeString(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    private func progressColor(_ progress: (confirmed: Int, target: Int)) -> Color {
        let percentage = Double(progress.confirmed) / Double(progress.target)
        if percentage >= 0.8 {
            return .green
        } else if percentage >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    private func trackingStatusColor(_ status: DataManager.TrackingStatus) -> Color {
        switch status {
        case .ahead:
            return .green
        case .onTrack:
            return .blue
        case .behind:
            return .red
        }
    }
}
