//
//  MonthGridView.swift
//  HowYouDoing?
//

import SwiftUI

/// Zoomed-out view showing mood entries as thin full-width color bars
/// with month dividers. No text — just the mood color.
struct CompactTimelineView: View {
    let timelineRows: [TimelineRow]

    var body: some View {
        LazyVStack(spacing: 2) {
            ForEach(timelineRows) { row in
                switch row {
                case .moodEntry(let entry, let position, _, _):
                    RoundedRectangle(cornerRadius: 4)
                        .fill(entry.moodState.color)
                        .frame(height: 12)
                        .opacity(0.85)
                        .padding(.horizontal, 16)
                        .padding(.top, position == .sole || position == .first ? 4 : 0)
                        .padding(.bottom, position == .sole || position == .last ? 4 : 0)

                case .monthDivider(let label, _):
                    MonthDividerView(label: label)
                        .padding(.vertical, 4)
                }
            }
        }
    }
}
