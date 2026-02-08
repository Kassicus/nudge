//
//  HabitScheduleHelpers.swift
//  Nudge
//

import Foundation

struct HabitScheduleHelpers {

    /// Checks if a habit is due on a given date based on its frequency and scheduled days.
    /// - Parameters:
    ///   - habit: The habit to check.
    ///   - date: The date to evaluate.
    /// - Returns: `true` if the habit is due on that date.
    static func isDue(_ habit: Habit, on date: Date) -> Bool {
        let calendar = Calendar.current
        // weekday: 1=Sunday, 2=Monday, ..., 7=Saturday
        let weekday = calendar.component(.weekday, from: date)

        switch habit.frequency {
        case "daily":
            return true
        case "weekdays":
            return (2...6).contains(weekday)
        case "weekends":
            return weekday == 1 || weekday == 7
        case "custom":
            // scheduledDays stores weekday numbers (1-7)
            return habit.scheduledDays?.contains(weekday) ?? false
        default:
            return true
        }
    }
}
