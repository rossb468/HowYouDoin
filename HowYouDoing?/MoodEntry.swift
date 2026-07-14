//
//  MoodEntry.swift
//  HowYouDoing?
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - App Color Palette

extension Color {
    static let moodGreen      = Color(red: 0.20, green: 0.78, blue: 0.35)  // #34C759
    static let moodGreenDark  = Color(red: 0.10, green: 0.60, blue: 0.25)  // #1A9940
    static let moodRed        = Color(red: 1.00, green: 0.22, blue: 0.24)  // #FF383C
    static let moodRedDark    = Color(red: 0.85, green: 0.12, blue: 0.15)  // #D91F26
    static let moodBlue       = Color(red: 0.00, green: 0.53, blue: 1.00)  // #0088FF
    static let moodBlueDark   = Color(red: 0.00, green: 0.40, blue: 0.85)  // #0066D9
}


/// The set of moods a user can log.
///
/// `Codable` conformance is REQUIRED by SwiftData's `@Model` macro to synthesize
/// the persisted-property accessors for `MoodEntry.moodState`; removing it breaks
/// compilation. Because the enum is `String`-backed it is stored as its raw value
/// (not via a value transformer), so it does not cause the benign
/// `NSKeyedUnarchiveFromData` console warning — that comes from the CloudKit
/// store's internal metadata. See `HowYouDoing_App.init()`.
enum MoodState: String, Codable, Equatable, CaseIterable {
    case great
    case good
    case neutral
    case bad
    case terrible

    var displayString: String {
        switch self {
        case .great:    return "Great!"
        case .good:     return "Good"
        case .bad:      return "Bad"
        case .terrible: return "Terrible"
        case .neutral:  return "Meh"
        }
    }

    var emoji: String {
        switch self {
        case .great:    return "🤩"
        case .good:     return "😊"
        case .bad:      return "😞"
        case .terrible: return "😢"
        case .neutral:  return "😐"
        }
    }

    /// Primary color used for buttons and card backgrounds.
    var color: Color {
        switch self {
        case .great:    return .moodGreenDark
        case .good:     return .moodGreen
        case .bad:      return .moodRed
        case .terrible: return .moodRedDark
        case .neutral:  return .moodBlue
        }
    }

    /// Identifier used for UNNotificationAction (e.g. "mood_great").
    var actionIdentifier: String {
        "mood_\(rawValue)"
    }

    /// Resolve a MoodState from a notification action identifier.
    static func from(actionIdentifier: String) -> MoodState? {
        guard actionIdentifier.hasPrefix("mood_") else { return nil }
        let raw = String(actionIdentifier.dropFirst(5))
        return MoodState(rawValue: raw)
    }

    /// Maps CSV mood strings (e.g. Daylio export) to MoodState.
    static func fromCSV(_ value: String) -> MoodState? {
        switch value.lowercased().trimmingCharacters(in: .whitespaces) {
        case "rad":       return .great
        case "good":      return .good
        case "meh":       return .neutral
        case "bad":       return .bad
        case "awful":     return .terrible
        default:          return nil
        }
    }
}

// Shared DateFormatter instances — formatter initialization is one of the
// slowest things in Foundation, so we cache one of each format we use.
private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    return f
}()
private let weekdayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "EEEE"
    return f
}()
private let dayOfMonthFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "d"
    return f
}()
private let shortMonthFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMM"
    return f
}()

@Model
final class MoodEntry {
    var moodState: MoodState = MoodState.neutral
    var date: Date = Date()

    init(moodState: MoodState, date: Date = Date()) {
        self.moodState = moodState
        self.date = date
    }

    /// Formatted time string (e.g. "2:30 PM").
    var timeLabel: String {
        timeFormatter.string(from: date)
    }

    /// Day of week name (e.g. "Monday", "Today", "Yesterday").
    var dayOfWeekLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return weekdayFormatter.string(from: date)
        }
    }

    /// Day of the month number (e.g. "20").
    var dayOfMonthLabel: String {
        dayOfMonthFormatter.string(from: date)
    }

    /// Short month name (e.g. "Mar").
    var shortMonthLabel: String {
        shortMonthFormatter.string(from: date)
    }
}
