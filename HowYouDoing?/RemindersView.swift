//
//  RemindersView.swift
//  HowYouDoing?
//

import SwiftUI

struct RemindersView: View {
    @Binding var reminders: [Reminder]
    @State private var showAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reminders")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            ForEach(reminders) { reminder in
                ReminderRow(reminder: reminder) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        reminders.removeAll { $0.id == reminder.id }
                        NotificationManager.scheduleAll(reminders)
                    }
                }
            }

            Button {
                triggerHaptic()
                showAddSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Add Reminder")
                        .font(.body.weight(.semibold))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.glass(.regular.tint(.moodBlue)))
        }
        .sheet(isPresented: $showAddSheet) {
            AddReminderSheet { newReminder in
                reminders.append(newReminder)
                NotificationManager.scheduleAll(reminders)
            }
        }
    }
}

// MARK: - Reminder Row

private struct ReminderRow: View {
    let reminder: Reminder
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.timeString)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                Text(reminder.body)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                triggerHaptic()
                onDelete()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular.tint(.moodGreen), in: .rect(cornerRadius: 12))
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
            VStack(spacing: 24) {
                DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("Reminder text", text: $bodyText)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 20)

                Spacer()

                Button {
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
                } label: {
                    Text("Save Reminder")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.glass(.regular.tint(.moodGreen)))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
