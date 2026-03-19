//
//  ContentView.swift
//  HowYouDoing?
//
//  Created by Ross Bower on 2/5/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]

    @State private var showSettings = false
    @State private var showDeleteConfirmation = false
    @State private var showFileImporter = false
    private func addMood(_ state: MoodState) {
        modelContext.insert(MoodEntry(moodState: state))
    }

    private func deleteMood(_ entry: MoodEntry) {
        modelContext.delete(entry)
    }

    private func deleteAllMoods() {
        for entry in moodEntries {
            modelContext.delete(entry)
        }
    }

    var body: some View {
        List {
            // Header with title and gear button on separate rows
            Section {
                HStack {
                    Spacer()
                    Button {
                        triggerHaptic()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.glass)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Text("How You Doin'?")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            // Mood buttons
            Section {
                GlassEffectContainer(spacing: 8) {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            MoodButton(
                                primaryMood: .good,
                                popoverOptions: [.good, .great],
                                onSelect: addMood
                            )

                            MoodButton(
                                primaryMood: .bad,
                                popoverOptions: [.bad, .terrible],
                                onSelect: addMood
                            )
                        }

                        MoodButton(
                            mood: .neutral,
                            minHeight: 100,
                            onSelect: addMood
                        )
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 28, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            // Mood history
            if !moodEntries.isEmpty {
                Section {
                    ForEach(moodEntries) { entry in
                        MoodCardView(entry: entry, entries: moodEntries)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteMood(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollEdgeEffectStyle(.soft, for: .all)
        .sheet(isPresented: $showSettings) {
            SettingsView(
                onImportCSV: {
                    showFileImporter = true
                },
                onDeleteAll: {
                    showDeleteConfirmation = true
                }
            )
        }
        .alert("Delete All Moods?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All Moods", role: .destructive) {
                deleteAllMoods()
            }
        } message: {
            Text("This will permanently delete all your mood entries. This cannot be undone.")
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    CSVImporter.importCSV(from: url, into: modelContext)
                }
            case .failure:
                break
            }
        }

    }
}

#Preview {
    ContentView()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
