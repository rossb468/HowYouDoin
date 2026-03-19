//
//  HowYouDoing_App.swift
//  HowYouDoing?
//
//  Created by Ross Bower on 2/5/26.
//

import SwiftUI
import SwiftData

@main
struct HowYouDoing_App: App {
    let modelContainer: ModelContainer

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
            modelContainer = try ModelContainer(for: MoodEntry.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                WelcomeView()
            }
        }
        .modelContainer(modelContainer)
    }
}
