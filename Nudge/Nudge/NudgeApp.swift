//
//  NudgeApp.swift
//  Nudge
//
//  Created by Kason Suchow on 2/7/26.
//

import SwiftUI
import SwiftData
import FoundationModels

@main
struct NudgeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Habit.self,
            CheckIn.self,
            Conversation.self,
            Message.self,
            PreGeneratedMessage.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
