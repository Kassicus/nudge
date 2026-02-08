//
//  BuddyTools.swift
//  Nudge
//

import Foundation
import FoundationModels

struct HabitStreakTool: Tool {
    let name: String = "getHabitStreak"
    let description: String = "Returns the user's current streak data for their habit, including current streak, longest streak, consecutive misses, and last completed date."

    @Generable
    struct Arguments {
        @Guide(description: "Reason for looking up streak data, e.g. 'check progress' or 'motivate user'")
        var reason: String
    }

    // Thread-safe snapshot of habit data captured at init
    private let habitName: String
    private let currentStreak: Int
    private let longestStreak: Int
    private let consecutiveMisses: Int
    private let lastCompletedDescription: String

    init(habit: Habit) {
        self.habitName = habit.name
        self.currentStreak = habit.currentStreak
        self.longestStreak = habit.longestStreak
        self.consecutiveMisses = habit.consecutiveMisses
        self.lastCompletedDescription = habit.lastCompletedDate?.formatted(date: .abbreviated, time: .omitted) ?? "never"
    }

    func call(arguments: Arguments) async throws -> String {
        """
        Habit: \(habitName)
        Current streak: \(currentStreak) days
        Longest streak: \(longestStreak) days
        Consecutive misses: \(consecutiveMisses)
        Last completed: \(lastCompletedDescription)
        """
    }
}
