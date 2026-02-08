//
//  HabitsListView.swift
//  Nudge
//

import SwiftUI
import SwiftData

struct HabitsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Habit> { $0.isActive },
        sort: \Habit.createdAt, order: .reverse
    ) private var habits: [Habit]

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "No Habits Yet",
                        systemImage: "list.bullet.circle",
                        description: Text("Tap + to create your first habit.")
                    )
                } else {
                    List {
                        ForEach(habits) { habit in
                            NavigationLink {
                                HabitDetailView(habit: habit)
                            } label: {
                                HabitRow(habit: habit)
                            }
                        }
                        .onDelete(perform: deleteHabits)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        HabitFormView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func deleteHabits(at offsets: IndexSet) {
        let manager = HabitManager(modelContext: modelContext)
        for index in offsets {
            let habit = habits[index]
            NotificationManager.shared.cancelReminder(for: habit)
            manager.deleteHabit(habit)
        }
    }
}

// MARK: - Habit Row

private struct HabitRow: View {
    let habit: Habit

    private var personality: BuddyPersonality {
        BuddyPersonality(rawValue: habit.buddyPersonality) ?? .supportiveFriend
    }

    var body: some View {
        HStack(spacing: 12) {
            BuddyAvatar(name: habit.buddyName, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(habit.name)
                        .font(.headline)

                    Spacer()

                    StreakBadge(count: habit.currentStreak)
                }

                HStack {
                    Text(habit.buddyName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.secondary)

                    Text(frequencyLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var frequencyLabel: String {
        switch habit.frequency {
        case "daily":    return "Daily"
        case "weekdays": return "Weekdays"
        case "weekends": return "Weekends"
        case "custom":   return "Custom"
        default:         return habit.frequency.capitalized
        }
    }
}
