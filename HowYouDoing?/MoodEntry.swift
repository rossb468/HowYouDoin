//
//  MoodEntry.swift
//  HowYouDoing?
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - App Color Palette

extension Color {
    // Greens — used for Good / Great
    static let moodGreen      = Color(red: 0.30, green: 0.78, blue: 0.55)  // #4DC78C
    static let moodGreenDark  = Color(red: 0.20, green: 0.62, blue: 0.43)  // #339E6E

    // Reds — used for Bad / Terrible
    static let moodRed        = Color(red: 0.92, green: 0.34, blue: 0.38)  // #EB5761
    static let moodRedDark    = Color(red: 0.76, green: 0.22, blue: 0.27)  // #C23845

    // Blues — used for Meh / Neutral
    static let moodBlue       = Color(red: 0.36, green: 0.56, blue: 0.92)  // #5C8FEB
    static let moodBlueDark   = Color(red: 0.25, green: 0.43, blue: 0.76)  // #406EC2
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
}

@Model
final class MoodEntry {
    var moodState: MoodState
    var date: Date

    init(moodState: MoodState, date: Date = Date()) {
        self.moodState = moodState
        self.date = date
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
