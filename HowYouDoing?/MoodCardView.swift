//
//  MoodCardView.swift
//  HowYouDoing?
//

import SwiftUI

struct MoodCardView: View {
    let entry: MoodEntry
    let entries: [MoodEntry]

    var body: some View {
        HStack(spacing: 14) {
            Text(entry.moodState.emoji)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.moodState.displayString)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(entry.dateLabel(in: entries))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .glassEffect(.regular.tint(entry.moodState.color), in: .rect(cornerRadius: 14))
    }
}
