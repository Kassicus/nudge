//
//  OnboardingChatView.swift
//  Nudge
//

import SwiftUI
import SwiftData

struct OnboardingChatView: View {
    @Environment(\.modelContext) private var modelContext
    var onComplete: () -> Void

    // State machine
    enum Step: CaseIterable {
        case welcome, askHabit, askFrequency, askTime, askPersonality, askBuddyName, complete
    }

    @State private var currentStep: Step = .welcome
    @State private var chatMessages: [(id: UUID, content: String, isUser: Bool)] = []
    @State private var isTyping = false
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool

    // Collected data
    @State private var userName = ""
    @State private var habitName = ""
    @State private var frequency = "daily"
    @State private var reminderTime = Date()
    @State private var personality: BuddyPersonality = .supportiveFriend
    @State private var buddyName = ""

    // Show input controls after typing animation
    @State private var showInput = false

    var body: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(chatMessages, id: \.id) { msg in
                            OnboardingBubble(content: msg.content, isUser: msg.isUser)
                                .id(msg.id)
                        }

                        if isTyping {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding(.vertical, 12)
                }
                .onChange(of: chatMessages.count) {
                    if let last = chatMessages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isTyping) {
                    if isTyping {
                        withAnimation {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input area
            if showInput {
                inputView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showInput)
        .task {
            await sendBuddyMessage("Hey there! \u{1F44B} I'm going to be your habit buddy. What should I call you?")
            showInput = true
        }
    }

    // MARK: - Input Views

    @ViewBuilder
    private var inputView: some View {
        switch currentStep {
        case .welcome:
            textInputBar(placeholder: "Your name")
        case .askHabit:
            textInputBar(placeholder: "e.g., Exercise, Read, Meditate...")
        case .askFrequency:
            frequencyPicker
        case .askTime:
            timePicker
        case .askPersonality:
            personalityPicker
        case .askBuddyName:
            textInputBar(placeholder: buddyNameDefault)
        case .complete:
            getStartedButton
        }
    }

    private func textInputBar(placeholder: String) -> some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: $inputText)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)
                .onSubmit { handleTextInput() }

