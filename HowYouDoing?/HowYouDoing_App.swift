//
//  HowYouDoing_App.swift
//  HowYouDoing?
//
//  Created by Ross Bower on 2/5/26.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct HowYouDoing_App: App {
    let modelContainer: ModelContainer
    private let notificationDelegate: NotificationDelegate

    init() {
        // Ensure the Application Support directory exists before SwiftData
        // attempts to create its store file, avoiding a slow recovery path
        // on first launch on physical devices.
        let fileManager = FileManager.default
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            if !fileManager.fileExists(atPath: appSupport.path()) {
                try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
            }
        }

        do {
            let container = try ModelContainer(for: MoodEntry.self)
            self.modelContainer = container

            let delegate = NotificationDelegate(modelContainer: container)
            self.notificationDelegate = delegate
            UNUserNotificationCenter.current().delegate = delegate

            NotificationManager.registerCategory()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("reminders") private var remindersJSON: String = "[]"
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    WelcomeView()
                }
            }
            #if DEBUG
            .task {
                if UserDefaults.standard.bool(forKey: "debug_alwaysShowWelcome") {
                    hasCompletedOnboarding = false
                }
            }
            #endif
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                NotificationManager.clearBadge()
                let reminders = [Reminder].fromJSON(remindersJSON)
                NotificationManager.scheduleAll(reminders)
            }
        }
    }
}
