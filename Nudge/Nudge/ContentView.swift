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
    @State private var hasSeeded = false

    var body: some View {
        ConversationsListView()
            .task {
                guard !hasSeeded else { return }
                hasSeeded = true

                let manager = HabitManager(modelContext: modelContext)
                if let habit = manager.seedTestHabitIfNeeded() {
                    let engine = ConversationEngine(modelContext: modelContext)
                    let _ = await engine.startCheckIn(for: habit)
                }
            }
    }
}
