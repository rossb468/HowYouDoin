//
//  AnalyticsView.swift
//  HowYouDoing?
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]
    @Environment(\.dismiss) private var dismiss

    private var sortedEntries: [MoodEntry] {
        moodEntries.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if moodEntries.isEmpty {
                    ContentUnavailableView(
                        "No Mood Data",
                        systemImage: "chart.bar",
                        description: Text("Start logging moods to see your analytics.")
                    )
                    .padding(.top, 60)
                } else {
                    VStack(spacing: 20) {
                        summaryCards
                        moodDistributionChart
                        weeklyTrendChart
                        dayOfWeekChart
                        timeOfDayChart
                        streakCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        let total = moodEntries.count
        let avgScore = moodEntries.map { $0.moodState.numericValue }.reduce(0.0, +) / max(Double(total), 1)
        let mostCommon = mostCommonMood

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(title: "Total Entries", value: "\(total)", icon: "number")
                StatCard(title: "Avg Mood", value: String(format: "%.1f", avgScore), icon: "gauge.with.needle")
            }
            HStack(spacing: 12) {
                StatCard(title: "Most Common", value: "\(mostCommon.emoji) \(mostCommon.displayString)", icon: "star")
                StatCard(title: "Days Tracked", value: "\(uniqueDaysCount)", icon: "calendar")
            }
        }
    }

    private var mostCommonMood: MoodState {
        let counts = Dictionary(grouping: moodEntries, by: \.moodState)
        return counts.max(by: { $0.value.count < $1.value.count })?.key ?? .neutral
    }

    private var uniqueDaysCount: Int {
        let calendar = Calendar.current
        let days = Set(moodEntries.map { calendar.startOfDay(for: $0.date) })
        return days.count
    }

    // MARK: - Mood Distribution

    private var moodDistributionChart: some View {
        let counts = Dictionary(grouping: moodEntries, by: \.moodState)
            .map { MoodCount(mood: $0.key, count: $0.value.count) }
            .sorted { $0.mood.sortOrder < $1.mood.sortOrder }

        return ChartCard(title: "Mood Distribution") {
            Chart(counts) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(item.mood.color)
                .annotation(position: .overlay) {
                    if item.count > 0 {
                        Text(item.mood.emoji)
                            .font(.system(size: 18))
                    }
                }
            }
            .frame(height: 200)
        }
    }

    // MARK: - Weekly Trend (last 8 weeks)

    private var weeklyTrendChart: some View {
        let calendar = Calendar.current
        let now = Date()
        let eightWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -8, to: now)!
        let recent = sortedEntries.filter { $0.date >= eightWeeksAgo }

        let weeklyAverages: [WeekAverage] = {
            let grouped = Dictionary(grouping: recent) { entry in
                calendar.dateInterval(of: .weekOfYear, for: entry.date)?.start ?? entry.date
            }
            return grouped.map { weekStart, entries in
                let avg = entries.map { $0.moodState.numericValue }.reduce(0.0, +) / Double(entries.count)
                return WeekAverage(weekStart: weekStart, average: avg)
            }
            .sorted { $0.weekStart < $1.weekStart }
        }()

        return ChartCard(title: "Weekly Mood Trend") {
            if weeklyAverages.count < 2 {
                Text("Need at least 2 weeks of data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 180)
            } else {
                Chart(weeklyAverages) { week in
                    LineMark(
                        x: .value("Week", week.weekStart, unit: .weekOfYear),
                        y: .value("Avg", week.average)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.moodBlue)

                    AreaMark(
                        x: .value("Week", week.weekStart, unit: .weekOfYear),
                        y: .value("Avg", week.average)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.moodBlue.opacity(0.15))

                    PointMark(
                        x: .value("Week", week.weekStart, unit: .weekOfYear),
                        y: .value("Avg", week.average)
                    )
                    .foregroundStyle(Color.moodBlue)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(MoodState.fromNumeric(v).emoji)
                                    .font(.system(size: 12))
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
    }

    // MARK: - Day of Week

    private var dayOfWeekChart: some View {
        let calendar = Calendar.current
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        let grouped = Dictionary(grouping: moodEntries) { entry in
            calendar.component(.weekday, from: entry.date)
        }

        let data: [DayCount] = (1...7).map { weekday in
            let entries = grouped[weekday] ?? []
            let avg = entries.isEmpty ? 0.0 : entries.map { $0.moodState.numericValue }.reduce(0.0, +) / Double(entries.count)
            return DayCount(day: dayNames[weekday - 1], count: entries.count, average: avg, weekday: weekday)
        }

        return ChartCard(title: "By Day of Week") {
            Chart(data) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Entries", item.count)
                )
                .foregroundStyle(item.average > 0 ? MoodState.fromNumericDouble(item.average).color.opacity(0.8) : .gray.opacity(0.3))
                .cornerRadius(6)
            }
            .frame(height: 160)
        }
    }

    // MARK: - Time of Day

    private var timeOfDayChart: some View {
        let calendar = Calendar.current

        let hourBuckets: [HourBucket] = {
            let grouped = Dictionary(grouping: moodEntries) { entry in
                calendar.component(.hour, from: entry.date)
            }
            return (0..<24).map { hour in
                let label: String
                if hour == 0 { label = "12a" }
                else if hour < 12 { label = "\(hour)a" }
                else if hour == 12 { label = "12p" }
                else { label = "\(hour - 12)p" }
                return HourBucket(hour: hour, label: label, count: grouped[hour]?.count ?? 0)
            }
        }()

        return ChartCard(title: "Time of Day") {
            Chart(hourBuckets) { bucket in
                BarMark(
                    x: .value("Hour", bucket.label),
                    y: .value("Count", bucket.count)
                )
                .foregroundStyle(Color.moodBlue.opacity(0.7))
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 1)) { value in
                    if let label = value.as(String.self),
                       ["12a", "6a", "12p", "6p"].contains(label) {
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
            }
            .frame(height: 140)
        }
    }

    // MARK: - Streak

    private var streakCard: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let uniqueDays = Set(moodEntries.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)

        var currentStreak = 0
        var checkDate = today
        for day in uniqueDays {
            if day == checkDate {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if day < checkDate {
                break
            }
        }

        var longestStreak = 0
        var tempStreak = 0
        var tempCheck: Date?
        for day in uniqueDays.reversed() {
            if let check = tempCheck {
                if day == calendar.date(byAdding: .day, value: 1, to: check) {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            tempCheck = day
        }
        longestStreak = max(longestStreak, tempStreak)

        return HStack(spacing: 12) {
            StatCard(title: "Current Streak", value: "\(currentStreak) day\(currentStreak == 1 ? "" : "s")", icon: "flame")
            StatCard(title: "Longest Streak", value: "\(longestStreak) day\(longestStreak == 1 ? "" : "s")", icon: "trophy")
        }
    }
}

// MARK: - Supporting Types

private struct MoodCount: Identifiable {
    let mood: MoodState
    let count: Int
    var id: String { mood.rawValue }
}

private struct WeekAverage: Identifiable {
    let weekStart: Date
    let average: Double
    var id: Date { weekStart }
}

private struct DayCount: Identifiable {
    let day: String
    let count: Int
    let average: Double
    let weekday: Int
    var id: String { day }
}

private struct HourBucket: Identifiable {
    let hour: Int
    let label: String
    let count: Int
    var id: Int { hour }
}

// MARK: - Reusable Components

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - MoodState Helpers

extension MoodState {
    var numericValue: Double {
        switch self {
        case .terrible: return 1
        case .bad:      return 2
        case .neutral:  return 3
        case .good:     return 4
        case .great:    return 5
        }
    }

    var sortOrder: Int {
        switch self {
        case .great:    return 0
        case .good:     return 1
        case .neutral:  return 2
        case .bad:      return 3
        case .terrible: return 4
        }
    }

    static func fromNumeric(_ value: Int) -> MoodState {
        switch value {
        case 1: return .terrible
        case 2: return .bad
        case 3: return .neutral
        case 4: return .good
        default: return .great
        }
    }

    static func fromNumericDouble(_ value: Double) -> MoodState {
        fromNumeric(Int(value.rounded()))
    }
}
