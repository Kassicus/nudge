//
//  StreakBadge.swift
//  Nudge
//

import SwiftUI

struct StreakBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    VStack {
        StreakBadge(count: 0)
        StreakBadge(count: 5)
        StreakBadge(count: 30)
    }
}
