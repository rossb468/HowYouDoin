//
//  EncouragementBanner.swift
//  HowYouDoing?
//

import SwiftUI

// MARK: - Encouragement Frequency Setting

enum EncouragementFrequency: String, CaseIterable {
    case never = "never"
    case onceADay = "onceADay"
    case oncePerReminder = "oncePerReminder"

    var displayString: String {
        switch self {
        case .never:            return "Never"
        case .onceADay:         return "Once a Day"
        case .oncePerReminder:  return "Once per Reminder"
        }
    }
}

// MARK: - Encouragement Engine (Pure Logic)

struct EncouragementEngine {

    struct Result: Equatable {
        let message: String
        let icon: String
    }

    /// Returns an encouragement message if the user should be prompted, or nil if not.
    static func encouragement(
        now: Date,
        reminders: [Reminder],
        moodEntries: [MoodEntry],
        frequency: EncouragementFrequency
    ) -> Result? {
        guard frequency != .never else { return nil }

        let calendar = Calendar.current
        let enabledReminders = reminders
            .filter(\.isEnabled)
            .sorted { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }

        // Use per-reminder windows only when the setting is oncePerReminder AND
        // there are at least 2 enabled reminders to form multiple windows.
        if frequency == .oncePerReminder, enabledReminders.count >= 2 {
            if let window = currentWindow(now: now, enabledReminders: enabledReminders, calendar: calendar) {
                if hasEntry(in: moodEntries, since: window.start, now: now) {
                    return nil
                }
                let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
                return Result(
                    message: message(forHour: window.reminderHour, dayOfYear: dayOfYear),
                    icon: icon(forHour: window.reminderHour)
                )
            }
        }

        // Fallback: once-a-day window (entire calendar day)
        let startOfDay = calendar.startOfDay(for: now)
        if hasEntry(in: moodEntries, since: startOfDay, now: now) {
            return nil
        }
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        return Result(
            message: message(forHour: nil, dayOfYear: dayOfYear),
            icon: icon(forHour: nil)
        )
    }

    // MARK: - Window Computation

    private struct Window {
        let start: Date
        let reminderHour: Int
    }

    /// Finds which reminder window `now` falls into, given 2+ enabled reminders.
    private static func currentWindow(
        now: Date,
        enabledReminders: [Reminder],
        calendar: Calendar
    ) -> Window? {
        let count = enabledReminders.count
        let reminderMinutes = enabledReminders.map { $0.hour * 60 + $0.minute }

        // Compute reset points: the time after each reminder when its window begins.
        var resetPoints: [Int] = []
        for i in 0..<count {
            let nextIndex = (i + 1) % count
            var gap = reminderMinutes[nextIndex] - reminderMinutes[i]
            if gap <= 0 { gap += 1440 }

            let resetOffset: Int
            if gap <= 60 {
                resetOffset = Int(Double(gap) * 0.2)
            } else {
                resetOffset = 60
            }
            resetPoints.append((reminderMinutes[i] + resetOffset) % 1440)
        }

        let nowMinutes = calendar.component(.hour, from: now) * 60
                       + calendar.component(.minute, from: now)

        for i in 0..<count {
            let windowStart = resetPoints[i]
            let windowEnd = resetPoints[(i + 1) % count]

            let inWindow: Bool
            if windowStart <= windowEnd {
                inWindow = nowMinutes >= windowStart && nowMinutes < windowEnd
            } else {
                // Wraps around midnight
                inWindow = nowMinutes >= windowStart || nowMinutes < windowEnd
            }

            if inWindow {
                let today = calendar.startOfDay(for: now)
                var startDate = calendar.date(byAdding: .minute, value: windowStart, to: today)!
                // If the window start is after current time, it must be from the previous day
                if windowStart > nowMinutes {
                    startDate = calendar.date(byAdding: .day, value: -1, to: startDate)!
                }
                return Window(start: startDate, reminderHour: enabledReminders[i].hour)
            }
        }

        return nil
    }

    // MARK: - Entry Check

    /// Checks if any mood entry exists between `since` and `now`.
    /// Assumes moodEntries are sorted newest-first for efficient early exit.
    private static func hasEntry(in moodEntries: [MoodEntry], since: Date, now: Date) -> Bool {
        for entry in moodEntries {
            if entry.date < since { break }
            if entry.date >= since && entry.date <= now {
                return true
            }
        }
        return false
    }

