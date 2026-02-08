//
//  QuickReplyBar.swift
//  Nudge
//

import SwiftUI

struct QuickReplyBar: View {
    var onReply: (String) -> Void

    private let replies = [
        ("Yes ✅", "Yes, I did it!"),
        ("Not today", "No, I didn't do it today"),
        ("Partially", "I did some of it but not all")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(replies, id: \.0) { label, value in
                    Button {
                        onReply(value)
                    } label: {
                        Text(label)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    QuickReplyBar { reply in
        print(reply)
    }
}
