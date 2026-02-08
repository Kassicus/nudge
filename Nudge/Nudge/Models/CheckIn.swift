//
//  CheckIn.swift
//  Nudge
//

import Foundation
import SwiftData

@Model
class CheckIn {
    var id: UUID = UUID()
    var date: Date = Date()
    var status: String = "pending"
    var createdAt: Date = Date()

    var habit: Habit? = nil
    var conversation: Conversation? = nil

    init(date: Date = Date(), status: String = "pending") {
        self.id = UUID()
        self.date = date
        self.status = status
        self.createdAt = Date()
    }
}
