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
    @AppStorage("appTheme") private var appTheme: String = AppTheme.system.rawValue

    private var selectedTheme: AppTheme {
        get { AppTheme(rawValue: appTheme) ?? .system }
        set { appTheme = newValue.rawValue }
    }

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
        ZStack(alignment: .top) {
            // Main content
            List {
                // Header with gear icon
                Section {
                    ZStack(alignment: .topTrailing) {
                        Text("How You Doin'?")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 28)

                        Button {
                            triggerHaptic()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showSettings.toggle()
                            }
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                                .frame(width: 34, height: 34)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(.primary.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 12)
                        .padding(.trailing, 16)
                    }
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

            // Settings slide-over from top
            if showSettings {
                // Dimmed backdrop
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showSettings = false
                        }
                    }
                    .transition(.opacity)

                // Settings panel
                SettingsView(
                    selectedTheme: Binding(
                        get: { AppTheme(rawValue: appTheme) ?? .system },
                        set: { appTheme = $0.rawValue }
                    ),
                    onImportCSV: {
                        showFileImporter = true
                    },
                    onDeleteAll: {
                        showDeleteConfirmation = true
                    },
                    onDismiss: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showSettings = false
                        }
                    }
                )
                .shadow(color: .black.opacity(0.4), radius: 30, y: 12)
                .padding(.horizontal, 16)
                .padding(.top, 2)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showSettings)
        .alert("Delete All Moods?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All Moods", role: .destructive) {
                deleteAllMoods()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    showSettings = false
                }
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
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showSettings = false
                    }
                }
            case .failure:
                break
            }
        }
        .preferredColorScheme(selectedTheme.colorScheme)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
