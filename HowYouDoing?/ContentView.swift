//
//  ContentView.swift
//  HowYouDoing?
//
//  Created by Ross Bower on 2/5/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]

    private func addMood(_ state: MoodState) {
        modelContext.insert(MoodEntry(moodState: state))
    }

    private func deleteMood(_ entry: MoodEntry) {
        modelContext.delete(entry)
    }

    var body: some View {
        List {
            // Header
            Section {
                Text("How You Doin'?")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 28)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            // Mood buttons
            Section {
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
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
