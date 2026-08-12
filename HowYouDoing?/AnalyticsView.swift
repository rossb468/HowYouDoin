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
                            .foregroundStyle(Color.themeTextOnFieldSecondary)
                    )
                    .foregroundStyle(Color.themeTextOnField)
                    .padding(.top, 60)
                } else {
                    VStack(spacing: 20) {
                        moodDistributionChart
                        moodOverTimeChart
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground.ignoresSafeArea())
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
                    .foregroundStyle(Color.themeTextOnFieldSecondary)
                    .frame(height: 180)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    MoodTimelineChart(points: points, visibleDays: 14)
                        .frame(height: 180)

                    Label("Tap to view full screen", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.caption2)
                        .foregroundStyle(Color.themeTextOnFieldSecondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    triggerHaptic()
                    showGraph = true
                }
            }
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
                    .foregroundStyle(Color.themeTextOnBackground)

                MoodTimelineChart(points: points, visibleDays: 30)
            }
            .padding(20)
            // Lay out at landscape dimensions (width/height swapped), then
            // rotate into the portrait sheet and re-center.
            .frame(width: geo.size.height, height: geo.size.width)
            .rotationEffect(.degrees(90))
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Reusable Components

private struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.themeTextOnField)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.themeGroupedBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
}
