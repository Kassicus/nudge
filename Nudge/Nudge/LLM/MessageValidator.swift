//
//  MessageValidator.swift
//  Nudge
//

import Foundation

struct MessageValidator {
    static func validateBuddyMessage(_ message: String, habitName: String) -> Bool {
        // Too long
        if message.split(separator: " ").count > 60 { return false }

        // Too short (likely error)
        if message.count < 5 { return false }

        // Contains hallucinated content
        let lower = message.lowercased()
        if lower.contains("as an ai") { return false }
        if lower.contains("language model") { return false }
        if lower.contains("i'm an ai") { return false }
        if lower.contains("i am an ai") { return false }

        return true
    }
}