            Button {
                handleTextInput()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var frequencyPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([
                    ("Every day", "daily"),
                    ("Weekdays", "weekdays"),
                    ("Weekends", "weekends")
                ], id: \.1) { label, value in
                    Button {
                        Task { await handleFrequencySelection(label: label, value: value) }
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
            .padding(.vertical, 12)
        }
    }

    private var timePicker: some View {
        VStack(spacing: 12) {
            DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 120)

            Button("Set Time") {
                Task { await handleTimeSelection() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var personalityPicker: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(BuddyPersonality.allCases, id: \.self) { p in
                    PersonalityCard(personality: p, isSelected: personality == p) {
                        personality = p
                    }
                }
            }

            Button("Continue") {
                Task { await handlePersonalitySelection() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var getStartedButton: some View {
        Button {
            Task { await finishOnboarding() }
        } label: {
            Text("Get Started")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Buddy Name Default

    private var buddyNameDefault: String {
        switch personality {
        case .supportiveFriend: return "Alex"
        case .toughCoach:       return "Coach"
        case .chillCompanion:   return "Zen"
        case .hypePartner:      return "Blaze"
        }
    }

    // MARK: - Input Handlers

    private func handleTextInput() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        inputFocused = false

        Task {
            switch currentStep {
            case .welcome:
                userName = text
                addUserMessage(text)
                showInput = false
                await sendBuddyMessage("Nice to meet you, \(userName)! What's one thing you've been wanting to do more consistently?")
                currentStep = .askHabit
                showInput = true

            case .askHabit:
                habitName = inferHabitName(from: text)
                addUserMessage(text)
                showInput = false
                await sendBuddyMessage("Love that! How often do you want to \(habitName.lowercased())?")
                currentStep = .askFrequency
                showInput = true

            case .askBuddyName:
                buddyName = text
                addUserMessage(text)
                showInput = false
                let timeString = formattedTime
                await sendBuddyMessage("Perfect! I'll check in with you about \(habitName) at \(timeString). Let's do this! \u{1F4AA}")
                currentStep = .complete
                showInput = true

            default:
                break
            }
        }
    }

    private func handleFrequencySelection(label: String, value: String) async {
        frequency = value
        addUserMessage(label)
        showInput = false
        await sendBuddyMessage("And what time should I check in with you?")
        currentStep = .askTime
        showInput = true
    }

    private func handleTimeSelection() async {
        addUserMessage(formattedTime)
        showInput = false
        await sendBuddyMessage("One last thing — what vibe do you want from me?")
        currentStep = .askPersonality
        showInput = true
    }

    private func handlePersonalitySelection() async {
        addUserMessage(personality.displayName)
        showInput = false
        buddyName = buddyNameDefault
        await sendBuddyMessage("Almost done! What do you want to call me?")
        currentStep = .askBuddyName
        showInput = true
    }

    private func finishOnboarding() async {
        // Create or update UserProfile
        let profileDescriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(profileDescriptor)) ?? []
        let profile: UserProfile
        if let existing = profiles.first {
            profile = existing
        } else {
            profile = UserProfile()
            modelContext.insert(profile)
        }
        profile.name = userName
        profile.onboardingCompleted = true

        // Create habit
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let manager = HabitManager(modelContext: modelContext)
        let habit = manager.createHabit(
            name: habitName,
            buddyName: buddyName,
            personality: personality,
            frequency: frequency,
            reminderHour: components.hour ?? 20,
            reminderMinute: components.minute ?? 0
        )

        // Request notification permission and schedule
        let _ = await NotificationManager.shared.requestPermission()
        NotificationManager.shared.scheduleHabitReminder(for: habit)

        // Start first check-in conversation
        let engine = ConversationEngine(modelContext: modelContext)
        let _ = await engine.startCheckIn(for: habit)

        try? modelContext.save()
        onComplete()
    }

    // MARK: - Helpers

    private func addUserMessage(_ text: String) {
        chatMessages.append((id: UUID(), content: text, isUser: true))
    }

    private func sendBuddyMessage(_ text: String) async {
        isTyping = true
        try? await Task.sleep(for: .milliseconds(800))
        isTyping = false
        chatMessages.append((id: UUID(), content: text, isUser: false))
    }

    private func inferHabitName(from input: String) -> String {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip common preambles (case-insensitive), longest first
        let preambles = [
            "i've been wanting to ",
            "i want to get better at ",
            "i'd like to get better at ",
            "i would like to get better at ",
            "i want to start ",
            "i'd like to start ",
            "i would like to start ",
            "i want to be better at ",
            "i'd like to be better at ",
            "get better at ",
            "be better at ",
            "start to ",
            "i want to ",
            "i'd like to ",
            "i would like to ",
            "i wanna ",
            "i need to ",
            "maybe ",
        ]

        let lowered = text.lowercased()
        for preamble in preambles {
            if lowered.hasPrefix(preamble) {
                text = String(text.dropFirst(preamble.count))
                break
            }
        }

        // Strip trailing fluff like "more often", "every day", "more consistently", "before bed" etc.
        // but only generic scheduling fluff — keep context like "before bed" since it's meaningful
        let suffixes = [
            " more consistently",
            " more often",
            " every day",
            " each day",
            " regularly",
            " every single day",
        ]

        let suffixLowered = text.lowercased()
        for suffix in suffixes {
            if suffixLowered.hasSuffix(suffix) {
                text = String(text.dropLast(suffix.count))
                break
            }
        }

        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Capitalize first letter
        guard let first = text.first else { return input }
        return String(first).uppercased() + text.dropFirst()
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: reminderTime)
    }
}

// MARK: - Onboarding Bubble

private struct OnboardingBubble: View {
    let content: String
    let isUser: Bool

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            Text(content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 8)
    }
}
