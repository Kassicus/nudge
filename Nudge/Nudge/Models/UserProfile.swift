//
//  UserProfile.swift
//  Nudge
//

import Foundation
import SwiftData

@Model
class UserProfile {
    var name: String = ""
    var timezone: String = TimeZone.current.identifier
    var onboardingCompleted: Bool = false
    var createdAt: Date = Date()

    init(name: String = "", timezone: String = TimeZone.current.identifier, onboardingCompleted: Bool = false) {
        self.name = name
        self.timezone = timezone
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = Date()
    }
}
