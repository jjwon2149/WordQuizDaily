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

`LearningWordRepository` validates required fields, removes invalid duplicate data, supports daily deterministic selection, and creates shuffled multiple-choice answers.

## External Integrations

| Integration | Responsibility |
| --- | --- |
| Firebase Analytics | App analytics initialization |
| Firebase Messaging | Push notification registration and token handling |
| Google Mobile Ads | Banner ad rendering |
| Kingfisher | Remote image loading and fallback handling |
| Naver Image Search | Optional quiz image enrichment |

The learning content itself is local-first. External services should enrich the experience, not block the core study flow.

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
