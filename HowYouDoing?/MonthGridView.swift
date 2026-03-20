//
//  MonthGridView.swift
//  HowYouDoing?
//

import SwiftUI

/// Zoomed-out view showing mood entries as thin full-width color bars
/// with month dividers. All entries within a month blend into one solid block.
struct CompactTimelineView: View {
    let timelineRows: [TimelineRow]

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(timelineRows) { row in
                switch row {
                case .moodEntry(let entry, _, _, _):
                    Rectangle()
                        .fill(entry.moodState.color)
                        .frame(height: 12)
                        .padding(.horizontal, 16)

                case .monthDivider(let label, _):
                    MonthDividerView(label: label)
                        .padding(.vertical, 8)
                }
            }
        }
    }
}
