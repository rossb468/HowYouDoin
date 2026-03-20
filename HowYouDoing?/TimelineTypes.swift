//
//  TimelineTypes.swift
//  HowYouDoing?
//

import SwiftUI

// MARK: - Timeline Row

/// A single flat row in the mood timeline list. Each entry is its own row
/// so that native List swipe actions work on every mood entry.
enum TimelineRow: Identifiable {
    case moodEntry(
        entry: MoodEntry,
        position: EntryPosition,
        dayLabel: String,
        nextColor: Color?
    )
    case monthDivider(label: String, id: String)

    var id: String {
        switch self {
        case .moodEntry(let entry, _, _, _):
            return "entry-\(entry.id)"
        case .monthDivider(_, let id):
            return "month-\(id)"
        }
    }
}

// MARK: - Timeline Builder

/// Groups mood entries by day, flattens them into individual rows with
/// position metadata, and inserts month/week dividers between day groups.
func buildTimeline(from entries: [MoodEntry], weekStartDay: Int) -> [TimelineRow] {
    guard !entries.isEmpty else { return [] }

    var calendar = Calendar.current
    calendar.firstWeekday = weekStartDay

    // Group entries by calendar day
    let grouped = Dictionary(grouping: entries) { entry in
        calendar.startOfDay(for: entry.date)
    }

    // Sort days newest-first, entries within each day newest-first
    let dayStarts = grouped.keys.sorted(by: >)

    var rows: [TimelineRow] = []
    let monthFormatter = DateFormatter()
    monthFormatter.dateFormat = "MMMM yyyy"

    for (dayIndex, dayStart) in dayStarts.enumerated() {
        let dayEntries = grouped[dayStart]!.sorted { $0.date > $1.date }
        let dayLabel = MoodEntry.dayLabel(for: dayStart)

        // Emit each entry as its own row with position metadata
        for (entryIndex, entry) in dayEntries.enumerated() {
            let position: EntryPosition
            if dayEntries.count == 1 {
                position = .sole
            } else if entryIndex == 0 {
                position = .first
            } else if entryIndex == dayEntries.count - 1 {
                position = .last
            } else {
                position = .middle
            }

            let nextColor: Color? = (entryIndex < dayEntries.count - 1)
                ? dayEntries[entryIndex + 1].moodState.color
                : nil

            rows.append(.moodEntry(
                entry: entry,
                position: position,
                dayLabel: dayLabel,
                nextColor: nextColor
            ))
        }

        // Insert month divider between day groups at month boundaries
        if dayIndex < dayStarts.count - 1 {
            let nextDayStart = dayStarts[dayIndex + 1]
            let currentMonth = calendar.component(.month, from: dayStart)
            let nextMonth = calendar.component(.month, from: nextDayStart)
            let currentYear = calendar.component(.year, from: dayStart)
            let nextYear = calendar.component(.year, from: nextDayStart)

            if currentMonth != nextMonth || currentYear != nextYear {
                let label = monthFormatter.string(from: nextDayStart)
                rows.append(.monthDivider(
                    label: label,
                    id: "\(nextYear)-\(nextMonth)"
                ))
            }
        }
    }

    return rows
}

// MARK: - Month Grid (Zoomed-Out View)

/// Represents one month in the zoomed-out calendar grid.
struct MonthGridSection: Identifiable {
    let id: String              // e.g. "2026-03"
    let title: String           // e.g. "March 2026"
    let year: Int
    let month: Int
    let firstWeekday: Int       // weekday of day 1 (1=Sun..7=Sat)
    let numberOfDays: Int
    let dayColors: [Int: Color] // day-of-month -> blended mood color
}

/// Builds month grid sections from mood entries, sorted newest-first.
func buildMonthGrid(
    from entries: [MoodEntry],
    weekStartDay: Int,
    environment: EnvironmentValues
) -> [MonthGridSection] {
    guard !entries.isEmpty else { return [] }

    var calendar = Calendar.current
    calendar.firstWeekday = weekStartDay

    // Group entries by (year, month)
    let grouped = Dictionary(grouping: entries) { entry -> DateComponents in
        calendar.dateComponents([.year, .month], from: entry.date)
    }

    let monthFormatter = DateFormatter()
    monthFormatter.dateFormat = "MMMM yyyy"

    // Sort months newest-first
    let sortedKeys = grouped.keys.sorted { a, b in
        if a.year! != b.year! { return a.year! > b.year! }
        return a.month! > b.month!
    }

    return sortedKeys.map { key in
        let year = key.year!
        let month = key.month!
        let monthEntries = grouped[key]!

        // Group by day-of-month and blend colors
        let byDay = Dictionary(grouping: monthEntries) { entry in
            calendar.component(.day, from: entry.date)
        }

        var dayColors: [Int: Color] = [:]
        for (day, dayEntries) in byDay {
            dayColors[day] = blendColors(dayEntries.map(\.moodState.color), in: environment)
        }

        // Calculate grid metadata
        let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!

        return MonthGridSection(
            id: "\(year)-\(month)",
            title: monthFormatter.string(from: firstOfMonth),
            year: year,
            month: month,
            firstWeekday: firstWeekday,
            numberOfDays: range.count,
            dayColors: dayColors
        )
    }
}

/// Averages the resolved RGBA components of multiple colors.
func blendColors(_ colors: [Color], in environment: EnvironmentValues) -> Color {
    guard !colors.isEmpty else { return .clear }
    guard colors.count > 1 else { return colors[0] }

    let resolved = colors.map { $0.resolve(in: environment) }
    let count = Float(resolved.count)
    let r = resolved.map(\.red).reduce(0, +) / count
    let g = resolved.map(\.green).reduce(0, +) / count
    let b = resolved.map(\.blue).reduce(0, +) / count

    return Color(red: Double(r), green: Double(g), blue: Double(b))
}
