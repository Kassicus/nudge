//
//  PersonalityCard.swift
//  Nudge
//

import SwiftUI

struct PersonalityCard: View {
    let personality: BuddyPersonality
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(personality.icon)
                    .font(.system(size: 32))

                Text(personality.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(personality.tagline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        PersonalityCard(personality: .supportiveFriend, isSelected: true) {}
        PersonalityCard(personality: .toughCoach, isSelected: false) {}
        PersonalityCard(personality: .chillCompanion, isSelected: false) {}
        PersonalityCard(personality: .hypePartner, isSelected: false) {}
    }
    .padding()
}
