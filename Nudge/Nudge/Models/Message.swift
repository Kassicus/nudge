//
//  Message.swift
//  Nudge
//

import Foundation
import SwiftData

@Model
class Message {
    var id: UUID = UUID()
    var content: String = ""
    var role: String = "buddy"
    var timestamp: Date = Date()
    var isStreaming: Bool = false

    var conversation: Conversation? = nil

    init(content: String = "", role: String = "buddy", timestamp: Date = Date()) {
        self.id = UUID()
        self.content = content
        self.role = role
        self.timestamp = timestamp
        self.isStreaming = false
    }
}
