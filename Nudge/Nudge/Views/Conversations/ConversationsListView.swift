//
//  ConversationsListView.swift
//  Nudge
//

import SwiftUI
import SwiftData

struct ConversationsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "No Habits Yet",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Your buddy conversations will appear here.")
                    )
                } else {
                    List(habits) { habit in
                        let latestConversation = latestConversation(for: habit)

                        NavigationLink {
                            if let conversation = latestConversation, !conversation.isComplete {
                                ChatView(
                                    conversation: conversation,
                                    habit: habit,
                                    engine: ConversationEngine(modelContext: modelContext)
                                )
                            } else {
                                NewCheckInView(habit: habit)
                            }
                        } label: {
                            ConversationRow(
                                habit: habit,
                                conversation: latestConversation
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Nudge")
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let habit = habits.first {
                        NavigationLink {
                            DebugStreakView(habit: habit)
                        } label: {
                            Image(systemName: "ant")
                        }
                    }
                }
            }
            #endif
        }
    }

    private func latestConversation(for habit: Habit) -> Conversation? {
        habit.conversations?
            .sorted { $0.date > $1.date }
            .first
    }
}

// MARK: - New Check-In View (starts a new conversation)

struct NewCheckInView: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    @State private var conversation: Conversation?
    @State private var engine: ConversationEngine?

    var body: some View {
        Group {
            if let conversation, let engine {
                ChatView(conversation: conversation, habit: habit, engine: engine)
            } else {
                ProgressView("Starting check-in...")
                    .task {
                        let eng = ConversationEngine(modelContext: modelContext)
                        let conv = await eng.startCheckIn(for: habit)
                        self.engine = eng
                        self.conversation = conv
                    }
            }
        }
    }
}
