//
//  SettingsView.swift
//  HowYouDoing?
//

import SwiftUI

struct SettingsView: View {
    @Binding var selectedTheme: AppTheme
    let onImportCSV: () -> Void
    let onDeleteAll: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

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

            // Appearance picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Appearance")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                HStack(spacing: 8) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Button {
                            triggerHaptic()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTheme = theme
                            }
                        } label: {
                            Text(theme.displayName)
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(selectedTheme == theme ? .white : .primary)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selectedTheme == theme ? Color.moodBlue : Color(.systemGray5))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
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
                .stroke(.primary.opacity(0.15), lineWidth: 1.5)
        )
    }
}
