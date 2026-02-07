# Nudge — Project Plan

## Overview

Nudge is a native iOS habit tracking app where users don't interact with dashboards and checkboxes. Instead, a virtual "buddy" initiates text-message-style conversations at scheduled times to check in on habits. The buddy has emotional range — celebrating streaks, encouraging after misses, and showing concern during prolonged lapses. The entire app runs on-device using Apple's native frameworks with iCloud sync for cross-device support.

### Core Value Proposition

- **Conversational habit tracking** — the buddy texts you, you respond naturally
- **Emotional intelligence** — the buddy's tone adapts to your streak history
- **Zero cloud dependency** — runs fully offline using on-device AI
- **Complete privacy** — habit data and conversations never leave the device (except user's private iCloud for sync)
- **No ongoing costs** — Apple's Foundation Models framework is free

### Target Platform

- iOS 26+ (iPhone 15 Pro or later required — A17 Pro chip minimum)
- Apple Intelligence must be enabled
- iPad support as a secondary target via iCloud sync

---

## Tech Stack

| Layer | Framework |
|---|---|
| Language | Swift 6.2 |
| UI | SwiftUI |
| LLM | Foundation Models framework |
| Local Database | SwiftData |
| Cross-Device Sync | CloudKit (automatic via SwiftData) |
| Notifications | UserNotifications (local, scheduled) |
| Background Tasks | BGTaskScheduler |
| Development | Xcode 26 |

No third-party dependencies. No server. No API keys.

---

## Architecture

### High-Level Data Flow

```
┌─────────────────────────────────────────────────┐
│                   SwiftUI Views                  │
│  (ChatView, HabitListView, OnboardingView, etc.) │
└──────────────────────┬──────────────────────────┘
                       │
          ┌────────────┴────────────┐
          │                         │
┌─────────▼──────────┐   ┌────────▼─────────────┐
│  ConversationEngine │   │   HabitManager        │
│  (LLM + Templates)  │   │   (Streaks, Stats)    │
└─────────┬──────────┘   └────────┬─────────────┘
          │                         │
          └────────────┬────────────┘
                       │
              ┌────────▼────────┐
              │    SwiftData     │
              │  (Local + iCloud │
              │   via CloudKit)  │
              └─────────────────┘
```

### Key Architectural Principles

1. **Offline-first**: All data and AI inference runs locally. iCloud sync is additive, not required.
2. **Chat-first UI**: The primary interface is a conversation thread, not a dashboard. Stats views are secondary.
3. **Structured LLM output**: Use Guided Generation (`@Generable` / `@Guide`) for all model interactions to get typed Swift structs back, never raw text parsing.
4. **Template fallbacks**: Every LLM-generated message has a curated template fallback in case the model produces low-quality output.
5. **Pre-generated notifications**: Opening check-in messages are generated ahead of time during foreground app use and stored in SwiftData, so notifications don't depend on background LLM execution.

---

## Data Model (SwiftData)

All models must be CloudKit-compatible: all properties must have default values or be optional, all relationships must be optional. No `@Attribute(.unique)`.

### User

```swift
@Model
class UserProfile {
    var name: String = ""
    var timezone: String = TimeZone.current.identifier
    var onboardingCompleted: Bool = false
    var createdAt: Date = Date()
}
```

### Buddy

Each habit can have a buddy personality. Initially we support a set of predefined personalities. The buddy is not a separate entity — it's a personality configuration on the habit. This simplifies the data model while still allowing different vibes per habit.

```swift
// BuddyPersonality is a simple enum, not a SwiftData model
enum BuddyPersonality: String, Codable, CaseIterable {
    case supportiveFriend    // warm, encouraging, patient
    case toughCoach          // direct, expects results, celebrates hard
    case chillCompanion      // relaxed, no pressure, gentle nudges
    case hypePartner         // high energy, lots of emoji, enthusiastic
}
```

### Habit

```swift
@Model
class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var habitDescription: String = ""
    var buddyName: String = "Buddy"
    var buddyPersonality: String = BuddyPersonality.supportiveFriend.rawValue
    var frequency: String = "daily"            // "daily", "weekdays", "weekends", "custom"
    var scheduledDays: [Int]? = []             // 1=Sun, 2=Mon, ... 7=Sat (for custom frequency)
    var reminderHour: Int = 20                 // 24-hour format, default 8 PM
    var reminderMinute: Int = 0
    var isActive: Bool = true
    var createdAt: Date = Date()

    // Streak tracking (denormalized for fast access)
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var consecutiveMisses: Int = 0
    var lastCompletedDate: Date? = nil
    var lastCheckInDate: Date? = nil

    // Relationships
    @Relationship(deleteRule: .cascade)
    var checkIns: [CheckIn]? = []

    @Relationship(deleteRule: .cascade)
    var conversations: [Conversation]? = []

    @Relationship(deleteRule: .cascade)
    var preGeneratedMessages: [PreGeneratedMessage]? = []
}
```

### CheckIn

```swift
@Model
class CheckIn {
    var id: UUID = UUID()
    var date: Date = Date()
    var status: String = "pending"        // "pending", "completed", "partial", "missed", "skipped"
    var createdAt: Date = Date()

    // Relationship
    var habit: Habit? = nil
    var conversation: Conversation? = nil
}
```

### Conversation

```swift
@Model
class Conversation {
    var id: UUID = UUID()
    var date: Date = Date()
    var isComplete: Bool = false
    var emotionalState: String = "neutral"   // "proud", "supportive", "concerned", "celebratory", "neutral"
    var createdAt: Date = Date()

    // Relationships
    var habit: Habit? = nil
    var checkIn: CheckIn? = nil

    @Relationship(deleteRule: .cascade)
    var messages: [Message]? = []
}
```

### Message

```swift
@Model
class Message {
    var id: UUID = UUID()
    var content: String = ""
    var role: String = "buddy"             // "buddy" or "user"
    var timestamp: Date = Date()
    var isStreaming: Bool = false

    // Relationship
    var conversation: Conversation? = nil
}
```

### PreGeneratedMessage

```swift
@Model
class PreGeneratedMessage {
    var id: UUID = UUID()
    var targetDate: Date = Date()          // The date this message is intended for
    var content: String = ""
    var isUsed: Bool = false
    var createdAt: Date = Date()

    // Relationship
    var habit: Habit? = nil
}
```

---

## Foundation Models Integration

### Session Setup

Each conversation gets its own `LanguageModelSession` with instructions that encode the buddy's personality and current context.

```swift
import FoundationModels

func createBuddySession(for habit: Habit) -> LanguageModelSession {
    let personality = BuddyPersonality(rawValue: habit.buddyPersonality) ?? .supportiveFriend
    let emotionalState = calculateEmotionalState(for: habit)

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
    
    RULES:
    - You are texting a friend. Keep messages short and casual.
    - Never exceed 40 words per message.
    - Match your emotional state in tone.
    - Do not use more than 1-2 emoji per message.
    - Do not lecture or be preachy.
    - If the user says something off-topic, gently redirect to the habit check-in.
    - If the user seems upset or stressed, acknowledge it before asking about the habit.
    """

    return LanguageModelSession(instructions: instructions)
}
```

### Guided Generation Schemas

#### Check-In Classification

```swift
@Generable
struct CheckInResult {
    @Guide(description: "The user's habit completion status based on their response")
    let status: CheckInStatus

    @Guide(description: "A short, casual buddy response under 40 words matching the emotional state")
    let buddyMessage: String

    @Guide(description: "Whether to ask a follow-up question or end the check-in")
    let shouldFollowUp: Bool

    @Guide(description: "If following up, the follow-up question. Empty string if not following up.")
    let followUpMessage: String
}

@Generable
enum CheckInStatus: String {
    case completed    // user clearly did the habit
    case partial      // user did some but not all
    case missed       // user did not do it
    case skipped      // user intentionally skipping (sick, traveling, etc.)
    case unclear      // can't determine from the response
}
```

#### Opening Message Generation

```swift
@Generable
struct OpeningMessage {
    @Guide(description: "A casual, friendly opening check-in message under 30 words")
    let message: String
}
```

#### Weekly Recap Generation

```swift
@Generable
struct WeeklyRecap {
    @Guide(description: "A 2-3 sentence recap of the week's habit performance, casual and friendly tone")
    let summary: String

    @Guide(description: "A short motivational message for the coming week, under 20 words")
    let motivation: String
}
```

### Tool Calling — Streak Lookup

Define a tool that lets the model query the user's habit data during conversation:

```swift
struct HabitStreakTool: Tool {
    var name: String { "get_habit_streak" }
    var description: String { "Retrieves current streak and recent history for the habit being discussed" }

    func call(with arguments: HabitStreakArgs) async throws -> ToolOutput {
        // Fetch from SwiftData and return formatted context
        let context = """
        Current streak: \(habit.currentStreak) days
        Longest streak: \(habit.longestStreak) days
        Last 7 days: \(recentHistory.map { $0.status }.joined(separator: ", "))
        """
        return ToolOutput(content: context)
    }
}
```

### Personality System Descriptions

Each personality gets a detailed system description used in session instructions:

```swift
extension BuddyPersonality {
    var systemDescription: String {
        switch self {
        case .supportiveFriend:
            return """
            You are warm, encouraging, and patient. You celebrate small wins genuinely.
            When the user misses a day, you're understanding and focus on tomorrow.
            You use casual, friendly language. You occasionally share that you believe in them.
            """
        case .toughCoach:
            return """
            You are direct and expect results, but you're fair. You celebrate hard work enthusiastically.
            When the user misses, you're matter-of-fact and redirect focus to getting back on track.
            You don't sugarcoat things but you're never mean. Think supportive coach, not drill sergeant.
            """
        case .chillCompanion:
            return """
            You are relaxed and low-pressure. You check in casually without making it feel like an obligation.
            When the user misses, it's no big deal - life happens.
            You use laid-back language. You don't push hard but you're genuinely happy when they succeed.
            """
        case .hypePartner:
            return """
            You are high-energy and enthusiastic. Every completion is cause for celebration.
            When the user misses, you pump them up for tomorrow with infectious optimism.
            You use exclamation marks and emoji freely. You make the user feel like a champion.
            """
        }
    }
}
```

---

## Emotional State Engine

The buddy's emotional state is calculated from streak data and determines the tone of all generated messages.

### Emotional States

```swift
enum BuddyEmotion: String, Codable {
    case neutral        // default, no strong signal
    case proud          // 3+ day streak
    case excited        // new personal best streak
    case celebratory    // milestone hit (7, 14, 21, 30, 60, 90 days)
    case supportive     // 1 miss after a streak
    case concerned      // 3+ consecutive misses
    case welcomeBack    // first check-in after 5+ days of misses
}
```

### Calculation Logic

```swift
func calculateEmotionalState(for habit: Habit) -> BuddyEmotion {
    let milestones = [7, 14, 21, 30, 60, 90, 180, 365]

    // Check milestone first (takes priority)
    if milestones.contains(habit.currentStreak) {
        return .celebratory
    }

    // New personal best
    if habit.currentStreak > 0 && habit.currentStreak >= habit.longestStreak {
        return .excited
    }

    // Active streak
    if habit.currentStreak >= 3 {
        return .proud
    }

    // Welcome back after long absence
    if habit.consecutiveMisses >= 5 {
        return .welcomeBack
    }

    // Concerning miss pattern
    if habit.consecutiveMisses >= 3 {
        return .concerned
    }

    // Single recent miss after a streak
    if habit.consecutiveMisses == 1 && habit.currentStreak == 0 {
        // Check if there was a streak before this miss
        if habit.longestStreak > 0 {
            return .supportive
        }
    }

    return .neutral
}
```

---

## Template Fallback System

Every emotional state has curated fallback messages used when the LLM produces low-quality output or when running pre-generation for notifications.

### Opening Message Templates

```swift
let openingTemplates: [BuddyEmotion: [String]] = [
    .neutral: [
        "Hey {name}! How did {habit} go today?",
        "Hi {name}! Checking in — did you get to {habit}?",
        "Hey! Quick check-in on {habit} today 😊"
    ],
    .proud: [
        "Hey {name}! {streak} days strong 💪 Did you keep it going today?",
        "{streak} days in a row! Tell me you made it {streak_plus_one} 🔥",
        "Look at you on day {streak}! How was {habit} today?"
    ],
    .excited: [
        "You're on your LONGEST streak ever! {streak} days! Did today make it {streak_plus_one}?",
        "Personal best alert! 🎉 {streak} days! Please tell me you kept it going!"
    ],
    .celebratory: [
        "🎉 {streak} DAYS!! That's incredible {name}! Did you make it today too?",
        "MILESTONE! {streak} days of {habit}! I'm so proud. How about today?"
    ],
    .supportive: [
        "Hey {name}, yesterday was just one day. Fresh start today — how did {habit} go?",
        "New day, clean slate! Did you get to {habit} today?"
    ],
    .concerned: [
        "Hey {name}, I've noticed it's been a few days. Everything okay? No pressure, just checking in ❤️",
        "Missing you! It's been {miss_count} days. Want to talk about what's getting in the way?"
    ],
    .welcomeBack: [
        "Hey {name}! Been a while. I'm glad you're here. Want to get back to {habit}?",
        "Welcome back {name}! No judgment — let's just pick up where we left off. How are you?"
    ]
]
```

### Response Templates (by status and emotion)

```swift
let responseTemplates: [CheckInStatus: [BuddyEmotion: [String]]] = [
    .completed: [
        .neutral: ["Nice work! ✅ That's what I like to see.", "Awesome, checked off for today! 👏"],
        .proud: ["That's {streak} days! You're on fire 🔥", "{streak} in a row — you're building something real here."],
        .celebratory: ["🎉🎉🎉 {streak} DAYS! I can't even handle how proud I am!"],
        .supportive: ["YES! Back on track! That's the spirit 💪", "Knew you'd bounce back. Great job today!"]
    ],
    .missed: [
        .neutral: ["No worries — tomorrow's a new day.", "That's okay! One day doesn't define the journey."],
        .supportive: ["Hey, it happens. Don't be hard on yourself. Tomorrow's there for you."],
        .concerned: ["I hear you. Is there something making it harder lately? I'm here if you want to talk about it."]
    ],
    .partial: [
        .neutral: ["Partial counts! Some is better than none.", "Hey, you still showed up. That matters."],
        .proud: ["Still showed up, that's what counts! Almost there 💪"]
    ],
    .skipped: [
        .neutral: ["Totally fair. Rest when you need to. We'll pick back up tomorrow.", "Got it — take care of yourself first. See you tomorrow! ❤️"]
    ]
]
```

### Quality Validation

Before displaying an LLM-generated message, validate it:

```swift
func validateBuddyMessage(_ message: String, habitName: String) -> Bool {
    // Too long
    if message.split(separator: " ").count > 60 { return false }

    // Too short (likely error)
    if message.count < 5 { return false }

    // Contains hallucinated content (mentions habits/names not in context)
    // Basic check — expand as needed
    if message.lowercased().contains("as an ai") { return false }
    if message.lowercased().contains("language model") { return false }

    return true
}
```

---

## Notification System

### Scheduling Local Notifications

When a user creates or edits a habit, schedule recurring local notifications:

```swift
func scheduleHabitNotification(for habit: Habit) {
    let center = UNUserNotificationCenter.current()

    // Remove existing notifications for this habit
    center.removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])

    // Get pre-generated message or fallback template
    let messageContent = getNextPreGeneratedMessage(for: habit)
        ?? generateFallbackOpening(for: habit)

    let content = UNMutableNotificationContent()
    content.title = habit.buddyName
    content.body = messageContent
    content.sound = .default
    content.categoryIdentifier = "HABIT_CHECKIN"
    content.userInfo = ["habitId": habit.id.uuidString]

    // Create trigger for the habit's scheduled time
    var dateComponents = DateComponents()
    dateComponents.hour = habit.reminderHour
    dateComponents.minute = habit.reminderMinute

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(
        identifier: habit.id.uuidString,
        content: content,
        trigger: trigger
    )

    center.add(request)
}
```

### Notification Actions

Allow quick replies directly from the notification:

```swift
func registerNotificationCategories() {
    let yesAction = UNNotificationAction(identifier: "YES", title: "Yes! ✅", options: [])
    let noAction = UNNotificationAction(identifier: "NO", title: "Not today", options: [])
    let openAction = UNNotificationAction(identifier: "OPEN", title: "Tell me more...", options: [.foreground])

    let category = UNNotificationCategory(
        identifier: "HABIT_CHECKIN",
        actions: [yesAction, noAction, openAction],
        intentIdentifiers: [],
        options: []
    )

    UNUserNotificationCenter.current().setNotificationCategories([category])
}
```

### Pre-Generation Strategy

Pre-generate opening messages during foreground app use to avoid reliance on background execution:

```swift
func preGenerateMessages(for habit: Habit) async {
    let existingMessages = habit.preGeneratedMessages?.filter { !$0.isUsed } ?? []
    let daysToGenerate = 3 - existingMessages.count

    guard daysToGenerate > 0 else { return }

    let session = createBuddySession(for: habit)

    for dayOffset in 1...daysToGenerate {
        let targetDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!

        do {
            let result = try await session.respond(
                to: "Generate an opening check-in message for \(targetDate.formatted(date: .abbreviated, time: .omitted))",
                generating: OpeningMessage.self
            )

            let preGenerated = PreGeneratedMessage()
            preGenerated.targetDate = targetDate
            preGenerated.content = result.message
            preGenerated.habit = habit

            // Insert into SwiftData context
        } catch {
            // Silently fail — template fallback will be used
        }
    }
}
```

---

## UI Structure

### View Hierarchy

```
App
├── ContentView (tab bar or navigation root)
│   ├── ConversationsListView        // Main screen — list of active buddy conversations
│   │   └── ChatView                 // Individual conversation thread (iMessage-style)
│   │       ├── MessageBubble        // Single message bubble component
│   │       ├── TypingIndicator      // Animated dots while buddy "types"
│   │       └── QuickReplyBar        // Optional quick-reply buttons
│   ├── HabitsListView               // Manage habits
│   │   └── HabitDetailView          // Edit habit, see streak stats
│   │       └── StreakCalendarView   // GitHub-style contribution grid
│   └── SettingsView                 // App preferences
└── OnboardingView                   // First launch — conversational setup
    └── OnboardingChatView           // Buddy introduces itself, helps create first habit
```

### ChatView Design Specifications

The chat interface should closely mimic iMessage:

- **Message bubbles**: Buddy messages left-aligned (gray/colored background), user messages right-aligned (blue background)
- **Timestamps**: Shown between message groups, not on every message. Use relative time ("2 min ago", "Yesterday 8:03 PM")
- **Typing indicator**: Three animated dots in a buddy-colored bubble. Show this while the Foundation Models framework is generating a response. This masks latency and reinforces the "real person texting" feeling.
- **Buddy avatar**: Small circular avatar next to buddy messages. Can be an emoji, illustrated character, or SF Symbol. Appears only on the first message in a group from the buddy.
- **Quick reply buttons**: Optional row of tappable pills below the input field for common responses ("Yes ✅", "Not today", "Partially"). These are convenience shortcuts that feed text into the conversation engine as if the user typed them.
- **Input field**: Standard text input at the bottom with send button. Auto-focus when the view appears from a notification tap.
- **Scroll behavior**: Auto-scroll to bottom on new messages. Load older messages on scroll-up.

### ConversationsListView Design

The main screen shows active buddy conversations, one per habit:

- Each row shows: buddy name/avatar, habit name as subtitle, last message preview, timestamp, unread indicator if today's check-in hasn't happened
- Sorted by most recent activity
- Visual indicator of streak (small flame icon + number, or similar)
- "Today's check-ins" section at top for habits due today that haven't been completed
- Pull-to-refresh triggers pre-generation of upcoming messages

### OnboardingView Design

The onboarding is itself a conversation with a default buddy:

```
Buddy: Hey there! 👋 I'm your new habit buddy. What should I call you?
User: [types name]
Buddy: Nice to meet you, {name}! I'm here to help you stick to your goals.
       What's one thing you've been wanting to do more consistently?
User: [types habit]
Buddy: Love that! How often do you want to do {habit}?
       [Quick reply buttons: Every day / Weekdays / A few times a week]
User: [selects]
Buddy: And what time should I check in with you?
       [Time picker appears]
User: [selects time]
Buddy: Perfect! I'll text you at {time} to see how {habit} went.
       One last thing — what vibe do you want from me?
       [Personality cards: Supportive Friend / Tough Coach / Chill Companion / Hype Partner]
User: [selects]
Buddy: Great choice! I'm {personality description}. Let's do this, {name}! 💪
       I'll check in with you {tomorrow/today} at {time}. Talk soon!
```

---

## CloudKit / iCloud Sync Configuration

### Xcode Project Setup

1. Target → Signing & Capabilities → add **iCloud** capability
2. Check **CloudKit** under iCloud services
3. Add CloudKit container: `iCloud.com.{bundleId}`
4. Add **Background Modes** capability → check **Remote Notifications**

### SwiftData ModelContainer Setup

```swift
@main
struct NudgeApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                UserProfile.self,
                Habit.self,
                CheckIn.self,
                Conversation.self,
                Message.self,
                PreGeneratedMessage.self
            ])

            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )

            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
```

### CloudKit Constraints Checklist

- [x] All `@Model` properties have default values or are optional
- [x] All `@Relationship` properties are optional
- [x] No `@Attribute(.unique)` on any synced property
- [x] Background Modes → Remote Notifications enabled
- [ ] Test on real device (simulator is unreliable for CloudKit)

---

## Conversation Engine — Full Flow

### 1. Notification Triggers Conversation

```
User receives notification: "Hey Sarah! Did you get your 30-min walk in today?"
User taps notification → App opens to ChatView for this habit's conversation
```

### 2. Conversation Initialization

```swift
func startCheckIn(for habit: Habit) async {
    // Create new conversation
    let conversation = Conversation()
    conversation.date = Date()
    conversation.habit = habit
    conversation.emotionalState = calculateEmotionalState(for: habit).rawValue

    // Create check-in record
    let checkIn = CheckIn()
    checkIn.date = Date()
    checkIn.habit = habit
    checkIn.conversation = conversation

    // Get opening message (pre-generated or template fallback)
    let openingText = consumePreGeneratedMessage(for: habit)
        ?? generateFallbackOpening(for: habit)

    let openingMessage = Message()
    openingMessage.content = openingText
    openingMessage.role = "buddy"
    openingMessage.conversation = conversation

    // Save to SwiftData
    // Display in ChatView with typing indicator animation before reveal
}
```

### 3. User Responds → Classification + Reply

```swift
func handleUserResponse(_ userText: String, conversation: Conversation, habit: Habit) async {
    // Save user message
    let userMessage = Message()
    userMessage.content = userText
    userMessage.role = "user"
    userMessage.conversation = conversation

    // Show typing indicator
    // Create session with full context
    let session = createBuddySession(for: habit)

    // Replay conversation history into session
    for msg in (conversation.messages ?? []).sorted(by: { $0.timestamp < $1.timestamp }) {
        if msg.role == "buddy" {
            // Add as assistant turn
        } else {
            // Add as user turn
        }
    }

    do {
        // Get structured response
        let result = try await session.respond(
            to: userText,
            generating: CheckInResult.self
        )

        // Validate the buddy message
        let buddyText: String
        if validateBuddyMessage(result.buddyMessage, habitName: habit.name) {
            buddyText = result.buddyMessage
        } else {
            buddyText = getTemplateFallback(status: result.status, emotion: conversation.emotionalState)
        }

        // Save buddy response
        let buddyMessage = Message()
        buddyMessage.content = buddyText
        buddyMessage.role = "buddy"
        buddyMessage.conversation = conversation

        // Update check-in status
        conversation.checkIn?.status = result.status.rawValue

        // Handle follow-up or end conversation
        if result.shouldFollowUp && !result.followUpMessage.isEmpty {
            let followUp = Message()
            followUp.content = result.followUpMessage
            followUp.role = "buddy"
            followUp.timestamp = Date().addingTimeInterval(1) // Slight delay
            followUp.conversation = conversation
        } else {
            // Conversation complete — update streaks
            conversation.isComplete = true
            updateStreaks(for: habit, with: result.status)
        }

    } catch {
        // LLM failed — use template fallback
        let fallback = Message()
        fallback.content = "Got it! Thanks for checking in 😊"
        fallback.role = "buddy"
        fallback.conversation = conversation
    }
}
```

### 4. Streak Update Logic

```swift
func updateStreaks(for habit: Habit, with status: CheckInStatus) {
    let today = Calendar.current.startOfDay(for: Date())
    habit.lastCheckInDate = today

    switch status {
    case .completed:
        habit.currentStreak += 1
        habit.consecutiveMisses = 0
        habit.lastCompletedDate = today
        if habit.currentStreak > habit.longestStreak {
            habit.longestStreak = habit.currentStreak
        }

    case .partial:
        // Partial counts toward streak but doesn't reset misses
        habit.currentStreak += 1
        habit.consecutiveMisses = 0
        habit.lastCompletedDate = today
        if habit.currentStreak > habit.longestStreak {
            habit.longestStreak = habit.currentStreak
        }

    case .missed:
        habit.currentStreak = 0
        habit.consecutiveMisses += 1

    case .skipped:
        // Skipped doesn't break streak or count as miss
        // (sick day, travel, etc.)
        break

    case .unclear:
        // Don't update anything — buddy should follow up
        break
    }
}
```

---

## Missed Day Detection

If the user doesn't respond to a check-in by end of day, auto-record a miss:

```swift
// Run via BGTaskScheduler or on next app open
func reconcileMissedCheckIns() {
    let today = Calendar.current.startOfDay(for: Date())

    for habit in activeHabits {
        // Check all days since last check-in
        guard let lastCheckIn = habit.lastCheckInDate else {
            // Never checked in — don't auto-miss, let first check-in happen naturally
            continue
        }

        var checkDate = Calendar.current.date(byAdding: .day, value: 1, to: lastCheckIn)!

        while checkDate < today {
            if habitIsDue(habit, on: checkDate) {
                // No check-in exists for this date — record a miss
                let checkIn = CheckIn()
                checkIn.date = checkDate
                checkIn.status = "missed"
                checkIn.habit = habit

                habit.currentStreak = 0
                habit.consecutiveMisses += 1
            }
            checkDate = Calendar.current.date(byAdding: .day, value: 1, to: checkDate)!
        }
    }
}
```

---

## Project File Structure

```
Nudge/
├── NudgeApp.swift                     // App entry point, ModelContainer setup
├── ContentView.swift                        // Root navigation (tab bar)
│
├── Models/
│   ├── UserProfile.swift                    // UserProfile SwiftData model
│   ├── Habit.swift                          // Habit SwiftData model
│   ├── CheckIn.swift                        // CheckIn SwiftData model
│   ├── Conversation.swift                   // Conversation SwiftData model
│   ├── Message.swift                        // Message SwiftData model
│   ├── PreGeneratedMessage.swift            // PreGeneratedMessage SwiftData model
│   ├── BuddyPersonality.swift              // BuddyPersonality enum + descriptions
│   └── BuddyEmotion.swift                  // BuddyEmotion enum + calculation
│
├── LLM/
│   ├── ConversationEngine.swift             // Core conversation logic (session creation, response handling)
│   ├── GenerableSchemas.swift               // @Generable structs (CheckInResult, OpeningMessage, WeeklyRecap)
│   ├── BuddyTools.swift                     // Tool definitions for Foundation Models
│   ├── TemplateFallbacks.swift              // All template message pools
│   └── MessageValidator.swift               // LLM output validation
│
├── Services/
│   ├── HabitManager.swift                   // Habit CRUD, streak calculations, missed day reconciliation
│   ├── NotificationManager.swift            // Local notification scheduling and handling
│   ├── PreGenerationService.swift           // Pre-generate opening messages for upcoming days
│   └── BackgroundTaskManager.swift          // BGTaskScheduler setup and handlers
│
├── Views/
│   ├── Conversations/
│   │   ├── ConversationsListView.swift      // Main screen — list of buddy conversations
│   │   ├── ConversationRow.swift            // Single row in the conversations list
│   │   ├── ChatView.swift                   // Full conversation thread
│   │   ├── MessageBubble.swift              // Single message bubble
│   │   ├── TypingIndicator.swift            // Animated typing dots
│   │   └── QuickReplyBar.swift              // Quick-reply button row
│   │
│   ├── Habits/
│   │   ├── HabitsListView.swift             // Manage habits screen
│   │   ├── HabitDetailView.swift            // Habit settings + stats
│   │   ├── HabitFormView.swift              // Create/edit habit form
│   │   └── StreakCalendarView.swift          // GitHub-style streak grid
│   │
│   ├── Onboarding/
│   │   ├── OnboardingView.swift             // Onboarding container
│   │   └── OnboardingChatView.swift         // Conversational onboarding flow
│   │
│   └── Settings/
│       └── SettingsView.swift               // App preferences
│
├── Components/
│   ├── BuddyAvatar.swift                   // Buddy avatar component (used in chat + list)
│   ├── StreakBadge.swift                    // Small streak indicator (flame + number)
│   └── PersonalityCard.swift               // Personality selection card (used in onboarding)
│
└── Utilities/
    ├── DateHelpers.swift                    // Date formatting, relative time, calendar helpers
    └── HabitScheduleHelpers.swift           // Determine if a habit is due on a given date
```

---

## Build Phases

### Phase 1 — Core Chat Loop (Weeks 1–4)

**Goal**: A working conversation between a buddy and user that classifies habit completion.

**Tasks**:
- [ ] Set up Xcode project with SwiftData and Foundation Models framework
- [ ] Implement all SwiftData models (Habit, CheckIn, Conversation, Message)
- [ ] Build ChatView with iMessage-style bubbles, typing indicator, and input field
- [ ] Integrate Foundation Models: create session, generate responses, use Guided Generation for CheckInResult
- [ ] Build ConversationEngine with full check-in flow (open → respond → classify → update)
- [ ] Implement template fallback system
- [ ] Implement message validation
- [ ] Create a single hardcoded test habit for development
- [ ] Build ConversationsListView showing active conversations
- [ ] Test full conversation loop end-to-end

**Deliverable**: You can open the app, tap into a conversation, and have a back-and-forth check-in with the buddy that correctly identifies whether you completed your habit and responds appropriately.

### Phase 2 — Emotional Intelligence (Weeks 5–7)

**Goal**: The buddy's tone adapts based on streak data and history.

**Tasks**:
- [ ] Implement BuddyEmotion calculation logic
- [ ] Wire emotional state into session instructions
- [ ] Build full template message pools for all emotion × status combinations
- [ ] Implement streak tracking logic (current streak, longest streak, consecutive misses)
- [ ] Add milestone detection (7, 14, 21, 30, 60, 90 days)
- [ ] Implement missed day reconciliation (auto-record misses for past days)
- [ ] Add Tool Calling for streak lookup during conversations
- [ ] Test emotional tone across different streak scenarios
- [ ] Add subtle UI cues for emotional state (buddy avatar expression or bubble color tint)

**Deliverable**: Conversations feel emotionally appropriate. A 10-day streak gets enthusiasm, a 3-day miss streak gets gentle concern, hitting 30 days gets a celebration.

### Phase 3 — Onboarding & Habit Management (Weeks 8–9)

**Goal**: Users can set up their own habits and buddy through a conversational onboarding flow.

**Tasks**:
- [ ] Build OnboardingChatView — conversational flow for name, first habit, frequency, time, personality
- [ ] Implement UserProfile model and persistence
- [ ] Build HabitsListView and HabitFormView for creating/editing habits
- [ ] Implement buddy personality selection with PersonalityCard components
- [ ] Build HabitDetailView showing basic streak info
- [ ] Support multiple habits with separate conversations
- [ ] Wire up notification permission request during onboarding
- [ ] Implement notification scheduling (one per habit at chosen time)

**Deliverable**: A new user can go through onboarding, create their first habit conversationally, and add more habits through the habits list. Each habit has its own buddy conversation.

### Phase 4 — Notifications & Pre-Generation (Weeks 10–11)

**Goal**: The buddy proactively reaches out via notifications that feel like text messages.

**Tasks**:
- [ ] Implement NotificationManager (schedule, reschedule, cancel notifications per habit)
- [ ] Register notification categories with quick-reply actions (Yes/No/Open)
- [ ] Handle notification tap → deep link directly into ChatView for that habit
- [ ] Handle quick-reply actions (Yes → auto-complete, No → open chat, Open → open chat)
- [ ] Build PreGenerationService — generate next 3 days of opening messages during foreground use
- [ ] Implement pre-generated message consumption and rotation
- [ ] Wire up notification content from pre-generated messages with template fallback
- [ ] Set up BGTaskScheduler for daily missed-check-in reconciliation
- [ ] Test notification flow end-to-end (receive notification → tap → chat → complete check-in)

**Deliverable**: User gets a notification at their scheduled time that reads like a text from their buddy. Tapping it opens the conversation. Quick replies work from the lock screen.

### Phase 5 — iCloud Sync (Week 12)

**Goal**: Data syncs across user's devices via iCloud.

**Tasks**:
- [ ] Enable CloudKit in Xcode project capabilities
- [ ] Configure ModelContainer with `.automatic` CloudKit database
- [ ] Verify all models meet CloudKit constraints (defaults, optional relationships)
- [ ] Test sync between two real devices (iPhone to iPhone, or iPhone to iPad)
- [ ] Handle edge cases: first install data restore, offline changes syncing later
- [ ] Add availability check (handle case where user is not signed into iCloud)

**Deliverable**: A user's habits, conversations, and streaks appear on any device signed into the same iCloud account.

### Phase 6 — Stats & History (Weeks 13–14)

**Goal**: Users can view their progress and browse past conversations.

**Tasks**:
- [ ] Build StreakCalendarView (GitHub-contribution-style grid showing completion by day)
- [ ] Add stats to HabitDetailView (current streak, longest streak, completion rate, total completions)
- [ ] Implement weekly recap generation (buddy sends a summary message on Sundays/Mondays)
- [ ] Build conversation history — scroll back through past check-in conversations
- [ ] Add "Today's Check-ins" section to ConversationsListView (habits due today, not yet completed)

**Deliverable**: Users can see a visual calendar of their habit history, view stats, and scroll through past buddy conversations.

### Phase 7 — Polish & Launch (Weeks 15–17)

**Goal**: Production-ready app for App Store submission.

**Tasks**:
- [ ] Device compatibility check on launch (show friendly message if device doesn't support Apple Intelligence)
- [ ] Performance optimization: measure LLM inference time, battery impact during conversations
- [ ] Empty states for all views (no habits yet, no conversations yet, no stats yet)
- [ ] Error handling: model unavailable, CloudKit failures, notification permission denied
- [ ] Haptic feedback on streak milestones and check-in completions
- [ ] App icon design
- [ ] App Store screenshots and preview video
- [ ] App Store description and metadata
- [ ] Privacy policy (emphasize on-device processing, iCloud data stays in user's account)
- [ ] TestFlight beta with 20-50 users
- [ ] Iterate on buddy prompt instructions based on real conversations
- [ ] Final QA pass

**Deliverable**: App submitted to the App Store.

---

## Future Enhancements (Post-Launch)

These are features to consider after the initial launch, based on user feedback:

- **Buddy memory**: The buddy references past conversations ("Last Tuesday you mentioned you were going to try morning runs — how's that going?"). Implement by including last N conversation summaries in session instructions.
- **Smart scheduling**: If user consistently checks in at a different time than scheduled, buddy suggests adjusting.
- **Streak recovery**: "You missed yesterday, but if you complete the next 2 days, I'll keep your streak alive." Configurable grace period.
- **Multiple buddies**: Different buddy characters (not just personalities) with unique names, avatars, and conversational styles.
- **Social sharing**: Share milestone achievements to social media or Messages.
- **Widget**: iOS home screen widget showing today's habits and streak counts.
- **Watch app**: Quick check-in via Apple Watch notification.
- **Habit categories**: Group habits (Health, Learning, Productivity) with category-level stats.
- **Custom buddy avatar**: Let users pick or create their buddy's appearance.
- **Habit reminders adaptation**: Buddy learns best times and adjusts suggestions.

---

## Key Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Foundation Models output quality too low for natural conversation | High | Template fallback system, constrained prompts, 40-word limit, Guided Generation for structure |
| Background notification pre-generation fails on iOS | Medium | Pre-generate during foreground use (3 days ahead), template fallbacks for edge cases |
| CloudKit sync unreliable or slow | Medium | App works fully offline — sync is additive. Test on real devices early. |
| Device requirement (iPhone 15 Pro+) limits market | Medium | Accepted trade-off. Target audience skews toward newer devices. |
| Apple Intelligence not enabled by user | Medium | Show clear onboarding prompt explaining requirement with link to Settings |
| Model guardrails block legitimate buddy messages | Low | Keep prompts clearly within safe territory. Test edge cases in Xcode Playgrounds. |
| Users find conversations repetitive over time | Medium | Invest in diverse template pools, use streak context and time-of-day variation in prompts, iterate post-launch |

---

## Development Environment Setup

### Prerequisites

- Mac running macOS 26 (Tahoe)
- Xcode 26
- iPhone 15 Pro or later for testing (simulator insufficient for Foundation Models and CloudKit)
- Apple Developer Program membership (required for CloudKit and App Store)
- Apple Intelligence enabled on test device

### Initial Project Setup

1. Create new Xcode project → iOS App → SwiftUI → SwiftData
2. Set minimum deployment target to iOS 26.0
3. Add capabilities: iCloud (CloudKit), Background Modes (Remote Notifications, Background Processing)
4. Create CloudKit container: `iCloud.com.{your-team-id}.nudge`
5. Import `FoundationModels` in relevant files
6. Test Foundation Models availability on device before proceeding

### Testing Foundation Models Availability

```swift
import FoundationModels

let model = SystemLanguageModel.default

switch model.availability {
case .available:
    print("Ready to go")
case .unavailable(let reason):
    print("Model unavailable: \(reason)")
    // Show user-facing message about enabling Apple Intelligence
}
```
