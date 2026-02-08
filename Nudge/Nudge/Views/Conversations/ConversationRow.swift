//
//  ConversationRow.swift
//  Nudge
//

import SwiftUI

struct ConversationRow: View {
    let habit: Habit
    let conversation: Conversation?

    private var lastMessage: Message? {
        guard let messages = conversation?.messages else { return nil }
        return messages.max(by: { $0.timestamp < $1.timestamp })
    }

    private var emotion: BuddyEmotion? {
        guard let state = conversation?.emotionalState else { return nil }
        return BuddyEmotion(rawValue: state)
    }

    var body: some View {
        HStack(spacing: 12) {
            BuddyAvatar(name: habit.buddyName, size: 48, emotion: emotion)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(habit.buddyName)
                        .font(.headline)

                    Spacer()

                    if let timestamp = lastMessage?.timestamp {
                        Text(DateHelpers.relativeTimeString(for: timestamp))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text(habit.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    StreakBadge(count: habit.currentStreak)
                }

                if let preview = lastMessage?.content {
                    Text(preview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
