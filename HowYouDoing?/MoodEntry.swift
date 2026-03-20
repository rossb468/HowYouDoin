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


enum MoodState: String, Codable, Equatable {
    case great
    case good
    case bad
    case terrible
    case neutral

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

@Model
final class MoodEntry {
    var moodState: MoodState
    var date: Date

    init(moodState: MoodState, date: Date = Date()) {
        self.moodState = moodState
        self.date = date
    }

    /// Formatted time string (e.g. "2:30 PM").
    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// Returns a human-readable day label relative to now (no time component).
    static func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: date, to: now)

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let days = components.day, days < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM dd"
            return formatter.string(from: date)
        }
    }

    /// Returns a human-readable date label relative to now.
    /// Includes time when multiple entries share the same day.
    func dateLabel(in entries: [MoodEntry]) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: date, to: now)
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today'"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "'Yesterday'"
        } else if let days = components.day, days < 7 {
            formatter.dateFormat = "EEEE"
        } else {
            formatter.dateFormat = "MMMM dd"
        }

        let sameDayCount = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
        if sameDayCount > 1 {
            formatter.dateFormat += " 'at' h:mm a"
        }

        return formatter.string(from: date)
    }
}
