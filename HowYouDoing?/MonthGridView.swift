//
//  MonthGridView.swift
//  HowYouDoing?
//

import SwiftUI

// Cached formatter — DateFormatter initialization is expensive.
private let overviewMonthFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMMM yyyy"
    return f
}()

/// Zoomed-out view showing mood entries as thin full-width color bars
/// with a month label at the top of each month. All entries within a month
/// read as a stack of color bars beneath their month header.
struct CompactTimelineView: View {
    let timelineRows: [TimelineRow]

    private let tileHeight: CGFloat = 12
    /// Match the card corner radius, but cap at half the tile height to avoid
    /// a curve taller than the tile (creates a rounded/capsule end instead).
    private var tileCornerRadius: CGFloat {
        min(20, tileHeight / 2)
    }

    /// A row for display: either a month header (shown at the top of a month)
    /// or a single entry's color bar.
    private enum OverviewRow: Identifiable {
        case header(label: String, id: String)
        case bar(entry: MoodEntry)

        var id: String {
            switch self {
            case .header(_, let id):  return "header-\(id)"
            case .bar(let entry):     return "bar-\(entry.id)"
            }
        }
    }

    /// Rebuilds the timeline for the overview, placing each month's label above
    /// its first (newest) entry and dropping the between-months dividers that
    /// the main history list uses.
    private var overviewRows: [OverviewRow] {
        let calendar = Calendar.current
        var result: [OverviewRow] = []
        var lastMonthKey: String?

        for row in timelineRows {
            guard case .moodEntry(let entry, _, _) = row else { continue }

            let components = calendar.dateComponents([.year, .month], from: entry.date)
            let key = "\(components.year ?? 0)-\(components.month ?? 0)"
            if key != lastMonthKey {
                result.append(.header(label: overviewMonthFormatter.string(from: entry.date), id: key))
                lastMonthKey = key
            }
            result.append(.bar(entry: entry))
        }

        return result
    }

    var body: some View {
        LazyVStack(spacing: 5) {
            ForEach(overviewRows) { row in
                switch row {
                case .header(let label, _):
                    MonthDividerView(label: label)
                        .padding(.vertical, 8)

                case .bar(let entry):
                    RoundedRectangle(cornerRadius: tileCornerRadius, style: .continuous)
                        .fill(entry.moodState.color)
                        .frame(height: tileHeight)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}
