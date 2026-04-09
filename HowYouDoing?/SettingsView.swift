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

    private static var isDebugBuild: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    @AppStorage("reminders") private var remindersJSON: String = "[]"
    @AppStorage("weekStartDay") private var weekStartDay: Int = 2
    @AppStorage("encouragementFrequency") private var encouragementFrequencyRaw: String = EncouragementFrequency.onceADay.rawValue
    @AppStorage("openAppOnMoodAction") private var openAppOnMoodAction = false

    #if DEBUG
    @AppStorage("debug_alwaysShowWelcome") private var debugAlwaysShowWelcome = false
    #endif

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

            // Notification behavior
            Toggle("Open App on Mood Response", isOn: $openAppOnMoodAction)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .onChange(of: openAppOnMoodAction) {
                    NotificationManager.registerCategory()
                }

            // Calendar section
            VStack(spacing: 0) {
                Text("Calendar")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)

                HStack {
                    Text("Week Starts On")
                        .font(.body)
                    Spacer()
                    Picker("Week Starts On", selection: $weekStartDay) {
                        Text("Sunday").tag(1)
                        Text("Monday").tag(2)
                        Text("Tuesday").tag(3)
                        Text("Wednesday").tag(4)
                        Text("Thursday").tag(5)
                        Text("Friday").tag(6)
                        Text("Saturday").tag(7)
                    }
                    .labelsHidden()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 12)

            // Encouragement section
            VStack(spacing: 0) {
                Text("Encouragement")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)

                HStack {
                    Text("Check-in Prompts")
                        .font(.body)
                    Spacer()
                    Picker("Check-in Prompts", selection: $encouragementFrequencyRaw) {
                        ForEach(EncouragementFrequency.allCases, id: \.rawValue) { freq in
                            Text(freq.displayString).tag(freq.rawValue)
                        }
                    }
                    .labelsHidden()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 12)

            // Data section
            VStack(spacing: 0) {
                Text("Data")
                    .font(.subheadline.weight(.medium))
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
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                    }

                    Divider()
                        .padding(.leading, 18)

                    Button(role: .destructive) {
                        triggerHaptic()
                        onDeleteAll()
                    } label: {
                        Label("Delete All Moods", systemImage: "trash")
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 16)
            }

            #if DEBUG
            // Debug section
            VStack(spacing: 0) {
                Text("Debug")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)

                VStack(spacing: 0) {
                    Toggle("Show Welcome on Launch", isOn: $debugAlwaysShowWelcome)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)

                    Divider()
                        .padding(.leading, 18)

                    Button {
                        triggerHaptic()
                        NotificationManager.scheduleDebugReminder()
                    } label: {
                        Label("Send Test Reminder (1 min)", systemImage: "bell.and.waves.left.and.right")
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 16)
            }
            .padding(.top, 12)
            #endif

            // Build info
            HStack(spacing: 6) {
                Circle()
                    .fill(Self.isDebugBuild ? .orange : .moodGreen)
                    .frame(width: 8, height: 8)
                Text(Self.isDebugBuild ? "Debug Build" : "Release Build")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)

            // Chevron hint to swipe down to dismiss
            Image(systemName: "chevron.compact.down")
                .font(.system(size: 24))
                .foregroundStyle(.secondary.opacity(0.5))
                .padding(.top, 16)
                .padding(.bottom, 8)
        }
    }
}

/// Inline reminders section styled to match inline settings.
/// Uses a standard List with swipe-to-delete and tap-to-edit.
private struct InlineRemindersSection: View {
    @Binding var reminders: [Reminder]
    @State private var editingReminder: Reminder?
    @State private var showAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            Text("Reminders")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

            List {
                ForEach(reminders) { reminder in
                    ReminderRow(reminder: reminder)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowBackground(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            triggerHaptic()
                            editingReminder = reminder
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                triggerHaptic()
                                if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
                                    reminders.remove(at: index)
                                    NotificationManager.scheduleAll(reminders)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }

                Button {
                    triggerHaptic()
                    showAddSheet = true
                } label: {
                    Label("Add Reminder", systemImage: "plus.circle.fill")
                        .font(.body)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .frame(height: CGFloat(max(reminders.count, 0)) * 60 + 48)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 16)
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

// MARK: - Reminder Row

private struct ReminderRow: View {
    let reminder: Reminder

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: reminder.isEnabled ? "bell.fill" : "bell.slash.fill")
                .foregroundStyle(reminder.isEnabled ? Color.moodGreen : .secondary)
                .font(.system(size: 18))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.timeString)
                    .font(.body.weight(.medium))
                Text(reminder.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Reminder Editor Sheet (Add & Edit)

struct ReminderEditorSheet: View {
    enum Mode {
        case add
        case edit(Reminder)

        var title: String {
            switch self {
            case .add: return "New Reminder"
            case .edit: return "Edit Reminder"
            }
        }
    }

    let mode: Mode
    let onSave: (Reminder) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedTime: Date
    @State private var bodyText: String
    @State private var isEnabled: Bool
    private let existingID: UUID?

    init(mode: Mode, onSave: @escaping (Reminder) -> Void) {
        self.mode = mode
        self.onSave = onSave

        switch mode {
        case .add:
            var components = DateComponents()
            components.hour = 14
            components.minute = 0
            let defaultTime = Calendar.current.date(from: components) ?? Date()
            _selectedTime = State(initialValue: defaultTime)
            _bodyText = State(initialValue: "How are you?")
            _isEnabled = State(initialValue: true)
            existingID = nil

        case .edit(let reminder):
            var components = DateComponents()
            components.hour = reminder.hour
            components.minute = reminder.minute
            let date = Calendar.current.date(from: components) ?? Date()
            _selectedTime = State(initialValue: date)
            _bodyText = State(initialValue: reminder.body)
            _isEnabled = State(initialValue: reminder.isEnabled)
            existingID = reminder.id
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }

                Section {
                    TextField("Message", text: $bodyText)
                }

                Section {
                    Toggle("Enabled", isOn: $isEnabled)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        triggerHaptic()
                        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                        var reminder = Reminder(
                            hour: components.hour ?? 12,
                            minute: components.minute ?? 0,
                            title: "How You Doin'?",
                            body: bodyText.isEmpty ? "How are you?" : bodyText,
                            isEnabled: isEnabled
                        )
                        if let existingID {
                            reminder.id = existingID
                        }
                        onSave(reminder)
                        dismiss()
                    }
                }
            }
        }
    }
}
