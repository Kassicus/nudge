//
//  TemplateFallbacks.swift
//  Nudge
//

import Foundation

struct TemplateFallbacks {

    // MARK: - Opening Message Templates

    private static let openingTemplates: [BuddyEmotion: [String]] = [
        .neutral: [
            "Hey! How did {habit} go today?",
            "Hi! Checking in — did you get to {habit}?",
            "Hey! Quick check-in on {habit} today 😊"
        ],
        .proud: [
            "Hey! {streak} days strong 💪 Did you keep it going today?",
            "{streak} days in a row! Tell me you made it {streak_plus_one} 🔥",
            "Look at you on day {streak}! How was {habit} today?"
        ],
        .excited: [
            "You're on your LONGEST streak ever! {streak} days! Did today make it {streak_plus_one}?",
            "Personal best alert! 🎉 {streak} days! Please tell me you kept it going!"
        ],
        .celebratory: [
            "🎉 {streak} DAYS!! That's incredible! Did you make it today too?",
            "MILESTONE! {streak} days of {habit}! I'm so proud. How about today?"
        ],
        .supportive: [
            "Hey, yesterday was just one day. Fresh start today — how did {habit} go?",
            "New day, clean slate! Did you get to {habit} today?"
        ],
        .concerned: [
            "Hey, I've noticed it's been a few days. Everything okay? No pressure, just checking in ❤️",
            "Missing you! It's been {miss_count} days. Want to talk about what's getting in the way?"
        ],
        .welcomeBack: [
            "Hey! Been a while. I'm glad you're here. Want to get back to {habit}?",
            "Welcome back! No judgment — let's just pick up where we left off. How are you?"
        ]
    ]

    // MARK: - Response Templates (by status and emotion)

    private static let responseTemplates: [String: [String: [String]]] = [
        "completed": [
            "neutral": ["Nice work! ✅ That's what I like to see.", "Awesome, checked off for today! 👏"],
            "proud": ["That's {streak} days! You're on fire 🔥", "{streak} in a row — you're building something real here."],
            "excited": ["NEW PERSONAL BEST! {streak} days! You're unstoppable! 🎉", "You just broke your own record! {streak} days! 🔥"],
            "celebratory": ["🎉🎉🎉 {streak} DAYS! I can't even handle how proud I am!"],
            "supportive": ["YES! Back on track! That's the spirit 💪", "Knew you'd bounce back. Great job today!"],
            "concerned": ["You did it! So glad to see you back at it 😊"],
            "welcomeBack": ["Welcome back AND you crushed it! Love to see it 💪"]
        ],
        "missed": [
            "neutral": ["No worries — tomorrow's a new day.", "That's okay! One day doesn't define the journey."],
            "proud": ["Streak paused, but all that progress isn't gone. Tomorrow! 💪"],
            "excited": ["Hey, even record-breakers take a rest day. You'll get back to it! 💪"],
            "celebratory": ["The streak pauses but wow, what a run! {streak} days is still amazing 🎉"],
            "supportive": ["Hey, it happens. Don't be hard on yourself. Tomorrow's there for you."],
            "concerned": ["I hear you. Is there something making it harder lately? I'm here if you want to talk about it."],
            "welcomeBack": ["No stress at all. The fact that you're here means a lot. One step at a time."]
        ],
        "partial": [
            "neutral": ["Partial counts! Some is better than none.", "Hey, you still showed up. That matters."],
            "proud": ["Still showed up, that's what counts! Almost there 💪"],
            "excited": ["Even a partial day keeps momentum going! Still at {streak} days 🔥"],
            "celebratory": ["Partial on a milestone streak? Still incredible. Keep it rolling! 🎉"],
            "supportive": ["Showing up partially is still showing up. Proud of you!"],
            "concerned": ["Every little bit helps. Glad you did something today."],
            "welcomeBack": ["You showed up and did some — that's huge after a break! 💪"]
        ],
        "skipped": [
            "neutral": ["Totally fair. Rest when you need to. We'll pick back up tomorrow.", "Got it — take care of yourself first. See you tomorrow! ❤️"],
            "excited": ["Rest days are part of the journey. {streak} days is still amazing!"],
            "proud": ["Smart call if you need rest. Your {streak}-day streak shows real commitment."],
            "celebratory": ["Even champions rest! Your {streak}-day run speaks for itself 🎉"],
            "supportive": ["Self-care comes first. See you when you're ready!"],
            "concerned": ["Take all the time you need. I'll be here when you're ready."],
            "welcomeBack": ["Totally okay. No rush — just glad you checked in. 😊"]
        ],
        "unclear": [
            "neutral": ["Hmm, I'm not quite sure — did you get to it today?", "So... did you do it? 😄"],
            "proud": ["Ha — not sure I caught that! Did you keep the {streak}-day streak alive? 💪"],
            "excited": ["Wait, I need to know — did you break your record today?! 🔥"],
            "celebratory": ["Hold on — did you hit the milestone or not?! The suspense! 🎉"],
            "supportive": ["I didn't quite catch that — how did it go today?"],
            "concerned": ["Not sure I followed — no pressure, just want to know how you're doing."],
            "welcomeBack": ["I'm just glad you're here! So… did you get to {habit}? 😊"]
        ]
    ]

    // MARK: - Public Functions

    static func generateFallbackOpening(for habit: Habit) -> String {
        let emotion = BuddyEmotion.calculateEmotionalState(for: habit)
        let templates = openingTemplates[emotion] ?? openingTemplates[.neutral]!
        let template = templates.randomElement()!
        return fillPlaceholders(template, habit: habit)
    }

    static func getTemplateFallback(status: CheckInStatus, emotion: String) -> String {
        let statusKey = status.rawValue
        let emotionTemplates = responseTemplates[statusKey] ?? [:]

        if let templates = emotionTemplates[emotion], let template = templates.randomElement() {
            return template
        }

        if let neutralTemplates = emotionTemplates["neutral"], let template = neutralTemplates.randomElement() {
            return template
        }

        return "Got it! Thanks for checking in 😊"
    }

    static func getTemplateFallback(status: CheckInStatus, emotion: String, habit: Habit) -> String {
        let template = getTemplateFallback(status: status, emotion: emotion)
        return fillPlaceholders(template, habit: habit)
    }

    // MARK: - Placeholder Filling

    private static func fillPlaceholders(_ template: String, habit: Habit) -> String {
        var result = template
        result = result.replacingOccurrences(of: "{habit}", with: habit.name)
        result = result.replacingOccurrences(of: "{name}", with: habit.buddyName)
        result = result.replacingOccurrences(of: "{streak}", with: "\(habit.currentStreak)")
        result = result.replacingOccurrences(of: "{streak_plus_one}", with: "\(habit.currentStreak + 1)")
        result = result.replacingOccurrences(of: "{miss_count}", with: "\(habit.consecutiveMisses)")
        return result
    }
}
