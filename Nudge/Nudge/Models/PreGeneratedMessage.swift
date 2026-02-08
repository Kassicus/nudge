//
//  PreGeneratedMessage.swift
//  Nudge
//

import Foundation
import SwiftData

@Model
class PreGeneratedMessage {
    var id: UUID = UUID()
    var targetDate: Date = Date()
    var content: String = ""
    var isUsed: Bool = false
    var createdAt: Date = Date()

    var habit: Habit? = nil

    init(targetDate: Date = Date(), content: String = "") {
        self.id = UUID()
        self.targetDate = targetDate
        self.content = content
        self.isUsed = false
        self.createdAt = Date()
    }
}
