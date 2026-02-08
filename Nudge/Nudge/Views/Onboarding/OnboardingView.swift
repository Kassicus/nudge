//
//  OnboardingView.swift
//  Nudge
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var onboardingCompleted: Bool

    var body: some View {
        OnboardingChatView {
            onboardingCompleted = true
        }
        .environment(\.modelContext, modelContext)
    }
}
