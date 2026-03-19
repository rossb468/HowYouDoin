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

    @AppStorage("reminders") private var remindersJSON: String = "[]"

    private var remindersBinding: Binding<[Reminder]> {
        Binding(
            get: { [Reminder].fromJSON(remindersJSON) },
            set: { remindersJSON = $0.jsonString }
        )
    }

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
                }
                .buttonStyle(.glass(.regular.tint(.moodGreen)))
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
                        }
                        .buttonStyle(.glass(selectedTheme == theme ? .regular.tint(.moodBlue) : .regular))
                    }
                }
            }
            .padding(.bottom, 4)

            // Reminders
            RemindersView(reminders: remindersBinding)
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
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.glass(.regular.tint(.moodBlue)))

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
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.glass(.regular.tint(.moodRed)))
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
