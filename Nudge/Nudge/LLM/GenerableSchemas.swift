//
//  GenerableSchemas.swift
//  Nudge
//

import Foundation
import FoundationModels

@Generable
struct CheckInResult {
    @Guide(description: "The user's habit completion status based on their response")
    var status: CheckInStatus

    @Guide(description: "A short, casual buddy response under 40 words matching the emotional state")
    var buddyMessage: String

    @Guide(description: "Whether to ask a follow-up question or end the check-in")
    var shouldFollowUp: Bool

    @Guide(description: "If following up, the follow-up question. Empty string if not following up.")
    var followUpMessage: String
}

@Generable
enum CheckInStatus: String {
    case completed
    case partial
    case missed
    case skipped
    case unclear
}

@Generable
struct OpeningMessage {
    @Guide(description: "A casual, friendly opening check-in message under 30 words")
    var message: String
}
