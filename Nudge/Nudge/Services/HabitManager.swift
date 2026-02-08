//
//  HabitManager.swift
//  Nudge
//

import Foundation
import SwiftData

@Observable
class HabitManager {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD

    func createHabit(
        name: String,
        description: String = "",
        buddyName: String = "Buddy",
        personality: BuddyPersonality = .supportiveFriend,
        frequency: String = "daily",
        reminderHour: Int = 20,
        reminderMinute: Int = 0
    ) -> Habit {
        let habit = Habit(
            name: name,
            habitDescription: description,
            buddyName: buddyName,
            buddyPersonality: personality,
            frequency: frequency,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute
        )
        modelContext.insert(habit)
        try? modelContext.save()
        return habit
    }

    func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
        try? modelContext.save()
    }

    // MARK: - Queries

    func fetchAllHabits() -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func hasAnyHabits() -> Bool {
        let descriptor = FetchDescriptor<Habit>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    // MARK: - Test Data Seeding

    func seedTestHabitIfNeeded() -> Habit? {
        guard !hasAnyHabits() else { return nil }

        let habit = createHabit(
            name: "30-Minute Walk",
            description: "Take a 30-minute walk outside",
            buddyName: "Alex",
            personality: .supportiveFriend,
            frequency: "daily",
            reminderHour: 20,
            reminderMinute: 0
        )

        return habit
    }
}
