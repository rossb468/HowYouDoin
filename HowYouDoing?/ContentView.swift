//
//  ContentView.swift
//  HowYouDoing?
//
//  Created by Ross Bower on 2/5/26.
//

import SwiftUI
import SwiftData
import UserNotifications
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]

    @AppStorage("weekStartDay") private var weekStartDay: Int = 2
    @AppStorage("reminders") private var remindersJSON: String = "[]"
    @AppStorage("pendingMoodPrompt") private var pendingMoodPrompt = false

    @State private var showDeleteConfirmation = false
    @State private var showImportFlow = false
    @State private var selectedDetent: PresentationDetent = .large
    @State private var isZoomedOut = false
    @State private var pinchScale: CGFloat = 1.0
    @State private var editingEntry: MoodEntry?
    @State private var panelHeight: CGFloat = 0
    @State private var collapsedHeight: CGFloat = 0
    @State private var tallHeight: CGFloat = 0
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
            selectedDetent = .height(collapsedHeight)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
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
            .opacity(showTallPanel ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: showTallPanel)
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
        .sheet(isPresented: .constant(true)) {
            moodPanelSheet
                .sheet(isPresented: $showImportFlow) {
                    CSVImportFlow()
                }
                .sheet(item: $editingEntry) { entry in
                    MoodEditorSheet(entry: entry)
                }
        }
        .task {
            await checkForDeliveredReminders()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await checkForDeliveredReminders() }
            }
            if newPhase == .background && collapsedHeight > 0 {
                withAnimation {
                    selectedDetent = .height(collapsedHeight)
                }
            }
        }
        .onChange(of: tallHeight) { _, newHeight in
            // While a prompt is pending, keep the sheet sized to the tall
            // panel so the larger buttons are never clipped — regardless of
            // what detent we were resting at when the prompt appeared.
            if pendingMoodPrompt && newHeight > 0 && selectedDetent != .height(newHeight) {
                withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                    selectedDetent = .height(newHeight)
                }
            }
        }
        .onChange(of: pendingMoodPrompt) { _, isPending in
            // A reminder can turn this on while the sheet is collapsed (e.g. it
            // arrives in the foreground, or the flag was persisted from a prior
            // launch). Grow to the tall panel as soon as the prompt begins.
            guard isPending else { return }
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                selectedDetent = tallHeight > 0 ? .height(tallHeight) : .large
            }
        }
    }

    private var showTallPanel: Bool {
        pendingMoodPrompt
    }

    private var sheetDetents: Set<PresentationDetent> {
        // While awaiting a mood entry, lock the sheet to the tall height so it
        // can't be dragged down and clip the prompt buttons.
        if pendingMoodPrompt {
            return tallHeight > 0 ? [.height(tallHeight)] : [.large]
        }

        // Resting state: only the compact height and the full settings height.
        // The tall prompt height is deliberately excluded so the panel can't be
        // dragged up to it manually — it's reachable only when a prompt is active.
        var detents: Set<PresentationDetent> = [.large]
        if collapsedHeight > 0 {
            detents.insert(.height(collapsedHeight))
        }
        return detents
    }

    // MARK: - Mood Panel Sheet

    private var moodPanelSheet: some View {
        ScrollView {
            if showTallPanel {
                tallPanelContent
            } else {
                collapsedPanelContent
            }

            if selectedDetent == .large && !pendingMoodPrompt {
                InlineSettingsContent(
                    onImportCSV: { showImportFlow = true },
                    onDeleteAll: { showDeleteConfirmation = true }
                )
                .transition(.opacity)
            }
        }
        .presentationDetents(
            sheetDetents,
            selection: $selectedDetent
        )
        .presentationDragIndicator(.hidden)
        .presentationBackgroundInteraction(.enabled(upThrough: .height(collapsedHeight)))
        .presentationBackground {
            Color.clear
                .glassEffect(.regular, in: .rect(cornerRadius: 24))
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Panel Grabber

    /// Drag handle shown at the top of the mood panel. Lives inside the panel
    /// content so its height is included in the measured detent heights.
    private var panelGrabber: some View {
        Capsule()
            // Opaque fixed gray so the handle keeps a consistent, high-contrast
            // appearance instead of shifting with whatever shows through the
            // glass as the panel moves.
            .fill(Color(.systemGray2))
            .frame(width: 40, height: 5)
    }

    // MARK: - Tall Panel (reminder triggered, awaiting mood entry)

    private var tallPanelContent: some View {
        VStack(spacing: 12) {
            panelGrabber

            Text("How You Doin'?")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)
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
        .padding(.top, 8)
        .padding(.bottom, 16)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            panelHeight = height
            tallHeight = height
        }
    }

    // MARK: - Collapsed Panel (default state)

    private var collapsedPanelContent: some View {
        VStack(spacing: 12) {
            panelGrabber

            Text("How You Doin'?")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)
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
        .padding(.top, 8)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            let isFirstMeasurement = collapsedHeight == 0
            collapsedHeight = height
            panelHeight = height
            if isFirstMeasurement && !pendingMoodPrompt {
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
                        case .moodEntry(let entry, let position, let nextColor):
                            MoodEntryRow(
                                entry: entry,
                                position: position,
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
            .contentMargins(.top, 0)
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
            // The detent adjustment is handled by onChange(of: pendingMoodPrompt).
            pendingMoodPrompt = true
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
