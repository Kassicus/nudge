//
//  MessageBubble.swift
//  Nudge
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    var showAvatar: Bool = false
    var buddyName: String = "Buddy"
    var emotion: BuddyEmotion? = nil

    private var isBuddy: Bool { message.role == "buddy" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isBuddy {
                if showAvatar {
                    BuddyAvatar(name: buddyName, size: 28, emotion: emotion)
                } else {
                    Spacer().frame(width: 28)
                }
            } else {
                Spacer(minLength: 60)
            }

            Text(message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(bubbleBackground)
                .foregroundColor(isBuddy ? Color.primary : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            if isBuddy {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 8)
    }

    private var bubbleBackground: some ShapeStyle {
        if isBuddy, let tint = emotionTintColor {
            return AnyShapeStyle(tint.opacity(0.12).blendMode(.normal))
        }
        return AnyShapeStyle(isBuddy ? Color(.systemGray5) : Color.blue)
    }

    private var emotionTintColor: Color? {
        guard let emotion else { return nil }
        switch emotion {
        case .neutral:     return nil
        case .proud:       return .blue
        case .excited:     return .purple
        case .celebratory: return .yellow
        case .supportive:  return .green
        case .concerned:   return .orange
        case .welcomeBack: return .teal
        }
    }
}

#Preview {
    VStack(spacing: 4) {
        MessageBubble(
            message: {
                let m = Message(content: "Hey! How did your walk go today?", role: "buddy")
                return m
            }(),
            showAvatar: true,
            buddyName: "Alex",
            emotion: .proud
        )
        MessageBubble(
            message: {
                let m = Message(content: "Yeah I did 35 minutes!", role: "user")
                return m
            }()
        )
        MessageBubble(
            message: {
                let m = Message(content: "Nice work! That's what I like to see!", role: "buddy")
                return m
            }(),
            showAvatar: true,
            buddyName: "Alex",
            emotion: .celebratory
        )
    }
}
