//
//  SettingsView.swift
//  HowYouDoing?
//

import SwiftUI

struct SettingsView: View {
    let onImportCSV: () -> Void
    let onDeleteAll: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2.bold())
                    .foregroundStyle(.black)

                Spacer()

                Button {
                    triggerHaptic()
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.moodGreen)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)

            // Import from CSV
            Button {
                triggerHaptic()
                onImportCSV()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 20))
                    Text("Import from CSV")
                        .font(.body.weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.moodBlue)
                )
            }
            .buttonStyle(.plain)

            // Delete All Moods
            Button {
                triggerHaptic()
                onDeleteAll()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                    Text("Delete All Moods")
                        .font(.body.weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.moodRed)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1.5)
        )
    }
}
