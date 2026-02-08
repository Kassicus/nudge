//
//  BuddyEmotion.swift
//  Nudge
//

import Foundation

enum BuddyEmotion: String, Codable, CaseIterable {
    case neutral
    case proud
    case excited
    case celebratory
    case supportive
    case concerned
    case welcomeBack

    static func calculateEmotionalState(for habit: Habit) -> BuddyEmotion {
        let milestones = [7, 14, 21, 30, 60, 90, 180, 365]

        if milestones.contains(habit.currentStreak) {
            return .celebratory
        }

        if habit.currentStreak > 0 && habit.currentStreak >= habit.longestStreak {
            return .excited
        }

        if habit.currentStreak >= 3 {
            return .proud
        }

        if habit.consecutiveMisses >= 5 {
            return .welcomeBack
        }

        if habit.consecutiveMisses >= 3 {
            return .concerned
        }

        if habit.consecutiveMisses == 1 && habit.currentStreak == 0 {
            if habit.longestStreak > 0 {
                return .supportive
            }
        }

        return .neutral
    }
}
