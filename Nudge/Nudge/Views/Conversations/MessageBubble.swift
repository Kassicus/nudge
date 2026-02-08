//
//  MessageBubble.swift
//  Nudge
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    var showAvatar: Bool = false
    var buddyName: String = "Buddy"

    private var isBuddy: Bool { message.role == "buddy" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isBuddy {
                if showAvatar {
                    BuddyAvatar(name: buddyName, size: 28)
                } else {
                    Spacer().frame(width: 28)
                }
            } else {
                Spacer(minLength: 60)
            }

            Text(message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isBuddy ? Color(.systemGray5) : Color.blue)
                .foregroundColor(isBuddy ? Color.primary : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            if isBuddy {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    VStack(spacing: 4) {
        MessageBubble(
            message: {
                let m = Message(content: "Hey! How did your walk go today? 🚶", role: "buddy")
                return m
            }(),
            showAvatar: true,
            buddyName: "Alex"
        )
        MessageBubble(
            message: {
                let m = Message(content: "Yeah I did 35 minutes!", role: "user")
                return m
            }()
        )
        MessageBubble(
            message: {
                let m = Message(content: "Nice work! That's what I like to see! ✅", role: "buddy")
                return m
            }(),
            showAvatar: true,
            buddyName: "Alex"
        )
    }
}
