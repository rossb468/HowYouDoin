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
    @AppStorage("weekStartDay") private var weekStartDay: Int = 2

    @State private var showGraph = false

    private var sortedEntries: [MoodEntry] {
        moodEntries.sorted { $0.date < $1.date }
    }

    /// One point per mood entry, ordered oldest-first, for the mood-over-time graph.
    private var moodPoints: [MoodPoint] {
        sortedEntries.map {
            MoodPoint(id: $0.id, date: $0.date, value: $0.moodState.numericValue, mood: $0.moodState)
        }
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
                        weekOverWeekCard
                        moodDistributionChart
                        moodOverTimeChart
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
        .sheet(isPresented: $showGraph) {
            MoodGraphSheet(points: moodPoints)
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

    // MARK: - Week-over-Week Insight

    private var weekOverWeekCard: some View {
        let calendar = Calendar.current
        let now = Date()
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now)!

        let thisWeek = moodEntries.filter { $0.date > oneWeekAgo }
        let lastWeek = moodEntries.filter { $0.date > twoWeeksAgo && $0.date <= oneWeekAgo }

        let thisAvg = thisWeek.isEmpty ? 0 : thisWeek.map(\.moodState.numericValue).reduce(0, +) / Double(thisWeek.count)
        let lastAvg = lastWeek.isEmpty ? 0 : lastWeek.map(\.moodState.numericValue).reduce(0, +) / Double(lastWeek.count)
        let delta = thisAvg - lastAvg

        let hasComparison = !thisWeek.isEmpty && !lastWeek.isEmpty
        let arrow: String
        let arrowColor: Color
        let summary: String
        if !hasComparison {
            arrow = "minus.circle"
            arrowColor = .secondary
            summary = thisWeek.isEmpty ? "No entries this week" : "Not enough history yet"
        } else if abs(delta) < 0.15 {
            arrow = "equal.circle.fill"
            arrowColor = .moodBlue
            summary = "About the same as last week"
        } else if delta > 0 {
            arrow = "arrow.up.right.circle.fill"
            arrowColor = .moodGreen
            summary = String(format: "Up %.1f vs. last week", delta)
        } else {
            arrow = "arrow.down.right.circle.fill"
            arrowColor = .moodRed
            summary = String(format: "Down %.1f vs. last week", abs(delta))
        }

        return ChartCard(title: "This Week vs. Last Week") {
            HStack(spacing: 14) {
                Image(systemName: arrow)
                    .font(.system(size: 32))
                    .foregroundStyle(arrowColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(summary)
                        .font(.system(size: 15, weight: .semibold))
                    Text("\(thisWeek.count) entr\(thisWeek.count == 1 ? "y" : "ies") this week · \(lastWeek.count) last week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
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

    // MARK: - Mood Over Time

    private var moodOverTimeChart: some View {
        let points = moodPoints

        return ChartCard(title: "Mood Over Time") {
            if points.count < 2 {
                Text("Need at least 2 entries")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 180)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    MoodTimelineChart(points: points, visibleDays: 14)
                        .frame(height: 180)

                    Label("Tap to view full screen", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    triggerHaptic()
                    showGraph = true
                }
            }
        }
    }

    // MARK: - Day of Week

    private var dayOfWeekChart: some View {
        var calendar = Calendar.current
        calendar.firstWeekday = weekStartDay
        let shortSymbols = calendar.shortWeekdaySymbols

        let grouped = Dictionary(grouping: moodEntries) { entry in
            calendar.component(.weekday, from: entry.date)
        }

        // Render weekdays in the user's preferred week order.
        let orderedWeekdays = (0..<7).map { offset -> Int in
            ((weekStartDay - 1 + offset) % 7) + 1
        }

        let data: [DayCount] = orderedWeekdays.map { weekday in
            let entries = grouped[weekday] ?? []
            let avg = entries.isEmpty ? 0.0 : entries.map { $0.moodState.numericValue }.reduce(0.0, +) / Double(entries.count)
            return DayCount(day: shortSymbols[weekday - 1], count: entries.count, average: avg, weekday: weekday)
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
            .chartXScale(domain: data.map(\.day))
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

        // Grace day: if the user hasn't logged today yet but logged yesterday,
        // anchor the streak at yesterday so they don't lose it before midnight.
        var checkDate = today
        if let mostRecent = uniqueDays.first,
           mostRecent != today,
           mostRecent == calendar.date(byAdding: .day, value: -1, to: today) {
            checkDate = mostRecent
        }

        var currentStreak = 0
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

private struct MoodPoint: Identifiable {
    let id: PersistentIdentifier
    let date: Date
    let value: Double
    let mood: MoodState
}

private struct MoodSegment: Identifiable {
    let id: Int
    let start: MoodPoint
    let end: MoodPoint

    var endpoints: [MoodPoint] { [start, end] }

    /// Leading→trailing gradient (leading = earlier entry) through every mood
    /// color between the two endpoints. Same-color moods yield a solid line;
    /// endpoints two or more positions apart pass through each intermediate mood
    /// color (e.g. terrible→great runs terrible·bad·neutral·good·great).
    var gradient: LinearGradient {
        let startV = Int(start.value.rounded())
        let endV = Int(end.value.rounded())
        let sequence: [Int] = startV <= endV
            ? Array(startV...endV)
            : Array(stride(from: startV, through: endV, by: -1))
        let colors = sequence.map { MoodState.fromNumeric($0).color }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }
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

// MARK: - Mood Timeline Chart

/// A line-and-point graph of individual mood entries over time. Horizontally
/// scrollable; the visible window is capped at `visibleDays` so the graph only
/// scrolls when the data spans more time than fits on screen.
private struct MoodTimelineChart: View {
    let points: [MoodPoint]
    let visibleDays: Int

    /// Visible window in seconds, clamped to the data's span so short histories
    /// fill the width instead of being squeezed against the leading edge.
    private var visibleLength: TimeInterval {
        let requested = TimeInterval(visibleDays) * 86_400
        guard let first = points.first?.date, let last = points.last?.date else { return requested }
        let span = last.timeIntervalSince(first)
        return span > 0 ? min(requested, span) : requested
    }

    private var initialScrollX: Date {
        guard let last = points.last?.date else { return Date() }
        return last.addingTimeInterval(-visibleLength)
    }

    private var strideDays: Int {
        max(Int((visibleLength / 86_400).rounded()) / 6, 1)
    }

    /// Adjacent pairs of points, each drawn as its own line segment so it can be
    /// tinted independently.
    private var segments: [MoodSegment] {
        guard points.count > 1 else { return [] }
        return (0..<(points.count - 1)).map { i in
            MoodSegment(id: i, start: points[i], end: points[i + 1])
        }
    }

    var body: some View {
        Chart {
            // Each segment is its own series so it draws as an isolated line and
            // can carry its own color/gradient.
            ForEach(segments) { segment in
                ForEach(segment.endpoints) { node in
                    LineMark(
                        x: .value("Date", node.date),
                        y: .value("Mood", node.value),
                        series: .value("Segment", segment.id)
                    )
                    .interpolationMethod(.linear)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .foregroundStyle(segment.gradient)
                }
            }

            ForEach(points) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Mood", point.value)
                )
                .foregroundStyle(point.mood.color)
                .symbolSize(50)
            }
        }
        // Pad the vertical scale beyond 1...5 so the top and bottom lines aren't
        // flush against the plot edges.
        .chartYScale(domain: 0.5...5.5)
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
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: strideDays)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: visibleLength)
        .chartScrollPosition(initialX: initialScrollX)
    }
}

// MARK: - Full-Screen Graph (slide-up)

/// The mood-over-time graph presented as a slide-up sheet. The app stays locked
/// in portrait; the graph is rotated 90° and sized to the screen's swapped
/// dimensions so it reads as landscape when the device is turned sideways. The
/// sheet's drag indicator is the standard control for dismissing it.
private struct MoodGraphSheet: View {
    let points: [MoodPoint]

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 8) {
                Text("Mood Over Time")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))

                MoodTimelineChart(points: points, visibleDays: 30)
            }
            .padding(20)
            // Lay out at landscape dimensions (width/height swapped), then
            // rotate into the portrait sheet and re-center.
            .frame(width: geo.size.height, height: geo.size.width)
            .rotationEffect(.degrees(90))
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
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
        case ...1:  return .terrible
        case 2:     return .bad
        case 3:     return .neutral
        case 4:     return .good
        default:    return .great
        }
    }

    static func fromNumericDouble(_ value: Double) -> MoodState {
        let clamped = min(max(value, 1), 5)
        return fromNumeric(Int(clamped.rounded()))
    }
}
