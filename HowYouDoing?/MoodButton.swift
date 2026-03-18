//
//  MoodButton.swift
//  HowYouDoing?
//

import SwiftUI

/// A single popover option row used inside mood popovers.
private struct MoodPopoverOption: View {
    let mood: MoodState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(mood.emoji)
                    .font(.system(size: 24))
                Text(mood.displayString)
                    .font(.body.weight(mood == .great || mood == .terrible ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular.tint(mood.color).interactive(), in: .rect(cornerRadius: 10))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// The floating popover that appears on long-press of a mood button.
private struct MoodPopover: View {
    let options: [MoodState]
    let onSelect: (MoodState) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .frame(width: 2000, height: 2000)
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 6) {
                ForEach(options, id: \.self) { mood in
                    MoodPopoverOption(mood: mood) {
                        triggerHaptic()
                        onSelect(mood)
                    }
                }
            }
            .padding(8)
            .frame(width: 200)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
            .foregroundStyle(.primary)
        }
        .transition(.scale.combined(with: .opacity))
    }
}

/// A mood button that supports tap to log and long-press to show a popover
/// with additional mood options.
struct MoodButton: View {
    let primaryMood: MoodState
    let popoverOptions: [MoodState]
    let minHeight: CGFloat
    let onSelect: (MoodState) -> Void

    @State private var showPopover = false
    @State private var isPressed = false

    /// Convenience for buttons that have no long-press popover (e.g. Meh).
    init(
        mood: MoodState,
        minHeight: CGFloat = 300,
        onSelect: @escaping (MoodState) -> Void
    ) {
        self.primaryMood = mood
        self.popoverOptions = []
        self.minHeight = minHeight
        self.onSelect = onSelect
    }

    /// Full initializer with popover options.
    init(
        primaryMood: MoodState,
        popoverOptions: [MoodState],
        minHeight: CGFloat = 300,
        onSelect: @escaping (MoodState) -> Void
    ) {
        self.primaryMood = primaryMood
        self.popoverOptions = popoverOptions
        self.minHeight = minHeight
        self.onSelect = onSelect
    }

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Text(primaryMood.emoji)
                    .font(.system(size: minHeight > 200 ? 48 : 28))
                Text(primaryMood.displayString)
                    .font(.title2.bold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .contentShape(Rectangle())
        }
        .glassEffect(.regular.tint(primaryMood.color).interactive(), in: .rect(cornerRadius: 12))
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isPressed ? 0.85 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .highPriorityGesture(
            TapGesture()
                .onEnded {
                    triggerHaptic()
                    onSelect(primaryMood)
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    guard !popoverOptions.isEmpty else { return }
                    triggerHaptic(style: .medium)
                    showPopover = true
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .overlay(alignment: .center) {
            if showPopover {
                MoodPopover(
                    options: popoverOptions,
                    onSelect: { mood in
                        onSelect(mood)
                        showPopover = false
                    },
                    onDismiss: { showPopover = false }
                )
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showPopover)
    }
}
