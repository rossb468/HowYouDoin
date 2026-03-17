//
//  ContentView.swift
//  HowYouDoing?
//
//  Created by Ross Bower on 2/5/26.
//

import SwiftUI
import SwiftData

// MARK: - Helpers

private func dateLabel(for entry: MoodEntry, in entries: [MoodEntry]) -> String {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.day], from: entry.date, to: now)
    let formatter = DateFormatter()

    if calendar.isDateInToday(entry.date) {
        formatter.dateFormat = "'Today'"
    } else if calendar.isDateInYesterday(entry.date) {
        formatter.dateFormat = "'Yesterday'"
    } else if let days = components.day, days < 7 {
        formatter.dateFormat = "EEEE"
    } else {
        formatter.dateFormat = "MMMM dd"
    }

    // If there are multiple entries on the same day, append the time
    let sameDayCount = entries.filter { calendar.isDate($0.date, inSameDayAs: entry.date) }.count
    if sameDayCount > 1 {
        formatter.dateFormat += " 'at' h:mm a"
    }

    return formatter.string(from: entry.date)
}

// MARK: - Mood Card

struct MoodCardView: View {
    let entry: MoodEntry
    let entries: [MoodEntry]

    var body: some View {
        HStack(spacing: 14) {
            Text(entry.moodState.emoji)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.moodState.displayString)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(dateLabel(for: entry, in: entries))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(entry.moodState.color)
        )
    }
}

// MARK: - Blocking Modal

struct BlockingModal: View {
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("You must dismiss this")
                .font(.title2)

            Button("Dismiss", action: dismiss)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Content View

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]

    @State private var showModal = false
    @State private var showGoodPopover = false
    @State private var showBadPopover = false

    private func addMood(_ state: MoodState) {
        let entry = MoodEntry(moodState: state)
        modelContext.insert(entry)
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
                    .padding(.vertical, 16)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            // Buttons section
            Section {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            addMood(.good)
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "hand.thumbsup.fill")
                                    .font(.system(size: 36))
                                Text("Good")
                                    .font(.title2.bold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 300)
                        }
                        .background(Color.moodGreen)
                        .onLongPressGesture {
                            showGoodPopover = true
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
//                        .popover(isPresented: $showGoodPopover, arrowEdge: .bottom) {
//                            VStack(spacing: 0) {
//                                Button {
//                                    addMood(.good)
//                                    showGoodPopover = false
//                                } label: {
//                                    Label("Good", systemImage: "hand.thumbsup")
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                        .padding(.horizontal, 16)
//                                        .padding(.vertical, 12)
//                                }
//                                Divider()
//                                Button {
//                                    addMood(.great)
//                                    showGoodPopover = false
//                                } label: {
//                                    Label("Great!", systemImage: "hand.thumbsup.fill")
//                                        .fontWeight(.semibold)
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                        .padding(.horizontal, 16)
//                                        .padding(.vertical, 12)
//                                }
//                            }
//                            .tint(Color.moodGreen)
//                            .presentationCompactAdaptation(.popover)
//                        }

                        Button {
                            addMood(.bad)
                        }
                        label: {
                            VStack(spacing: 8) {
                                Image(systemName: "hand.thumbsdown.fill")
                                    .font(.system(size: 36))
                                Text("Bad")
                                    .font(.title2.bold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 300)
                        }
                        .background(Color.moodRed)
                        .onLongPressGesture {
                            showBadPopover = true
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
//                        .popover(isPresented: $showBadPopover, arrowEdge: .bottom) {
//                            VStack(spacing: 0) {
//                                Button {
//                                    addMood(.bad)
//                                    showBadPopover = false
//                                } label: {
//                                    Label("Bad", systemImage: "hand.thumbsdown")
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                        .padding(.horizontal, 16)
//                                        .padding(.vertical, 12)
//                                }
//                                Divider()
//                                Button {
//                                    addMood(.terrible)
//                                    showBadPopover = false
//                                } label: {
//                                    Label("Terrible", systemImage: "hand.thumbsdown.fill")
//                                        .fontWeight(.semibold)
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                        .padding(.horizontal, 16)
//                                        .padding(.vertical, 12)
//                                }
//                            }
//                            .tint(Color.moodRed)
//                            .presentationCompactAdaptation(.popover)
//                        }
//                        .fullScreenCover(isPresented: $showModal) {
//                            BlockingModal {
//                                showModal = false
//                            }
//                        }
                    }

                    Button {
                        addMood(.neutral)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                            Text("Meh")
                                .font(.title2.bold())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 100)
                    }
                    .background(Color.moodBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
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
