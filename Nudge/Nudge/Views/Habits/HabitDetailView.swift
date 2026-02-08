//
//  HabitDetailView.swift
//  Nudge
//

import SwiftUI

struct HabitDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let habit: Habit

    @State private var showDeleteConfirmation = false

    private var personality: BuddyPersonality {
        BuddyPersonality(rawValue: habit.buddyPersonality) ?? .supportiveFriend
    }

    private var totalCheckIns: Int {
        habit.checkIns?.count ?? 0
    }

    private var completedCheckIns: Int {
        habit.checkIns?.filter { $0.status == "completed" || $0.status == "partial" }.count ?? 0
    }

    private var completionRate: Double {
        guard totalCheckIns > 0 else { return 0 }
        return Double(completedCheckIns) / Double(totalCheckIns) * 100
    }

    var body: some View {
        List {
            // Buddy section
            Section {
                HStack(spacing: 16) {
                    BuddyAvatar(name: habit.buddyName, size: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.buddyName)
                            .font(.title2)
                            .fontWeight(.semibold)

                        HStack(spacing: 4) {
                            Text(personality.icon)
                            Text(personality.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Habit info
            Section("Habit") {
                LabeledContent("Name", value: habit.name)

                if !habit.habitDescription.isEmpty {
                    LabeledContent("Description", value: habit.habitDescription)
                }

                LabeledContent("Frequency", value: frequencyLabel)

                LabeledContent("Reminder") {
                    Text(reminderTimeString)
                }
            }

            // Stats
            Section("Stats") {
                LabeledContent("Current Streak") {
                    StreakBadge(count: habit.currentStreak)
                }

                LabeledContent("Longest Streak") {
                    HStack(spacing: 3) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text("\(habit.longestStreak)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("Total Check-ins", value: "\(totalCheckIns)")
                LabeledContent("Completion Rate", value: String(format: "%.0f%%", completionRate))
            }

            // Actions
            Section {
                NavigationLink("Edit Habit") {
                    HabitFormView(habit: habit)
                }

                Button("Delete Habit", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete Habit?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                NotificationManager.shared.cancelReminder(for: habit)
                let manager = HabitManager(modelContext: modelContext)
                manager.deleteHabit(habit)
                dismiss()
            }
        } message: {
            Text("This will delete \"\(habit.name)\" and all its check-in history. This can't be undone.")
        }
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

    private var reminderTimeString: String {
        let components = DateComponents(hour: habit.reminderHour, minute: habit.reminderMinute)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(habit.reminderHour):\(String(format: "%02d", habit.reminderMinute))"
    }
}
