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


