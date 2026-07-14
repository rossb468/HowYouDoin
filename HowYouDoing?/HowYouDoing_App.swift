//
//  HowYouDoing_App.swift
//  HowYouDoing?
//
//  Created by Ross Bower on 2/5/26.
//

import SwiftUI
import SwiftData
import UserNotifications
import OSLog

@main
struct HowYouDoing_App: App {
    /// Logger used to annotate persistence events in the console.
    private static let persistenceLog = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "HowYouDoing",
        category: "persistence"
    )

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
            let config = ModelConfiguration(
                cloudKitDatabase: .private("iCloud.com.ross.HowYouDoing-")
            )
            let container = try ModelContainer(for: MoodEntry.self, configurations: config)
            self.modelContainer = container

            // KNOWN BENIGN WARNING:
            // When the CloudKit-backed store loads, Core Data logs:
            //   "'NSKeyedUnarchiveFromData' should not be used to for un-archiving
            //    and will be removed in a future release"
            // This originates from NSPersistentCloudKitContainer's own internal
            // Transformable metadata — NOT from our models. `MoodState` is a
            // String-backed enum persisted as its raw value, so nothing in this
            // app relies on the legacy keyed archiver. The warning is safe to
            // ignore; we log the note below so it has context when it appears.
            Self.persistenceLog.notice("""
            Model container ready. A Core Data \
            'NSKeyedUnarchiveFromData' warning may appear near this point — \
            it comes from the CloudKit store's internal metadata and is \
            expected and safe to ignore.
            """)

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
