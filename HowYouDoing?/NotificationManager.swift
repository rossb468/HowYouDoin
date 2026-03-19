//
//  NotificationManager.swift
//  HowYouDoing?
//

import UserNotifications

struct NotificationManager {
    static let reminderIdentifier = "dailyMoodReminder"

    /// Requests notification permission and schedules a daily 8 PM reminder if granted.
    /// Returns `true` if the reminder was successfully scheduled.
    @discardableResult
    static func requestPermissionAndSchedule() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                scheduleReminder()
                return true
            }
            return false
        } catch {
            return false
        }
    }

    /// Schedules a daily notification at 8:00 PM local time.
    static func scheduleReminder() {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "How You Doin'?"
        content.body = "Time to check in with yourself."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

        center.add(request)
    }

    /// Cancels the daily reminder.
    static func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }

    /// Checks whether a daily reminder is currently scheduled.
    static func isReminderScheduled() async -> Bool {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.contains { $0.identifier == reminderIdentifier }
    }
}
