//
//  WelcomeView.swift
//  HowYouDoing?
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("reminders") private var remindersJSON: String = "[]"
    @State private var showPermissionDeniedAlert = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon and title
            VStack(spacing: 16) {
                Text("👋")
                    .font(.system(size: 72))

                Text("How You Doin'?")
                    .font(.largeTitle.bold())

                Text("Track your mood every day.\nWe can remind you morning and evening.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    triggerHaptic()
                    Task {
                        let scheduled = await NotificationManager.requestPermissionAndScheduleDefaults()
                        if !scheduled.isEmpty {
                            remindersJSON = scheduled.jsonString
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                hasCompletedOnboarding = true
                            }
                        } else {
                            showPermissionDeniedAlert = true
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                        Text("Set Up Reminders")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.glass(.regular.tint(.moodGreen)))

                Button {
                    triggerHaptic()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("Skip")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.glass)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .alert("Notifications Disabled", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Skip") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    hasCompletedOnboarding = true
                }
            }
        } message: {
            Text("To receive daily reminders, please enable notifications in Settings.")
        }
    }
}
