//
//  ConversationEngine.swift
//  Nudge
//

import Foundation
import SwiftData
import FoundationModels

@Observable
class ConversationEngine {
    var isGenerating = false

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Session Creation

    func createBuddySession(for habit: Habit) -> LanguageModelSession {
        let personality = BuddyPersonality(rawValue: habit.buddyPersonality) ?? .supportiveFriend
        let emotionalState = BuddyEmotion.calculateEmotionalState(for: habit)

        let instructions = """
        You are \(habit.buddyName), a habit accountability buddy.
        Your personality: \(personality.systemDescription)

        You are checking in about: \(habit.name)
        \(habit.habitDescription.isEmpty ? "" : "Details: \(habit.habitDescription)")

        Current streak: \(habit.currentStreak) days
        Longest streak: \(habit.longestStreak) days
        Consecutive misses: \(habit.consecutiveMisses)
        Last completed: \(habit.lastCompletedDate?.formatted() ?? "never")

        Your current emotional state: \(emotionalState.rawValue)

        You have access to the getHabitStreak tool to look up detailed streak information when needed.

        RULES:
        - You are texting a friend. Keep messages short and casual.
        - Never exceed 40 words per message.
        - Match your emotional state in tone.
        - Do not use more than 1-2 emoji per message.
        - Do not lecture or be preachy.
        - If the user says something off-topic, gently redirect to the habit check-in.
        - If the user seems upset or stressed, acknowledge it before asking about the habit.
        """

        let tools: [any Tool] = [HabitStreakTool(habit: habit)]
        return LanguageModelSession(tools: tools, instructions: instructions)
    }

    // MARK: - Start Check-In

    func startCheckIn(for habit: Habit) async -> Conversation {
        let emotion = BuddyEmotion.calculateEmotionalState(for: habit)
        let conversation = Conversation(date: Date(), emotionalState: emotion.rawValue)
        conversation.habit = habit

        let checkIn = CheckIn(date: Date())
        checkIn.habit = habit
        checkIn.conversation = conversation
        conversation.checkIn = checkIn

        // Get opening message: try pre-generated, then LLM, then template fallback
        var openingText = consumePreGeneratedMessage(for: habit)
        if openingText == nil {
            openingText = await generateLLMOpening(for: habit)
        }
        if openingText == nil {
            openingText = TemplateFallbacks.generateFallbackOpening(for: habit)
        }

        let openingMessage = Message(content: openingText!, role: "buddy")
        openingMessage.conversation = conversation

        modelContext.insert(conversation)
        modelContext.insert(checkIn)
        modelContext.insert(openingMessage)
        try? modelContext.save()

        return conversation
    }

    // MARK: - Handle User Response

    func handleUserResponse(_ userText: String, conversation: Conversation, habit: Habit) async {
        let userMessage = Message(content: userText, role: "user")
        userMessage.conversation = conversation
        modelContext.insert(userMessage)
        try? modelContext.save()

        isGenerating = true

        do {
            let session = createBuddySession(for: habit)

            // Replay conversation history
            let sortedMessages = (conversation.messages ?? []).sorted { $0.timestamp < $1.timestamp }
            for msg in sortedMessages.dropLast() {
                if msg.role == "buddy" {
                    let _ = try await session.respond(to: "Previous buddy message: \(msg.content)")
                }
            }

            let response = try await session.respond(
                to: userText,
                generating: CheckInResult.self
            )
            let result = response.content

            let buddyText: String
            if MessageValidator.validateBuddyMessage(result.buddyMessage, habitName: habit.name) {
                buddyText = result.buddyMessage
            } else {
                buddyText = TemplateFallbacks.getTemplateFallback(
                    status: result.status,
                    emotion: conversation.emotionalState,
                    habit: habit
                )
            }

            let buddyMessage = Message(content: buddyText, role: "buddy")
            buddyMessage.conversation = conversation
            modelContext.insert(buddyMessage)

            conversation.checkIn?.status = result.status.rawValue

            if result.shouldFollowUp && !result.followUpMessage.isEmpty {
                let followUp = Message(
                    content: result.followUpMessage,
                    role: "buddy",
                    timestamp: Date().addingTimeInterval(1)
                )
                followUp.conversation = conversation
                modelContext.insert(followUp)
            } else {
                conversation.isComplete = true
                updateStreaks(for: habit, with: result.status)
            }

        } catch {
            // LLM failed — use template fallback
            let fallbackText = TemplateFallbacks.getTemplateFallback(
                status: .completed,
                emotion: conversation.emotionalState,
                habit: habit
            )
            let fallback = Message(content: fallbackText, role: "buddy")
            fallback.conversation = conversation
            modelContext.insert(fallback)

            conversation.checkIn?.status = "completed"
            conversation.isComplete = true
            updateStreaks(for: habit, with: .completed)
        }

        try? modelContext.save()
        isGenerating = false
    }

    // MARK: - Streak Updates

    func updateStreaks(for habit: Habit, with status: CheckInStatus) {
        let today = Calendar.current.startOfDay(for: Date())
        habit.lastCheckInDate = today

        switch status {
        case .completed, .partial:
            habit.currentStreak += 1
            habit.consecutiveMisses = 0
            habit.lastCompletedDate = today
            if habit.currentStreak > habit.longestStreak {
                habit.longestStreak = habit.currentStreak
            }
        case .missed:
            habit.currentStreak = 0
            habit.consecutiveMisses += 1
        case .skipped, .unclear:
            break
        }

        try? modelContext.save()
    }

    // MARK: - Pre-generated Messages

    private func consumePreGeneratedMessage(for habit: Habit) -> String? {
        let today = Calendar.current.startOfDay(for: Date())
        guard let messages = habit.preGeneratedMessages else { return nil }

        let available = messages.first { msg in
            !msg.isUsed && Calendar.current.isDate(msg.targetDate, inSameDayAs: today)
        }

        if let message = available {
            message.isUsed = true
            try? modelContext.save()
            return message.content
        }

        return nil
    }

    private func generateLLMOpening(for habit: Habit) async -> String? {
        do {
            let session = createBuddySession(for: habit)
            let response = try await session.respond(
                to: "Generate an opening check-in message for today.",
                generating: OpeningMessage.self
            )
            let result = response.content
            if MessageValidator.validateBuddyMessage(result.message, habitName: habit.name) {
                return result.message
            }
        } catch {
            // Fall through to template
        }
        return nil
    }
}
