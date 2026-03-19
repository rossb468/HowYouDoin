//
//  RemindersView.swift
//  HowYouDoing?
//

import SwiftUI

/// A Form section that displays reminders with swipe-to-delete, tap-to-edit, and an add button.
struct RemindersSection: View {
    @Binding var reminders: [Reminder]
    @State private var showAddSheet = false
    @State private var editingReminder: Reminder?

    var body: some View {
        Section("Reminders") {
            ForEach(reminders) { reminder in
                HStack(spacing: 12) {
                    Image(systemName: reminder.isEnabled ? "bell.fill" : "bell.slash.fill")
                        .foregroundStyle(reminder.isEnabled ? Color.moodGreen : .secondary)
                        .font(.system(size: 16))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(reminder.timeString)
                            .font(.body)
                        Text(reminder.body)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    triggerHaptic()
                    editingReminder = reminder
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
            ReminderEditorSheet(mode: .add) { newReminder in
                reminders.append(newReminder)
                NotificationManager.scheduleAll(reminders)
            }
        }
        .sheet(item: $editingReminder) { reminder in
            ReminderEditorSheet(mode: .edit(reminder)) { updated in
                if let index = reminders.firstIndex(where: { $0.id == updated.id }) {
                    reminders[index] = updated
                    NotificationManager.scheduleAll(reminders)
                }
            }
        }
    }
}


