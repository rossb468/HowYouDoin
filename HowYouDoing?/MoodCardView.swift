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
                    .foregroundStyle(.white)

                Text(entry.dateLabel(in: entries))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(entry.moodState.color)
        )
    }
}
