//
//  SettingsView.swift
//  HowYouDoing?
//

import SwiftUI

/// Inline settings content designed to be embedded above the main content
/// in a ScrollView. The user reveals it by pulling down from the top.
struct InlineSettingsContent: View {
    let onImportCSV: () -> Void
    let onDeleteAll: () -> Void

    @AppStorage("reminders") private var remindersJSON: String = "[]"

    private var reminders: Binding<[Reminder]> {
        Binding(
            get: { [Reminder].fromJSON(remindersJSON) },
            set: { remindersJSON = $0.jsonString }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Pull indicator
            Capsule()
                .fill(.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Text("Settings")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16)

            // Reminders section
            InlineRemindersSection(reminders: reminders)
                .padding(.bottom, 12)

            // Data section
            VStack(spacing: 0) {
                Text("Data")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)

                VStack(spacing: 0) {
                    Button {
                        triggerHaptic()
                        onImportCSV()
                    } label: {
                        Label("Import from CSV", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }

                    Divider()
                        .padding(.leading, 16)

                    Button(role: .destructive) {
                        triggerHaptic()
                        onDeleteAll()
                    } label: {
                        Label("Delete All Moods", systemImage: "trash")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
            }

            // Chevron hint to swipe up to dismiss
            Image(systemName: "chevron.compact.up")
                .font(.system(size: 24))
                .foregroundStyle(.secondary.opacity(0.5))
                .padding(.top, 16)
                .padding(.bottom, 8)
        }
    }
}

/// Inline reminders section styled to match inline settings.
private struct InlineRemindersSection: View {
    @Binding var reminders: [Reminder]
    @State private var showAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            Text("Reminders")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 16)
                    }
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
                        Spacer()
                        Button {
                            triggerHaptic()
                            reminders.remove(at: index)
                            NotificationManager.scheduleAll(reminders)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                if !reminders.isEmpty {
                    Divider()
                        .padding(.leading, 16)
                }

                Button {
                    triggerHaptic()
                    showAddSheet = true
                } label: {
                    Label("Add Reminder", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $showAddSheet) {
            AddReminderSheet { newReminder in
                reminders.append(newReminder)
                NotificationManager.scheduleAll(reminders)
            }
        }
    }
}

// MARK: - Add Reminder Sheet (shared)

struct AddReminderSheet: View {
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
