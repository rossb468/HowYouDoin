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
    case weekDivider(id: String)

    var id: String {
        switch self {
        case .moodEntry(let entry, _, _, _):
            return "entry-\(entry.id)"
        case .monthDivider(_, let id):
            return "month-\(id)"
        case .weekDivider(let id):
            return "week-\(id)"
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

        // Insert dividers between day groups
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
            } else {
                let currentWeek = calendar.component(.weekOfYear, from: dayStart)
                let nextWeek = calendar.component(.weekOfYear, from: nextDayStart)
                if currentWeek != nextWeek {
                    rows.append(.weekDivider(
                        id: "week-\(ISO8601DateFormatter().string(from: nextDayStart))"
                    ))
                }
            }
        }
    }

    return rows
}
