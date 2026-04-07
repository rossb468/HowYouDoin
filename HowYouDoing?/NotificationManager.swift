//
//  NotificationManager.swift
//  HowYouDoing?
//

import Foundation
import UserNotifications

// MARK: - Reminder Model

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var hour: Int
    var minute: Int
    var title: String
    var body: String
    var isEnabled: Bool = true

    /// Formatted time string (e.g. "8:00 AM").
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    /// Default reminders offered on first launch.
    static let defaults: [Reminder] = [
        Reminder(hour: 8, minute: 0, title: "Good Morning", body: "Start the day — how are you feeling?"),
        Reminder(hour: 20, minute: 0, title: "How You Doin'?", body: "Time to check in with yourself.")
    ]
}

// MARK: - AppStorage Helper

extension Array where Element == Reminder {
    /// Encode reminders to a JSON string for AppStorage.
    var jsonString: String {
        let data = (try? JSONEncoder().encode(self)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    /// Decode reminders from a JSON string.
    static func fromJSON(_ string: String) -> [Reminder] {
        guard let data = string.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([Reminder].self, from: data)) ?? []
    }
}

// MARK: - Notification Manager

struct NotificationManager {
    private static let identifierPrefix = "moodReminder-"
    static let categoryIdentifier = "moodCheckIn"

    /// Checks whether the app is authorized to post notifications.
    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    /// Requests notification permission. Returns `true` if granted.
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Registers the interactive notification category with one action per MoodState.
    /// Reads the `openAppOnMoodAction` preference to decide whether actions launch the app.
    static func registerCategory() {
        let openApp = UserDefaults.standard.bool(forKey: "openAppOnMoodAction")
        let actionOptions: UNNotificationActionOptions = openApp ? [.foreground] : []
        let actions = MoodState.allCases.map { mood in
            UNNotificationAction(
                identifier: mood.actionIdentifier,
                title: "\(mood.emoji) \(mood.displayString)",
                options: actionOptions
            )
        }
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: actions,
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Requests permission and schedules the default reminders.
    /// Returns the default reminders array if permission was granted, or an empty array.
    @discardableResult
    static func requestPermissionAndScheduleDefaults() async -> [Reminder] {
        let granted = await requestPermission()
        if granted {
            let defaults = Reminder.defaults
            scheduleAll(defaults)
            return defaults
        }
        return []
    }

    /// Cancels all mood reminders, then schedules individual non-repeating
    /// notifications for each enabled reminder over the next N days,
    /// with incrementing badge numbers starting from 1.
    static func scheduleAll(_ reminders: [Reminder]) {
        let center = UNUserNotificationCenter.current()

        // Remove all existing mood reminders
        center.getPendingNotificationRequests { requests in
            let moodIDs = requests
                .filter { $0.identifier.hasPrefix(identifierPrefix) }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: moodIDs)

            let enabledReminders = reminders.filter(\.isEnabled)
            guard !enabledReminders.isEmpty else { return }

            let maxNotifications = 64
            let daysAhead = max(maxNotifications / max(enabledReminders.count, 1), 1)

            let calendar = Calendar.current
            let now = Date()
            var badgeNumber = 1

            for dayOffset in 0..<daysAhead {
                guard let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

                for reminder in enabledReminders {
                    guard badgeNumber <= maxNotifications else { return }

                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDay)
                    dateComponents.hour = reminder.hour
                    dateComponents.minute = reminder.minute

                    // Skip notifications in the past
                    if let fireDate = calendar.date(from: dateComponents), fireDate <= now {
                        continue
                    }

                    let content = UNMutableNotificationContent()
                    content.title = reminder.title
                    content.body = reminder.body
                    content.sound = .default
                    content.badge = NSNumber(value: badgeNumber)
                    content.categoryIdentifier = categoryIdentifier

                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: dateComponents,
                        repeats: false
                    )
                    let identifier = "\(identifierPrefix)\(reminder.id.uuidString)-\(dayOffset)"
                    let request = UNNotificationRequest(
                        identifier: identifier,
                        content: content,
                        trigger: trigger
                    )
                    center.add(request)
                    badgeNumber += 1
                }
            }
        }
    }

    /// Clears the app badge to zero.
    static func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    /// Clears the badge and reschedules all notifications from badge 1.
    /// Call this whenever the user logs a mood.
    static func resetAndReschedule(_ reminders: [Reminder]) {
        clearBadge()
        scheduleAll(reminders)
    }

    #if DEBUG
    /// Schedules a one-off test reminder that fires in 1 minute.
    /// Not saved to the reminders list.
    static func scheduleDebugReminder() {
        let content = UNMutableNotificationContent()
        content.title = "How You Doin'?"
        content.body = "Test reminder"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = categoryIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let request = UNNotificationRequest(
            identifier: "debugReminder-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
    #endif

    /// Cancels all mood reminders and clears the badge.
    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let moodIDs = requests
                .filter { $0.identifier.hasPrefix(identifierPrefix) }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: moodIDs)
        }
        clearBadge()
    }
}
