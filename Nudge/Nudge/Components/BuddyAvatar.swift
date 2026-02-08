//
//  BuddyAvatar.swift
//  Nudge
//

import SwiftUI

struct BuddyAvatar: View {
    let name: String
    var size: CGFloat = 32
    var emotion: BuddyEmotion? = nil

    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor.gradient)
                .frame(width: size, height: size)

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
        }
        .overlay {
            if let ringColor = emotionRingColor {
                Circle()
                    .strokeBorder(ringColor, lineWidth: size * 0.07)
                    .frame(width: size + size * 0.15, height: size + size * 0.15)
            }
        }
    }

    private var initials: String {
        let components = name.split(separator: " ")
        if let first = components.first?.first {
            return String(first).uppercased()
        }
        return "B"
    }

    private var avatarColor: Color {
        let hash = abs(name.hashValue)
        let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]
        return colors[hash % colors.count]
    }

    private var emotionRingColor: Color? {
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
    HStack(spacing: 20) {
        BuddyAvatar(name: "Alex", emotion: .proud)
        BuddyAvatar(name: "Coach Mike", size: 44, emotion: .celebratory)
        BuddyAvatar(name: "Zen", size: 24, emotion: .concerned)
        BuddyAvatar(name: "Sam", size: 32)
    }
}
