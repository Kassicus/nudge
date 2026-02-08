//
//  ChatView.swift
//  Nudge
//

import SwiftUI
import SwiftData

struct ChatView: View {
    let conversation: Conversation
    let habit: Habit
    var engine: ConversationEngine

    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    private var emotion: BuddyEmotion? {
        BuddyEmotion(rawValue: conversation.emotionalState)
    }

    private var sortedMessages: [Message] {
        (conversation.messages ?? []).sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(sortedMessages.enumerated()), id: \.element.id) { index, message in
                            let showAvatar = message.role == "buddy" && (
                                index == 0 ||
                                sortedMessages[index - 1].role != "buddy"
                            )

                            MessageBubble(
                                message: message,
                                showAvatar: showAvatar,
                                buddyName: habit.buddyName,
                                emotion: message.role == "buddy" ? emotion : nil
                            )
                            .id(message.id)
                        }

                        if engine.isGenerating {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: sortedMessages.count) {
                    withAnimation {
                        if let lastMessage = sortedMessages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: engine.isGenerating) {
                    if engine.isGenerating {
                        withAnimation {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Quick replies (show when conversation is not complete and not generating)
            if !conversation.isComplete && !engine.isGenerating {
                QuickReplyBar { reply in
                    sendMessage(reply)
                }
                .padding(.vertical, 6)
            }

            // Input field
            if !conversation.isComplete {
                HStack(spacing: 10) {
                    TextField("Message...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button {
                        sendMessage(inputText)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || engine.isGenerating)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(habit.buddyName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isInputFocused = true
        }
    }

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        inputText = ""

        Task {
            await engine.handleUserResponse(trimmed, conversation: conversation, habit: habit)
        }
    }
}
