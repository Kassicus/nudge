//
//  BuddyAvatar.swift
//  Nudge
//

import SwiftUI

struct BuddyAvatar: View {
    let name: String
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor.gradient)
                .frame(width: size, height: size)

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
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
}

#Preview {
    HStack {
        BuddyAvatar(name: "Alex")
        BuddyAvatar(name: "Coach Mike", size: 44)
        BuddyAvatar(name: "Zen", size: 24)
    }
}
