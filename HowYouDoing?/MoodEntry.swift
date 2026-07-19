//
//  MoodEntry.swift
//  HowYouDoing?
//

import Foundation
import SwiftUI
import SwiftData
import UIKit

// MARK: - Theming

enum AppTheme: String, CaseIterable, Identifiable {
    case standard
    case pink

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "Default"
        case .pink:     return "Pink"
        }
    }

    /// Active theme, resolved from persisted settings. The theme-aware `Color`
    /// palette below reads this so any render reflects the current theme.
    static var current: AppTheme {
        AppTheme(rawValue: UserDefaults.standard.string(forKey: "appTheme") ?? "") ?? .standard
    }

    var palette: ThemePalette {
        switch self {
        case .standard: return .standard
        case .pink:     return .pink
        }
    }
}

/// Colors for every themed role in the app.
struct ThemePalette {
    // Mood colors, keyed to MoodState roles.
    let great: Color
    let good: Color
    let neutral: Color
    let bad: Color
    let terrible: Color
    // Shared UI roles.
    let accent: Color
    let background: Color
    let groupedBackground: Color
    let grabber: Color
    /// Tint applied to the mood panel's glass. `.clear` means untinted glass.
    let panelGlassTint: Color
    // Text roles. `onBackground` sits over the pink page/panel; `onField`/
    // `onFieldSecondary` sit over the light grouped fields.
    let textOnBackground: Color
    let textOnField: Color
    let textOnFieldSecondary: Color
    /// Hairline border around grouped fields. `.clear` means no border.
    let fieldBorder: Color

    static let standard = ThemePalette(
        great:    Color(red: 0.10, green: 0.60, blue: 0.25),
        good:     Color(red: 0.20, green: 0.78, blue: 0.35),
        neutral:  Color(red: 0.00, green: 0.53, blue: 1.00),
        bad:      Color(red: 1.00, green: 0.22, blue: 0.24),
        terrible: Color(red: 0.85, green: 0.12, blue: 0.15),
        accent:   Color(red: 0.00, green: 0.53, blue: 1.00),
        background: Color(uiColor: .systemBackground),
        groupedBackground: Color(uiColor: .secondarySystemGroupedBackground),
        grabber: Color(uiColor: .systemGray2),
        panelGlassTint: .clear,
        textOnBackground: Color(uiColor: .label),
        textOnField: Color(uiColor: .label),
        textOnFieldSecondary: Color(uiColor: .secondaryLabel),
        fieldBorder: .clear
    )

    /// Every role rendered as a distinct shade of pink. Text over the pink page
    /// is white; text over the light grouped fields is dark pink.
    static let pink = ThemePalette(
        great:    Color(red: 0.86, green: 0.10, blue: 0.52),
        good:     Color(red: 1.00, green: 0.44, blue: 0.71),
        neutral:  Color(red: 0.99, green: 0.72, blue: 0.82),
        bad:      Color(red: 0.82, green: 0.42, blue: 0.56),
        terrible: Color(red: 0.49, green: 0.13, blue: 0.31),
        accent:   Color(red: 0.78, green: 0.20, blue: 0.44),
        background: Color(red: 0.97, green: 0.78, blue: 0.87),
        groupedBackground: Color(red: 1.00, green: 0.96, blue: 0.98),
        grabber: Color(red: 0.72, green: 0.32, blue: 0.48),
        panelGlassTint: Color(red: 1.00, green: 0.72, blue: 0.83),
        textOnBackground: .white,
        textOnField: Color(red: 0.58, green: 0.09, blue: 0.33),
        textOnFieldSecondary: Color(red: 0.64, green: 0.30, blue: 0.46),
        fieldBorder: Color(red: 0.80, green: 0.42, blue: 0.58).opacity(0.35)
    )
}

// MARK: - App Color Palette (theme-aware)

extension Color {
    static var moodGreen: Color     { AppTheme.current.palette.good }
    static var moodGreenDark: Color { AppTheme.current.palette.great }
    static var moodRed: Color       { AppTheme.current.palette.bad }
    static var moodRedDark: Color   { AppTheme.current.palette.terrible }
    static var moodBlue: Color      { AppTheme.current.palette.neutral }
    static var moodBlueDark: Color  { AppTheme.current.palette.accent }

    static var themeAccent: Color            { AppTheme.current.palette.accent }
    static var themeBackground: Color        { AppTheme.current.palette.background }
    static var themeGroupedBackground: Color { AppTheme.current.palette.groupedBackground }
    static var themeGrabber: Color           { AppTheme.current.palette.grabber }
    static var themeTextOnBackground: Color     { AppTheme.current.palette.textOnBackground }
    static var themeTextOnField: Color          { AppTheme.current.palette.textOnField }
    static var themeTextOnFieldSecondary: Color { AppTheme.current.palette.textOnFieldSecondary }
    static var themeFieldBorder: Color          { AppTheme.current.palette.fieldBorder }
}

extension View {
    /// Hides the default scroll/grouped background and applies the themed page
    /// wash. Use on the root of a screen or a List/Form so the theme shows through.
    func themedScrollBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground.ignoresSafeArea())
    }
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
