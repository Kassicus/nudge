//
//  Habit.swift
//  Nudge
//

import Foundation
import SwiftData

@Model
class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var habitDescription: String = ""
    var buddyName: String = "Buddy"
    var buddyPersonality: String = BuddyPersonality.supportiveFriend.rawValue
    var frequency: String = "daily"
    var scheduledDays: [Int]? = []
    var reminderHour: Int = 20
    var reminderMinute: Int = 0
    var isActive: Bool = true
    var createdAt: Date = Date()

    // Streak tracking
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var consecutiveMisses: Int = 0
    var lastCompletedDate: Date? = nil
    var lastCheckInDate: Date? = nil

    // Relationships
    @Relationship(deleteRule: .cascade)
    var checkIns: [CheckIn]? = []

    @Relationship(deleteRule: .cascade)
    var conversations: [Conversation]? = []

    @Relationship(deleteRule: .cascade)
    var preGeneratedMessages: [PreGeneratedMessage]? = []

    init(
        name: String = "",
        habitDescription: String = "",
        buddyName: String = "Buddy",
        buddyPersonality: BuddyPersonality = .supportiveFriend,
        frequency: String = "daily",
        reminderHour: Int = 20,
        reminderMinute: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.habitDescription = habitDescription
        self.buddyName = buddyName
        self.buddyPersonality = buddyPersonality.rawValue
        self.frequency = frequency
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.isActive = true
        self.createdAt = Date()
    }
}
