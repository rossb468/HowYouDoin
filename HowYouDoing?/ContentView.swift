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

    @AppStorage("weekStartDay") private var weekStartDay: Int = 2

    @State private var showDeleteConfirmation = false
    @State private var showImportFlow = false
    @State private var settingsOpen = false
    @State private var dragOffset: CGFloat = 0
    @State private var settingsHeight: CGFloat = 0
    @State private var isAtTop = true
    @State private var isZoomedOut = false
    @State private var pinchScale: CGFloat = 1.0

    private var timelineRows: [TimelineRow] {
        buildTimeline(from: Array(moodEntries), weekStartDay: weekStartDay)
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

    /// Current translation: 0 when closed, settingsHeight when open.
    private var currentOffset: CGFloat {
        let base: CGFloat = settingsOpen ? settingsHeight : 0
        return base + dragOffset
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Settings panel positioned above the visible area
            InlineSettingsContent(
                onImportCSV: { showImportFlow = true },
                onDeleteAll: { showDeleteConfirmation = true }
            )
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                settingsHeight = height
            }
            .offset(y: currentOffset - settingsHeight)
            .clipped()

            // Main content — switches between normal list and zoomed-out grid
            Group {
                if isZoomedOut {
                    zoomedOutView
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                } else {
                    normalListView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .scaleEffect(pinchScale)
            .simultaneousGesture(magnifyGesture)
            .offset(y: currentOffset)
        }
        .simultaneousGesture(settingsDragGesture)
        .alert("Delete All Moods?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All Moods", role: .destructive) {
                deleteAllMoods()
            }
        } message: {
            Text("This will permanently delete all your mood entries. This cannot be undone.")
        }
        .sheet(isPresented: $showImportFlow) {
            CSVImportFlow()
        }
    }

    // MARK: - Mood Buttons (shared between views)

    private var moodButtonsSection: some View {
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
    }

    // MARK: - Normal List View

    private var normalListView: some View {
        List {
            // Title
            Section {
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
                moodButtonsSection
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 28, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            // Encouragement banner
            EncouragementBannerView(moodEntries: moodEntries)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            // Mood history with day grouping and dividers
            if !moodEntries.isEmpty {
                ForEach(timelineRows) { row in
                    switch row {
                    case .moodEntry(let entry, let position, let dayLabel, let nextColor):
                        MoodEntryRow(
                            entry: entry,
                            position: position,
                            dayLabel: dayLabel,
                            nextColor: nextColor
                        )
                        .listRowInsets(EdgeInsets(
                            top: position == .sole || position == .first ? 10 : 0,
                            leading: 16,
                            bottom: position == .sole || position == .last ? 10 : 0,
                            trailing: 16
                        ))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteMood(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                    case .monthDivider(let label, _):
                        MonthDividerView(label: label)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollEdgeEffectStyle(.soft, for: .all)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y <= geometry.contentInsets.top + 1
        } action: { _, atTop in
            isAtTop = atTop
        }
    }

    // MARK: - Zoomed-Out Grid View

    private var zoomedOutView: some View {
        ScrollView {
            Text("How You Doin'?")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)

            moodButtonsSection
                .padding(.horizontal, 16)
                .padding(.bottom, 28)

            EncouragementBannerView(moodEntries: moodEntries)

            if !moodEntries.isEmpty {
                CompactTimelineView(timelineRows: timelineRows)
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .all)
    }

    // MARK: - Magnify Gesture

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                pinchScale = min(max(value.magnification, 0.5), 1.5)
            }
            .onEnded { value in
                let scale = value.magnification

                withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                    pinchScale = 1.0

                    if !isZoomedOut && scale < 0.7 {
                        isZoomedOut = true
                        triggerHaptic(style: .medium)
                    } else if isZoomedOut && scale > 1.4 {
                        isZoomedOut = false
                        triggerHaptic(style: .medium)
                    }
                }
            }
    }

    /// Applies a rubber-band curve: moves quickly at first, then
    /// increasingly resists as the drag grows relative to the limit.
    private func rubberBand(_ offset: CGFloat, limit: CGFloat) -> CGFloat {
        let clamped = max(offset, 0)
        let ratio = clamped / limit
        // Logarithmic decay gives a natural rubber-band feel
        return limit * (1 - 1 / (ratio * 0.55 + 1))
    }

    private var settingsDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.height
                if settingsOpen {
                    // When open, only allow dragging up (negative)
                    dragOffset = min(0, translation)
                } else if isAtTop && !isZoomedOut && translation > 0 {
                    // When closed, only respond if list is at the top
                    let raw = max(0, translation)
                    dragOffset = rubberBand(raw, limit: settingsHeight)
                }
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height - value.translation.height
                let threshold = settingsHeight * 0.45

                withAnimation(.spring(duration: 0.35, bounce: 0.0)) {
                    if settingsOpen {
                        // Snap closed if dragged up enough or flicked up
                        if -value.translation.height > threshold || velocity < -100 {
                            settingsOpen = false
                        }
                    } else if isAtTop && !isZoomedOut {
                        // Snap open only if at top and the visual offset passed the threshold
                        if dragOffset > threshold || velocity > 200 {
                            settingsOpen = true
                        }
                    }
                    dragOffset = 0
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
