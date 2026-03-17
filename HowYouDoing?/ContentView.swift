//
//  ContentView.swift
//  HowYouDoing?
//
//  Created by Ross Bower on 2/5/26.
//

import SwiftUI
import SwiftData
import UIKit

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

// Simple haptic feedback helper
private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
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
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 28)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            // Buttons section
            Section {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            VStack(spacing: 8) {
                                Text(MoodState.good.emoji)
                                    .font(.system(size: 48))
                                Text("Good")
                                    .font(.title2.bold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 300)
                        }
                        .background(Color.moodGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .highPriorityGesture(
                            TapGesture()
                                .onEnded {
                                    triggerHaptic()
                                    addMood(.good)
                                }
                        )
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in 
                                    triggerHaptic(style: .medium)
                                    showGoodPopover = true 
                                }
                        )
                        .overlay(alignment: .center) {
                            if showGoodPopover {
                                ZStack {
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .frame(width: 2000, height: 2000)
                                        .onTapGesture {
                                            showGoodPopover = false
                                        }
                                    
                                    VStack(spacing: 6) {
                                        Button {
                                            triggerHaptic()
                                            addMood(.good)
                                            showGoodPopover = false
                                        } label: {
                                            HStack(spacing: 12) {
                                                Text(MoodState.good.emoji)
                                                    .font(.system(size: 24))
                                                Text("Good")
                                                    .font(.body)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(MoodState.good.color)
                                            )
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Button {
                                            triggerHaptic()
                                            addMood(.great)
                                            showGoodPopover = false
                                        } label: {
                                            HStack(spacing: 12) {
                                                Text(MoodState.great.emoji)
                                                    .font(.system(size: 24))
                                                Text("Great!")
                                                    .font(.body.weight(.semibold))
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(MoodState.great.color)
                                            )
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(8)
                                    .frame(width: 200)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color(.systemGray6))
                                            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(.white.opacity(0.2), lineWidth: 1.5)
                                    )
                                    .foregroundStyle(.white)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showGoodPopover)

                        Button(action: {}) {
                            VStack(spacing: 8) {
                                Text(MoodState.bad.emoji)
                                    .font(.system(size: 48))
                                Text("Bad")
                                    .font(.title2.bold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 300)
                        }
                        .background(Color.moodRed)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .highPriorityGesture(
                            TapGesture()
                                .onEnded {
                                    triggerHaptic()
                                    addMood(.bad)
                                }
                        )
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in 
                                    triggerHaptic(style: .medium)
                                    showBadPopover = true 
                                }
                        )
                        .overlay(alignment: .center) {
                            if showBadPopover {
                                ZStack {
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .frame(width: 2000, height: 2000)
                                        .onTapGesture {
                                            showBadPopover = false
                                        }
                                    
                                    VStack(spacing: 6) {
                                        Button {
                                            triggerHaptic()
                                            addMood(.bad)
                                            showBadPopover = false
                                        } label: {
                                            HStack(spacing: 12) {
                                                Text(MoodState.bad.emoji)
                                                    .font(.system(size: 24))
                                                Text("Bad")
                                                    .font(.body)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(MoodState.bad.color)
                                            )
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Button {
                                            triggerHaptic()
                                            addMood(.terrible)
                                            showBadPopover = false
                                        } label: {
                                            HStack(spacing: 12) {
                                                Text(MoodState.terrible.emoji)
                                                    .font(.system(size: 24))
                                                Text("Terrible")
                                                    .font(.body.weight(.semibold))
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(MoodState.terrible.color)
                                            )
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(8)
                                    .frame(width: 200)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color(.systemGray6))
                                            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(.white.opacity(0.2), lineWidth: 1.5)
                                    )
                                    .foregroundStyle(.white)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showBadPopover)
                    }
                    .fullScreenCover(isPresented: $showModal) {
                        BlockingModal {
                            showModal = false
                        }
                    }

                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Text(MoodState.neutral.emoji)
                                .font(.system(size: 28))
                            Text("Meh")
                                .font(.title2.bold())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 100)
                    }
                    .background(Color.moodBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .highPriorityGesture(
                        TapGesture()
                            .onEnded {
                                triggerHaptic()
                                addMood(.neutral)
                            }
                    )
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in }
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

