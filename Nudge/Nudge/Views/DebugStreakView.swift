//
//  DebugStreakView.swift
//  Nudge
//

#if DEBUG
import SwiftUI
import SwiftData

struct DebugStreakView: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext

    private var currentEmotion: BuddyEmotion {
        BuddyEmotion.calculateEmotionalState(for: habit)
    }

    var body: some View {
        Form {
            Section("Current Emotion") {
                HStack {
                    Text(currentEmotion.rawValue)
                        .font(.title2.bold())
                    Spacer()
                    BuddyAvatar(name: habit.buddyName, size: 44, emotion: currentEmotion)
                }
            }

            Section("Streak Values") {
                Stepper("Current Streak: \(habit.currentStreak)", value: Binding(
                    get: { habit.currentStreak },
                    set: { habit.currentStreak = $0 }
                ), in: 0...999)

                Stepper("Longest Streak: \(habit.longestStreak)", value: Binding(
                    get: { habit.longestStreak },
                    set: { habit.longestStreak = $0 }
                ), in: 0...999)

                Stepper("Consecutive Misses: \(habit.consecutiveMisses)", value: Binding(
                    get: { habit.consecutiveMisses },
                    set: { habit.consecutiveMisses = $0 }
                ), in: 0...999)
            }

            Section("Date Overrides") {
                DatePicker("Last Check-In", selection: Binding(
                    get: { habit.lastCheckInDate ?? Date() },
                    set: { habit.lastCheckInDate = $0 }
                ), displayedComponents: .date)

                DatePicker("Last Completed", selection: Binding(
                    get: { habit.lastCompletedDate ?? Date() },
                    set: { habit.lastCompletedDate = $0 }
                ), displayedComponents: .date)

                Button("Clear Dates") {
                    habit.lastCheckInDate = nil
                    habit.lastCompletedDate = nil
                    save()
                }
                .foregroundStyle(.red)
            }

            Section("Emotion Presets") {
                presetButton("Neutral", streak: 1, longest: 5, misses: 0)
                presetButton("Proud", streak: 5, longest: 10, misses: 0)
                presetButton("Excited", streak: 11, longest: 11, misses: 0)
                presetButton("Celebratory", streak: 30, longest: 30, misses: 0)
                presetButton("Supportive", streak: 0, longest: 5, misses: 1)
                presetButton("Concerned", streak: 0, longest: 5, misses: 3)
                presetButton("Welcome Back", streak: 0, longest: 10, misses: 5)
            }
        }
        .navigationTitle("Debug Streaks")
        .onChange(of: habit.currentStreak) { save() }
        .onChange(of: habit.longestStreak) { save() }
        .onChange(of: habit.consecutiveMisses) { save() }
    }

    private func presetButton(_ label: String, streak: Int, longest: Int, misses: Int) -> some View {
        Button {
            habit.currentStreak = streak
            habit.longestStreak = longest
            habit.consecutiveMisses = misses
            save()
        } label: {
            HStack {
                Text(label)
                Spacer()
                Text("streak=\(streak) longest=\(longest) misses=\(misses)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func save() {
        try? modelContext.save()
    }
}
#endif
