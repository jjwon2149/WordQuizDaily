# Architecture Overview

WordQuizDaily is organized around a small SwiftUI app surface with MVVM-style state management, local learning content, and optional network-powered enrichment.

## Runtime Flow

```text
ContentView
├── QuizView + QuizViewModel
├── HomeView + HomeViewModel
└── SettingView + FCMNotificationManager
```

- `ContentView` owns the main tab navigation and injects shared view models into each tab.
- `HomeViewModel` selects the daily learning word, persists the daily selection token, and exposes the learner-facing summary.
- `QuizViewModel` selects quiz words, generates answer choices, tracks answer state, and requests optional image data.
- `FCMService` and `FCMNotificationManager` isolate push-notification setup from the SwiftUI screens.

## Data Model

`LearningWord` is the central content model for the foreign learner MVP. It carries the fields needed by the today-word, quiz, feedback, and reminder experiences:

- Korean word
- English meaning
- Easy Korean definition
- Romanization
- Part of speech
- Difficulty
- Example sentence
- Example translation
- Incorrect-answer feedback

`LearningWordRepository` adapts the shared Foundation-only `LearningCore` package to the app. The package owns typed levels and parts of speech, bundled content validation, daily selection, quiz selection, durable progress, and review sessions. The app and widget use the same bundled catalog rather than separate word sources.

## Learning Continuity

- The bundled JSON currently contains 66 words: 20 beginner, 25 intermediate, and 21 advanced, including nouns, verbs, and adjectives. These are app difficulty groups, not certified TOPIK levels.
- A shared app learning store connects Home, Quiz, and Settings. Progress is local to the device; there is no account or remote history service.
- Incorrect answers enter review. Two subsequent consecutive correct answers clear the review requirement; another mistake resets that progress. A session contains up to ten distinct words, oldest study time first.
- Selection excludes recent questions where possible and uses same-level, same-part-of-speech choices. Audited conflict groups keep ambiguous meanings out of a question's choices.
- Record files are versioned and saved atomically. Unsupported versions must be preserved, corrupt files quarantined before recovery, and failed saves shown to the user.
- The daily selector respects a valid existing same-day cache during upgrades. Widget timeline entries carry their own dated word instead of reading an undated last-used word in the view.

Implementation and execution evidence are tracked in the [release verification record](qa/next-release-verification.md); this architecture description is not evidence of device QA or a shipped release.

## External Integrations

| Integration | Responsibility |
| --- | --- |
| Firebase Analytics | App analytics initialization |
| Firebase Messaging | Push notification registration and token handling |
| Google Mobile Ads | Banner ad rendering |
| Kingfisher | Remote image loading and fallback handling |
| Naver Image Search | Optional quiz image enrichment |

The learning content itself is local-first. External services should enrich the experience, not block the core study flow.

Repeating study reminders are scheduled locally, use generic localized copy, and retain the user's wall-clock hour and minute. FCM receiving and navigation remain supported, but remote scheduling is not implemented. Notification payloads do not replace the shared daily word. Tokens and raw payloads are not application log content.

## Localization

Localized resources live in:

```text
WordQuizDaily/WordQuizDaily/Resources/Localizations/
├── ko.lproj
├── en.lproj
└── ja.lproj
```

Screen text should resolve through localization keys rather than hard-coded display strings. Learning-word values can be localized through model helpers such as `meaning(for:)`, `exampleTranslation(for:)`, `localizedDifficulty(for:)`, and `localizedPartOfSpeech(for:)`.

## Engineering Notes

- Keep app secrets and local signing configuration out of Git.
- Keep the local learning-word data complete enough that the app can answer a quiz without network access.
- Keep network failure states user-friendly and non-blocking.
- Add documentation whenever the MVP scope, data contract, or reviewer QA expectations change.
