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
    /// The color of the next entry below this one (for blending).
    let nextColor: Color?

    // Inline journal-note editing (used from the history list). Defaulted so
    // read-only usages (e.g. the CSV preview) don't need to supply them.
    var isEditingNote: Bool = false
    var onNoteDone: (String) -> Void = { _ in }
    var onNoteCancel: () -> Void = {}

    @FocusState private var noteFieldFocused: Bool
    // Draft kept local so typing only re-renders this row, not the whole list.
    @State private var draft: String = ""

    private let cornerRadius: CGFloat = 20

    private var shape: UnevenRoundedRectangle {
        switch position {
        case .sole:
            UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius, bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius, topTrailingRadius: cornerRadius,
                style: .continuous)
        case .first:
            UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: cornerRadius,
                style: .continuous)
        case .middle:
            UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 0,
                style: .continuous)
        case .last:
            UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius, topTrailingRadius: 0,
                style: .continuous)
        }
    }

    private var showTime: Bool {
        position != .sole
    }

    /// Show the day-of-week as a header row above the content (multi-entry groups only)
    private var showGroupHeader: Bool {
        position == .first
    }

    /// Show the day-of-week inline next to the mood text (sole entries only)
    private var showInlineDay: Bool {
        position == .sole
    }

    private var showNoteArea: Bool {
        isEditingNote || !entry.note.isEmpty
    }

    /// Inline note editor while editing; a truncated preview otherwise.
    @ViewBuilder
    private var noteArea: some View {
        if isEditingNote {
            VStack(alignment: .leading, spacing: 8) {
                // A vertically-growing field: starts compact and expands (up to
                // ~6 lines / 140+ characters) as the note is written.
                TextField("Add a note…", text: $draft, axis: .vertical)
                    .lineLimit(1...6)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .focused($noteFieldFocused)

                HStack {
                    Button("Cancel", action: onNoteCancel)
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Button("Done") { onNoteDone(draft) }
                        .buttonStyle(.plain)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .font(.system(size: 15))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .onAppear {
                draft = entry.note
                noteFieldFocused = true
            }
            .onChange(of: isEditingNote) { _, editing in
                if editing {
                    draft = entry.note
                    noteFieldFocused = true
                }
            }
        } else if !entry.note.isEmpty {
            Text(entry.note)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day-of-week header — only on first entry of a multi-entry group
            if showGroupHeader {
                Text(entry.dayOfWeekLabel)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
            }

            HStack(spacing: 12) {
                // Emoji sized to full row height
                Text(entry.moodState.emoji)
                    .font(.system(size: 52))
                    .frame(maxHeight: .infinity)

                // Day (sole only) + mood + optional time stacked vertically
                VStack(alignment: .leading, spacing: 2) {
                    if showInlineDay {
                        Text(entry.dayOfWeekLabel)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Text(entry.moodState.displayString)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)

                    if showTime {
                        Text(entry.timeLabel)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                // Date number + month on the right
                VStack(spacing: 1) {
                    Text(entry.dayOfMonthLabel)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(entry.shortMonthLabel)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .textCase(.uppercase)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, showGroupHeader ? 2 : 8)
            .padding(.bottom, showNoteArea ? 4 : 10)

            // Journal note: inline editor while editing, otherwise a preview.
            noteArea

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
                .foregroundStyle(Color.themeTextOnBackground)
                .fixedSize()
            line
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var line: some View {
        Rectangle()
            .fill(Color.themeTextOnBackground.opacity(0.3))
            .frame(height: 1)
    }
}
