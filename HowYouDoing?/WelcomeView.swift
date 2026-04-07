//
//  WelcomeView.swift
//  HowYouDoing?
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("reminders") private var remindersJSON: String = "[]"
    @State private var showPermissionDeniedAlert = false
    @State private var showReminderSetup = false
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var reminderMessage = "How are you?"

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon and title
            VStack(spacing: 16) {
                Text("👋")
                    .font(.system(size: 72))

                Text("How You Doin'?")
                    .font(.largeTitle.bold())

                Text(showReminderSetup
                     ? "Set up a daily reminder\nto check in with yourself."
                     : "Track your mood every day.\nWe can remind you to check in.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if showReminderSetup {
                // Inline reminder editor
                VStack(spacing: 0) {
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)

                    Divider()
                        .padding(.leading, 18)

                    HStack {
                        Text("Message")
                        Spacer()
                        TextField("How are you?", text: $reminderMessage)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                if showReminderSetup {
                    Button {
                        triggerHaptic()
                        Task {
                            let granted = await NotificationManager.requestPermission()
                            if granted {
                                let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                                let reminder = Reminder(
                                    hour: components.hour ?? 20,
                                    minute: components.minute ?? 0,
                                    title: "How You Doin'?",
                                    body: reminderMessage.isEmpty ? "How are you?" : reminderMessage
                                )
                                let reminders = [reminder]
                                remindersJSON = reminders.jsonString
                                NotificationManager.scheduleAll(reminders)
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
                            Text("Enable Reminder")
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
                            showReminderSetup = false
                        }
                    } label: {
                        Text("Back")
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.glass)
                } else {
                    Button {
                        triggerHaptic()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showReminderSetup = true
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
