//
//  MoodCardView.swift
//  HowYouDoing?
//

import SwiftUI

// MARK: - Entry Position in a Day Group

enum EntryPosition {
    case sole       // only entry that day
    case first      // newest entry (top of group)
    case middle
    case last       // oldest entry (bottom of group)
}

// MARK: - Mood Entry Row (used inside grouped cards)

struct MoodEntryRow: View {
    let entry: MoodEntry
    let position: EntryPosition
    let dayLabel: String
    /// The color of the next entry below this one (for blending).
    let nextColor: Color?

    private let cornerRadius: CGFloat = 14

    private var shape: UnevenRoundedRectangle {
        switch position {
        case .sole:
            return UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius, bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius, topTrailingRadius: cornerRadius)
        case .first:
            return UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: cornerRadius)
        case .middle:
            return UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 0)
        case .last:
            return UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius, topTrailingRadius: 0)
        }
    }

    private var showDate: Bool {
        position == .sole || position == .first
    }

    private var showTime: Bool {
        position != .sole
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date header for first/sole entry
            if showDate {
                Text(dayLabel)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, position == .sole ? 0 : 6)
            }

            // Mood content
            HStack(spacing: 14) {
                Text(entry.moodState.emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.moodState.displayString)
                        .font(.headline)
                        .foregroundStyle(.white)

                    if showTime {
                        Text(entry.timeLabel)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, showDate ? 4 : 10)
            .padding(.bottom, 14)

            // Color blend gradient at the bottom edge for non-last entries
            if let nextColor, position == .first || position == .middle {
                LinearGradient(
                    colors: [entry.moodState.color, nextColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 4)
                .opacity(0.5)
            }
        }
        .glassEffect(.regular.tint(entry.moodState.color), in: shape)
    }
}

// MARK: - Month Divider

struct MonthDividerView: View {
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            line
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize()
            line
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var line: some View {
        Rectangle()
            .fill(.secondary.opacity(0.3))
            .frame(height: 1)
    }
}

// MARK: - Week Divider

struct WeekDividerView: View {
    var body: some View {
        Rectangle()
            .fill(.secondary.opacity(0.15))
            .frame(height: 0.5)
            .padding(.horizontal, 48)
            .padding(.vertical, 4)
    }
}
