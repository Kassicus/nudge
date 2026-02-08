//
//  HabitFormView.swift
//  Nudge
//

import SwiftUI
import SwiftData

struct HabitFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var habit: Habit? = nil

    @State private var name: String = ""
    @State private var habitDescription: String = ""
    @State private var buddyName: String = "Buddy"
    @State private var personality: BuddyPersonality = .supportiveFriend
    @State private var frequency: String = "daily"
    @State private var customDays: Set<Int> = []
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    private var isEditing: Bool { habit != nil }

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        Form {
            Section("Habit") {
                TextField("Habit name", text: $name)
                TextField("Description (optional)", text: $habitDescription)
            }

            Section("Buddy") {
                TextField("Buddy name", text: $buddyName)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(BuddyPersonality.allCases, id: \.self) { p in
                        PersonalityCard(personality: p, isSelected: personality == p) {
                            personality = p
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Schedule") {
                Picker("Frequency", selection: $frequency) {
                    Text("Daily").tag("daily")
                    Text("Weekdays").tag("weekdays")
                    Text("Weekends").tag("weekends")
                    Text("Custom").tag("custom")
                }
                .pickerStyle(.segmented)

                if frequency == "custom" {
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { day in
                            Button {
                                if customDays.contains(day) {
                                    customDays.remove(day)
                                } else {
                                    customDays.insert(day)
                                }
                            } label: {
                                Text(dayNames[day])
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(customDays.contains(day) ? Color.blue : Color(.systemGray6))
                                    .foregroundStyle(customDays.contains(day) ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
            }
        }
        .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveHabit()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if let habit {
                name = habit.name
                habitDescription = habit.habitDescription
                buddyName = habit.buddyName
                personality = BuddyPersonality(rawValue: habit.buddyPersonality) ?? .supportiveFriend
                frequency = habit.frequency
                customDays = Set(habit.scheduledDays ?? [])

                var components = DateComponents()
                components.hour = habit.reminderHour
                components.minute = habit.reminderMinute
                if let date = Calendar.current.date(from: components) {
                    reminderTime = date
                }
            }
        }
    }

    private func saveHabit() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let hour = components.hour ?? 20
        let minute = components.minute ?? 0

        if let habit {
            // Update existing
            habit.name = name.trimmingCharacters(in: .whitespaces)
            habit.habitDescription = habitDescription.trimmingCharacters(in: .whitespaces)
            habit.buddyName = buddyName.trimmingCharacters(in: .whitespaces)
            habit.buddyPersonality = personality.rawValue
            habit.frequency = frequency
            habit.scheduledDays = frequency == "custom" ? Array(customDays).sorted() : []
            habit.reminderHour = hour
            habit.reminderMinute = minute
            try? modelContext.save()

            NotificationManager.shared.cancelReminder(for: habit)
            NotificationManager.shared.scheduleHabitReminder(for: habit)
        } else {
            // Create new
            let manager = HabitManager(modelContext: modelContext)
            let newHabit = manager.createHabit(
                name: name.trimmingCharacters(in: .whitespaces),
                description: habitDescription.trimmingCharacters(in: .whitespaces),
                buddyName: buddyName.trimmingCharacters(in: .whitespaces),
                personality: personality,
                frequency: frequency,
                reminderHour: hour,
                reminderMinute: minute
            )
            if frequency == "custom" {
                newHabit.scheduledDays = Array(customDays).sorted()
                try? modelContext.save()
            }

            NotificationManager.shared.scheduleHabitReminder(for: newHabit)
        }

        dismiss()
    }
}
