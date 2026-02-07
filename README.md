# Nudge

A native iOS habit tracking app where a virtual "buddy" initiates text-message-style conversations to check in on your habits. No dashboards, no checkboxes — just a friend who texts you.

## What Makes Nudge Different

- **Conversational habit tracking** — your buddy texts you, you respond naturally
- **Emotional intelligence** — the buddy's tone adapts to your streak history (celebrating wins, encouraging after misses, showing concern during lapses)
- **Fully offline** — all data and AI inference runs on-device using Apple's Foundation Models framework
- **Complete privacy** — habit data and conversations never leave your device (except your private iCloud for sync)
- **No ongoing costs** — no API keys, no servers, no subscriptions

## Requirements

- iOS 26+ (iPhone 15 Pro or later — A17 Pro chip minimum)
- Apple Intelligence enabled
- Xcode 26 / macOS 26 (Tahoe) for development

## Tech Stack

| Layer | Framework |
|---|---|
| Language | Swift 6.2 |
| UI | SwiftUI |
| LLM | Foundation Models |
| Local Database | SwiftData |
| Cross-Device Sync | CloudKit (automatic via SwiftData) |
| Notifications | UserNotifications (local, scheduled) |
| Background Tasks | BGTaskScheduler |

No third-party dependencies.

## Architecture

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

### Key Principles

1. **Offline-first** — all data and AI inference runs locally; iCloud sync is additive
2. **Chat-first UI** — the primary interface is a conversation thread, not a dashboard
3. **Structured LLM output** — Guided Generation (`@Generable` / `@Guide`) for typed Swift structs
4. **Template fallbacks** — every LLM-generated message has a curated fallback
5. **Pre-generated notifications** — opening messages are generated ahead of time during foreground use

## How It Works

1. You create a habit and choose a buddy personality (Supportive Friend, Tough Coach, Chill Companion, or Hype Partner)
2. At your scheduled time, the buddy sends a notification that reads like a text message
3. You tap in and have a quick, natural conversation about whether you did the habit
4. The buddy classifies your response, updates your streak, and responds with the right emotional tone
5. Over time, the buddy adapts — celebrating streaks, gently nudging after misses, welcoming you back after lapses

## Project Structure

```
Nudge/
├── NudgeApp.swift
├── ContentView.swift
├── Models/                    # SwiftData models
├── LLM/                      # Conversation engine, schemas, templates, validation
├── Services/                  # Habit management, notifications, pre-generation
├── Views/
│   ├── Conversations/         # Chat UI (messages, bubbles, typing indicator)
│   ├── Habits/                # Habit management and stats
│   ├── Onboarding/            # Conversational first-launch flow
│   └── Settings/
├── Components/                # Reusable UI (avatars, streak badges, personality cards)
└── Utilities/                 # Date and schedule helpers
```

## Development Setup

1. Open the project in Xcode 26 on macOS 26
2. Set minimum deployment target to iOS 26.0
3. Ensure capabilities are configured: iCloud (CloudKit), Background Modes (Remote Notifications, Background Processing)
4. Test on a physical iPhone 15 Pro or later with Apple Intelligence enabled (simulator is insufficient for Foundation Models and CloudKit)

## Build Phases

| Phase | Focus |
|---|---|
| 1 | Core chat loop — working buddy conversation with habit classification |
| 2 | Emotional intelligence — tone adapts based on streak data |
| 3 | Onboarding & habit management — conversational setup, multiple habits |
| 4 | Notifications & pre-generation — proactive buddy check-ins |
| 5 | iCloud sync — cross-device data sync |
| 6 | Stats & history — streak calendar, weekly recaps, conversation history |
| 7 | Polish & launch — error handling, empty states, App Store submission |

## License

All rights reserved.