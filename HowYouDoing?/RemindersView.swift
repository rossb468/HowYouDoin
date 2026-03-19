//
//  RemindersView.swift
//  HowYouDoing?
//

import SwiftUI

/// A Form section that displays reminders with swipe-to-delete and an add button.
struct RemindersSection: View {
    @Binding var reminders: [Reminder]
    @State private var showAddSheet = false

    var body: some View {
        Section("Reminders") {
            ForEach(reminders) { reminder in
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reminder.timeString)
                                .font(.body)
                            Text(reminder.body)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } icon: {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(Color.moodGreen)
                    }
                }
            }
            .onDelete { indexSet in
                triggerHaptic()
                reminders.remove(atOffsets: indexSet)
                NotificationManager.scheduleAll(reminders)
            }

            Button {
                triggerHaptic()
                showAddSheet = true
            } label: {
                Label("Add Reminder", systemImage: "plus.circle.fill")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddReminderSheet { newReminder in
                reminders.append(newReminder)
                NotificationManager.scheduleAll(reminders)
            }
        }
    }
}

// MARK: - Add Reminder Sheet

private struct AddReminderSheet: View {
    let onSave: (Reminder) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTime = {
        var components = DateComponents()
        components.hour = 12
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var bodyText = "Time to check in with yourself."

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }

                Section {
                    TextField("Message", text: $bodyText)
                }
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        triggerHaptic()
                        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                        let reminder = Reminder(
                            hour: components.hour ?? 12,
                            minute: components.minute ?? 0,
                            title: "How You Doin'?",
                            body: bodyText.isEmpty ? "Time to check in with yourself." : bodyText
                        )
                        onSave(reminder)
                        dismiss()
                    }
                }
            }
        }
    }
}
