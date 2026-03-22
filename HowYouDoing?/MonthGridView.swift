//
//  MonthGridView.swift
//  HowYouDoing?
//

import SwiftUI

/// Zoomed-out view showing mood entries as thin full-width color bars
/// with month dividers. All entries within a month blend into one solid block.
struct CompactTimelineView: View {
    let timelineRows: [TimelineRow]

    private let tileHeight: CGFloat = 12
    /// Match the card corner radius, but cap at half the tile height to avoid
    /// a curve taller than the tile (creates a rounded/capsule end instead).
    private var tileCornerRadius: CGFloat {
        min(20, tileHeight / 2)
    }

    var body: some View {
        LazyVStack(spacing: 5) {
            ForEach(timelineRows) { row in
                switch row {
                case .moodEntry(let entry, _, _, _):
                    RoundedRectangle(cornerRadius: tileCornerRadius, style: .continuous)
                        .fill(entry.moodState.color)
                        .frame(height: tileHeight)
                        .padding(.horizontal, 16)

                case .monthDivider(let label, _):
                    MonthDividerView(label: label)
                        .padding(.vertical, 8)
                }
            }
        }
    }
}
