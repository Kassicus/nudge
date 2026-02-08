//
//  Conversation.swift
//  Nudge
//

import Foundation
import SwiftData

@Model
class Conversation {
    var id: UUID = UUID()
    var date: Date = Date()
    var isComplete: Bool = false
    var emotionalState: String = "neutral"
    var createdAt: Date = Date()

    var habit: Habit? = nil
    var checkIn: CheckIn? = nil

    @Relationship(deleteRule: .cascade)
    var messages: [Message]? = []

    init(date: Date = Date(), emotionalState: String = "neutral") {
        self.id = UUID()
        self.date = date
        self.isComplete = false
        self.emotionalState = emotionalState
        self.createdAt = Date()
    }
}
