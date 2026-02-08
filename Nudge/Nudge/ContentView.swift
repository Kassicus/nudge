//
//  ContentView.swift
//  Nudge
//
//  Created by Kason Suchow on 2/7/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var hasInitialized = false
    @State private var onboardingCompleted = false

    private var needsOnboarding: Bool {
        !onboardingCompleted
    }

    var body: some View {
        Group {
            if needsOnboarding {
                OnboardingView(onboardingCompleted: $onboardingCompleted)
            } else {
                MainTabView()
                    .task {
                        guard !hasInitialized else { return }
                        hasInitialized = true

                        let manager = HabitManager(modelContext: modelContext)
                        manager.reconcileMissedCheckIns()

                        #if DEBUG
                        if let habit = manager.seedDebugHabitIfNeeded() {
                            let engine = ConversationEngine(modelContext: modelContext)
                            let _ = await engine.startCheckIn(for: habit)
                        }
                        #endif
                    }
            }
        }
        .onAppear {
            // TODO: Remove this override — forces onboarding every launch for testing
            onboardingCompleted = false
            // onboardingCompleted = profiles.first?.onboardingCompleted ?? false
        }
    }
}
