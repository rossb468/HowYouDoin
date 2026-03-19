//
//  SettingsView.swift
//  HowYouDoing?
//

import SwiftUI

struct SettingsView: View {
    let onImportCSV: () -> Void
    let onDeleteAll: () -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("reminders") private var remindersJSON: String = "[]"

    private var reminders: Binding<[Reminder]> {
        Binding(
            get: { [Reminder].fromJSON(remindersJSON) },
            set: { remindersJSON = $0.jsonString }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                // Reminders
                RemindersSection(reminders: reminders)

                // Data
                Section("Data") {
                    Button {
                        triggerHaptic()
                        onImportCSV()
                    } label: {
                        Label("Import from CSV", systemImage: "square.and.arrow.down")
                    }

                    Button(role: .destructive) {
                        triggerHaptic()
                        onDeleteAll()
                    } label: {
                        Label("Delete All Moods", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        triggerHaptic()
                        dismiss()
                    }
                }
            }
        }
    }
}
