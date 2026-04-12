//
//  ContentView.swift
//  HowYouDoing?
//
//  Created by Ross Bower on 2/5/26.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]

    @AppStorage("weekStartDay") private var weekStartDay: Int = 2
    @AppStorage("reminders") private var remindersJSON: String = "[]"
    @AppStorage("pendingMoodPrompt") private var pendingMoodPrompt = false

    @State private var showDeleteConfirmation = false
    @State private var showImportFlow = false
    @State private var selectedDetent: PresentationDetent = .medium
    @State private var isZoomedOut = false
    @State private var pinchScale: CGFloat = 1.0
    @State private var editingEntry: MoodEntry?
    @State private var panelHeight: CGFloat = 0
    @State private var scrollToTop = false
    @Environment(\.scenePhase) private var scenePhase

    private var timelineRows: [TimelineRow] {
        buildTimeline(from: Array(moodEntries), weekStartDay: weekStartDay)
    }

    private var reminders: [Reminder] {
        [Reminder].fromJSON(remindersJSON)
    }

    private func addMood(_ state: MoodState) {
        modelContext.insert(MoodEntry(moodState: state))
        NotificationManager.resetAndReschedule(reminders)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        withAnimation(.spring(duration: 0.4, bounce: 0.1)) {
            pendingMoodPrompt = false
        }
        scrollToTop.toggle()
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
        ZStack(alignment: .bottom) {
            Group {
                if isZoomedOut {
                    zoomedOutView
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                } else {
                    historyListView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .scaleEffect(pinchScale)
            .simultaneousGesture(magnifyGesture)
            .opacity(pendingMoodPrompt ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: pendingMoodPrompt)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .sheet(item: $editingEntry) { entry in
            MoodEditorSheet(entry: entry)
        }
        .sheet(isPresented: .constant(true)) {
            moodPanelSheet
        }
        .task {
            await checkForDeliveredReminders()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await checkForDeliveredReminders() }
            }
            if newPhase == .background {
                withAnimation {
                    selectedDetent = .height(panelHeight)
                }
            }
        }
    }

    // MARK: - Mood Panel Sheet

    private var moodPanelSheet: some View {
        ScrollView {
            if pendingMoodPrompt {
                tallPanelContent
            } else {
                collapsedPanelContent
            }

            if selectedDetent == .large {
                InlineSettingsContent(
                    onImportCSV: { showImportFlow = true },
                    onDeleteAll: { showDeleteConfirmation = true }
                )
                .transition(.opacity)
            }
        }
        .presentationDetents(panelHeight > 0 ? [.height(panelHeight), .large] : [.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.hidden)
        .presentationBackgroundInteraction(.enabled(upThrough: .height(panelHeight)))
        .presentationBackground {
            Color.clear
                .glassEffect(.regular, in: .rect(cornerRadius: 24))
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Tall Panel (reminder triggered, awaiting mood entry)

    private var tallPanelContent: some View {
        VStack(spacing: 12) {
            Text("How You Doin'?")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
                .padding(.bottom, 4)

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 12) {
                    VStack(spacing: 12) {
                        MoodButton(
                            primaryMood: .good,
                            popoverOptions: [.good, .great],
                            minHeight: 160,
                            onSelect: addMood
                        )

                        MoodButton(
                            primaryMood: .bad,
                            popoverOptions: [.bad, .terrible],
                            minHeight: 160,
                            onSelect: addMood
                        )
                    }

                    MoodButton(
                        mood: .neutral,
                        minHeight: 332,
                        onSelect: addMood
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            panelHeight = height
            if selectedDetent != .large {
                selectedDetent = .height(height)
            }
        }
    }

    // MARK: - Collapsed Panel (default state)

    private var collapsedPanelContent: some View {
        VStack(spacing: 12) {
            Text("How You Doin'?")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
                .padding(.bottom, 4)

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 12) {
                    MoodButton(
                        primaryMood: .good,
                        popoverOptions: [.good, .great],
                        minHeight: 80,
                        onSelect: addMood
                    )

                    MoodButton(
                        primaryMood: .bad,
                        popoverOptions: [.bad, .terrible],
                        minHeight: 80,
                        onSelect: addMood
                    )

                    MoodButton(
                        mood: .neutral,
                        minHeight: 80,
                        onSelect: addMood
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            panelHeight = height
            if selectedDetent != .large {
                selectedDetent = .height(height)
            }
        }
    }

    // MARK: - Mood History List

    private var historyListView: some View {
        ScrollViewReader { proxy in
            List {
                Color.clear
                    .frame(height: 0)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .id("listTop")

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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingEntry = entry
                            }
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
            .contentMargins(.top, 16)
            .contentMargins(.bottom, panelHeight + 8)
            .onChange(of: scrollToTop) {
                withAnimation {
                    proxy.scrollTo("listTop", anchor: .top)
                }
            }
        }
    }

    // MARK: - Zoomed-Out Grid View

    private var zoomedOutView: some View {
        ScrollView {
            if !moodEntries.isEmpty {
                CompactTimelineView(timelineRows: timelineRows)
                    .padding(.top, 16)
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .all)
        .contentMargins(.bottom, panelHeight + 8)
    }

    private func checkForDeliveredReminders() async {
        let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
        let hasMoodReminders = delivered.contains {
            $0.request.identifier.hasPrefix("moodReminder-") ||
            $0.request.identifier.hasPrefix("debugReminder-")
        }
        if hasMoodReminders && !pendingMoodPrompt {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                pendingMoodPrompt = true
            }
        }
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

}

#Preview {
    ContentView()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