    // MARK: - Message Generation

    /// Returns a contextual encouragement message based on the reminder hour.
    /// `nil` hour means once-a-day mode (no time-of-day context).
    /// Messages rotate by day-of-year for variety.
    static func message(forHour hour: Int?, dayOfYear: Int) -> String {
        let messages: [String]

        guard let hour else {
            messages = [
                "How are you feeling today?",
                "Take a moment to check in with yourself.",
                "Your mood matters — log it for today.",
                "A quick check-in goes a long way.",
                "How's your day going so far?",
            ]
            return messages[dayOfYear % messages.count]
        }

        switch hour {
        case 5..<8:
            messages = [
                "Good morning! How are you starting your day?",
                "Rise and shine — how's your morning mood?",
                "A new day begins. How are you feeling?",
            ]
        case 8..<11:
            messages = [
                "How's your morning going?",
                "Mid-morning check-in — how are you doing?",
                "Take a moment to log your morning mood.",
            ]
        case 11..<13:
            messages = [
                "Midday check-in — how are you feeling?",
                "How's your day going so far?",
                "Halfway through the day. What's your mood?",
            ]
        case 13..<17:
            messages = [
                "How's your afternoon going?",
                "Afternoon check-in — how are you doing?",
                "Take a moment this afternoon to check in.",
            ]
        case 17..<20:
            messages = [
                "How's your evening going?",
                "Winding down — how are you feeling?",
                "Evening check-in. How was your day?",
            ]
        case 20..<24:
            messages = [
                "How are you feeling tonight?",
                "End of day check-in. How was today?",
                "Before you rest — how are you doing?",
            ]
        default: // 0..<5
            messages = [
                "Up late? How are you feeling?",
                "Late night check-in — how are you doing?",
                "Can't sleep? Take a moment to log your mood.",
            ]
        }

        return messages[dayOfYear % messages.count]
    }

    /// Returns an SF Symbol name contextual to the time of day.
    static func icon(forHour hour: Int?) -> String {
        guard let hour else { return "sun.and.horizon" }
        switch hour {
        case 5..<8:   return "sunrise"
        case 8..<13:  return "sun.max"
        case 13..<17: return "sun.haze"
        case 17..<20: return "sunset"
        case 20..<24: return "moon"
        default:      return "moon.stars"
        }
    }
}

// MARK: - Encouragement Banner View

struct EncouragementBannerView: View {
    let moodEntries: [MoodEntry]

    @AppStorage("reminders") private var remindersJSON: String = "[]"
    @AppStorage("encouragementFrequency") private var frequencyRaw: String = EncouragementFrequency.onceADay.rawValue

    @State private var currentResult: EncouragementEngine.Result?

    private var frequency: EncouragementFrequency {
        EncouragementFrequency(rawValue: frequencyRaw) ?? .onceADay
    }

    private var reminders: [Reminder] {
        [Reminder].fromJSON(remindersJSON)
    }

    var body: some View {
        // TimelineView re-evaluates every 60 seconds without Combine.
        // Bridge the result into @State so SwiftUI can animate transitions.
        // Everything is inside a single VStack so the list sees one row that
        // collapses to zero height when the banner is hidden.
        VStack(spacing: 0) {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                Color.clear.frame(height: 0)
                    .onChange(of: context.date) { _, newDate in
                        updateResult(now: newDate)
                    }
                    .onAppear {
                        updateResult(now: context.date)
                    }
            }
            .frame(height: 0)

            if let result = currentResult {
                bannerContent(result)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .move(edge: .top)
                            .combined(with: .scale(scale: 0.4))
                            .combined(with: .opacity)
                    ))
            }
        }
        .onChange(of: moodEntries.count) {
            updateResult(now: Date())
        }
        .onChange(of: frequencyRaw) {
            updateResult(now: Date())
        }
    }

    private func updateResult(now: Date) {
        let newResult = EncouragementEngine.encouragement(
            now: now,
            reminders: reminders,
            moodEntries: moodEntries,
            frequency: frequency
        )
        if (currentResult == nil) != (newResult == nil) {
            withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
                currentResult = newResult
            }
        } else {
            currentResult = newResult
        }
    }

    private func bannerContent(_ result: EncouragementEngine.Result) -> some View {
        HStack(spacing: 12) {
            Image(systemName: result.icon)
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
                .frame(width: 28)

            Text(result.message)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
