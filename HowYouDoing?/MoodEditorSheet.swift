//
//  MoodEditorSheet.swift
//  HowYouDoing?
//

import SwiftUI

struct MoodEditorSheet: View {
    @Bindable var entry: MoodEntry
    @Environment(\.dismiss) private var dismiss

    // Local copies so the user can adjust before implicitly saving
    // (SwiftData auto-persists on @Model mutations, so we work directly.)
    @State private var selectedMood: MoodState
    @State private var selectedDate: Date

    init(entry: MoodEntry) {
        self.entry = entry
        _selectedMood = State(initialValue: entry.moodState)
        _selectedDate = State(initialValue: entry.date)
    }

    var body: some View {
        NavigationStack {
            List {
                // Mood card preview
                Section {
                    previewCard
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                // Mood picker
                Section("Mood") {
                    moodPicker
                }

                // Date & time pickers
                Section("Date & Time") {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        "Time",
                        selection: $selectedDate,
                        displayedComponents: .hourAndMinute
                    )
                }
            }
            .navigationTitle("Edit Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        entry.moodState = selectedMood
                        entry.date = selectedDate
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground {
            Color.clear
                .glassEffect(.regular, in: .rect(cornerRadius: 24))
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        HStack(spacing: 12) {
            Text(selectedMood.emoji)
                .font(.system(size: 52))

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedMood.displayString)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)

                Text(formattedDate)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            VStack(spacing: 1) {
                Text(dayOfMonth)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Text(shortMonth)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .textCase(.uppercase)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(
            .regular.tint(selectedMood.color),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .animation(.default, value: selectedMood)
    }

    // MARK: - Mood Picker

    private var moodPicker: some View {
        HStack(spacing: 8) {
            ForEach([MoodState.great, .good, .neutral, .bad, .terrible], id: \.self) { mood in
                let isSelected = selectedMood == mood
                Button {
                    withAnimation(.default) {
                        selectedMood = mood
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(mood.emoji)
                            .font(.system(size: 28))
                        Text(mood.displayString)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(isSelected ? .white : mood.color)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSelected ? mood.color : mood.color.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(mood.color.opacity(isSelected ? 1 : 0.4), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Date Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter.string(from: selectedDate)
    }

    private var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: selectedDate)
    }

    private var shortMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: selectedDate)
    }
}
