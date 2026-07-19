//
//  SettingsView.swift
//  HowYouDoing?
//

import SwiftUI
import UIKit
import CoreData

@Observable
final class CloudSyncMonitor {
    var lastSyncDate: Date?

    private var observer: Any?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event,
                  event.succeeded,
                  let endDate = event.endDate else { return }
            self?.lastSyncDate = endDate
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }
}

/// Inline settings content designed to be embedded above the main content
/// in a ScrollView. The user reveals it by pulling down from the top.
///
/// Because a real `Form`/`List` can't be nested inside the mood panel's scroll
/// view without breaking the pull-up behavior, the grouped-list appearance is
/// reproduced with `SettingsSection`/row helpers using the system grouped
/// colors, fonts, and standard `Toggle`/`Picker`/menu controls.
struct InlineSettingsContent: View {
    let onImportCSV: () -> Void
    let onDeleteAll: () -> Void

    @State private var syncMonitor = CloudSyncMonitor()
    @State private var showAnalytics = false

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
        VStack(spacing: 18) {
            header

            SettingsSection {
                SettingsNavigationRow(title: "Analytics", systemImage: "chart.bar.xaxis") {
                    triggerHaptic()
                    showAnalytics = true
                }
            }

            InlineRemindersSection(reminders: reminders)

            SettingsSection(title: "Notifications") {
                Toggle("Open App on Mood Response", isOn: $openAppOnMoodAction)
                    .settingsRow()
                    .onChange(of: openAppOnMoodAction) {
                        NotificationManager.registerCategory()
                    }
            }

            SettingsSection(title: "Calendar") {
                SettingsPickerRow(title: "Week Starts On", selection: $weekStartDay) {
                    Text("Sunday").tag(1)
                    Text("Monday").tag(2)
                    Text("Tuesday").tag(3)
                    Text("Wednesday").tag(4)
                    Text("Thursday").tag(5)
                    Text("Friday").tag(6)
                    Text("Saturday").tag(7)
                }
            }

            SettingsSection(title: "Encouragement") {
                SettingsPickerRow(title: "Check-in Prompts", selection: $encouragementFrequencyRaw) {
                    ForEach(EncouragementFrequency.allCases, id: \.rawValue) { freq in
                        Text(freq.displayString).tag(freq.rawValue)
                    }
                }
            }

            SettingsSection(title: "Data") {
                SettingsNavigationRow(title: "Import from CSV", systemImage: "square.and.arrow.down") {
                    triggerHaptic()
                    onImportCSV()
                }
                SettingsRowDivider()
                SettingsActionRow(title: "Delete All Moods", systemImage: "trash", role: .destructive) {
                    triggerHaptic()
                    onDeleteAll()
                }
            }

            #if DEBUG
            SettingsSection(title: "Debug", titleColor: .orange) {
                Toggle("Show Welcome on Launch", isOn: $debugAlwaysShowWelcome)
                    .settingsRow()
                SettingsRowDivider()
                SettingsNavigationRow(
                    title: "Send Test Reminder (1 min)",
                    systemImage: "bell.and.waves.left.and.right",
                    showChevron: false
                ) {
                    triggerHaptic()
                    NotificationManager.scheduleDebugReminder()
                }
            }
            #endif

            Spacer(minLength: 16)
        }
        .padding(.top, 12)
        .sheet(isPresented: $showAnalytics) {
            AnalyticsView()
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Capsule()
                .fill(.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.bottom, 4)

            Text("Settings")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            HStack(spacing: 4) {
                Image(systemName: "icloud")
                    .font(.system(size: 11))
                if let date = syncMonitor.lastSyncDate {
                    Text("Last synced \(date.formatted(.relative(presentation: .named)))")
                } else {
                    Text("Waiting to sync…")
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - System-styled Settings Building Blocks

private extension View {
    /// Standard grouped-row metrics: horizontal inset and a 44pt minimum height.
    func settingsRow() -> some View {
        self
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
    }
}

/// A titled group of rows styled like an inset-grouped list section.
private struct SettingsSection<Content: View>: View {
    var title: String? = nil
    var titleColor: Color = .secondary
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(titleColor)
                    .textCase(.uppercase)
                    .padding(.leading, 16)
            }

            VStack(spacing: 0) {
                content
            }
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
        }
        .padding(.horizontal, 16)
    }
}

/// Separator between rows within a section, inset to align with the row label.
private struct SettingsRowDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 16)
    }
}

/// A tappable row with a leading label and an optional trailing chevron.
private struct SettingsNavigationRow: View {
    let title: String
    let systemImage: String
    var showChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .settingsRow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// An action row (e.g. destructive) whose label adopts the button role color.
private struct SettingsActionRow: View {
    let title: String
    let systemImage: String
    var role: ButtonRole? = nil
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .settingsRow()
                .contentShape(Rectangle())
        }
    }
}

/// A row with a leading title and a trailing pop-up menu picker, matching the
/// inline menu pickers used in the system Settings app.
private struct SettingsPickerRow<SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    @ViewBuilder var content: Content

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Picker(title, selection: $selection) {
                content
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(.secondary)
        }
        .settingsRow()
    }
}

/// Inline reminders section using a scroll-disabled List for native
/// swipe-to-delete and tap-to-edit, styled to match the other sections.
private struct InlineRemindersSection: View {
    @Binding var reminders: [Reminder]
    @State private var editingReminder: Reminder?
    @State private var showAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reminders")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 16)

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
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .frame(height: CGFloat(max(reminders.count, 0)) * 60 + 52)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
        }
        .padding(.horizontal, 16)
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

            Image(systemName: "chevron.forward")
                .font(.footnote.weight(.semibold))
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
