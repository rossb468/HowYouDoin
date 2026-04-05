//
//  NotificationDelegate.swift
//  HowYouDoing?
//

import Foundation
import UserNotifications
import SwiftData

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
    }

    // MARK: - Foreground Delivery

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    // MARK: - Action Response

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionIdentifier = response.actionIdentifier

        // User tapped a mood action from the notification banner
        if let mood = MoodState.from(actionIdentifier: actionIdentifier) {
            await insertMoodEntry(mood)
            let reminders = currentReminders()
            NotificationManager.resetAndReschedule(reminders)
            return
        }

        // Default tap (opened the app) — just clear badge
        if actionIdentifier == UNNotificationDefaultActionIdentifier {
            NotificationManager.clearBadge()
        }
    }

    // MARK: - Helpers

    @MainActor
    private func insertMoodEntry(_ mood: MoodState) {
        let context = modelContainer.mainContext
        let entry = MoodEntry(moodState: mood)
        context.insert(entry)
        try? context.save()
    }

    private func currentReminders() -> [Reminder] {
        let json = UserDefaults.standard.string(forKey: "reminders") ?? "[]"
        return [Reminder].fromJSON(json)
    }
}
