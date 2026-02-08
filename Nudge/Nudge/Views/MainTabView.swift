//
//  MainTabView.swift
//  Nudge
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ConversationsListView()
                .tabItem {
                    Label("Buddies", systemImage: "bubble.left.and.bubble.right")
                }

            HabitsListView()
                .tabItem {
                    Label("Habits", systemImage: "list.bullet.circle")
                }
        }
    }
}
