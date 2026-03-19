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

    /// Requests notification permission. Returns `true` if granted.
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
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

    /// Cancels all mood reminders, then schedules all enabled ones.
    static func scheduleAll(_ reminders: [Reminder]) {
        let center = UNUserNotificationCenter.current()

        // Remove all existing mood reminders
        let ids = reminders.map { identifierPrefix + $0.id.uuidString }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        // Also do a blanket removal of anything with our prefix
        center.getPendingNotificationRequests { requests in
            let moodIDs = requests
                .filter { $0.identifier.hasPrefix(identifierPrefix) }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: moodIDs)
        }

        // Schedule enabled reminders
        for reminder in reminders where reminder.isEnabled {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = reminder.hour
            dateComponents.minute = reminder.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: identifierPrefix + reminder.id.uuidString,
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    /// Cancels all mood reminders.
    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let moodIDs = requests
                .filter { $0.identifier.hasPrefix(identifierPrefix) }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: moodIDs)
        }
    }
}
