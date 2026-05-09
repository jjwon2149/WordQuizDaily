# WordQuizDaily

![iOS](https://img.shields.io/badge/iOS-17.0+-111827?style=flat-square&logo=apple&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Production_App-0ea5e9?style=flat-square&logo=swift&logoColor=white)
![Localization](https://img.shields.io/badge/Localization-KO%20%7C%20EN%20%7C%20JA-16a34a?style=flat-square)
![Status](https://img.shields.io/badge/App%20Store-Live-2563eb?style=flat-square)

**WordQuizDaily** is a SwiftUI vocabulary learning app that helps learners review one Korean word every day, solve short quizzes, and keep a steady study rhythm through reminders.

The project is built as a real App Store product, with localized resources, widget support, push notification integration, and a local learning-word model designed to keep the core study flow available even when remote services are unavailable.

[View App Store](https://apps.apple.com/kr/app/%EC%9A%B0%EB%A6%AC%EB%A7%90-%EB%8B%A8%EC%96%B4-%ED%80%B4%EC%A6%88-korean-words-quiz/id6505052767) · [Product Page](https://jjwon2149.github.io/WordQuizDaily/) · [Project Docs](docs/README.md)

![WordQuizDaily screenshots](docs/groupScreenshot.png)

## Why This Project Stands Out

- **Product-minded iOS implementation**: today word, quiz, reminder, widget, and App Store presentation are treated as one user journey.
- **Offline-first learning data**: the MVP learning content is stored locally so definitions, examples, romanization, and feedback can load without depending on a server.
- **Localized learner experience**: Korean, English, and Japanese resources support a broader learner audience.
- **Maintainable SwiftUI structure**: screens, view models, models, network clients, services, helpers, and localization resources are separated by responsibility.
- **Recruiter-friendly documentation**: product scope, architecture notes, QA checklist, and implementation boundaries are documented for reviewers.

## Core Features

| Area | Description |
| --- | --- |
| Today Word | Shows a daily Korean word with learner-friendly definition, romanization, part of speech, difficulty, and example sentence. |
| Quiz | Generates multiple-choice quizzes from the local learning-word repository and gives answer feedback after submission. |
| Feedback | Explains the correct answer with meaning, example, romanization, difficulty, and review hints. |
| Reminder | Supports notification-driven study habits through Firebase Cloud Messaging integration. |
| Widget | Provides a home-screen widget target for quick daily-word exposure. |
| Localization | Maintains Korean, English, and Japanese resource files for app labels and learning flow text. |

## Tech Stack

- **Language/UI**: Swift, SwiftUI
- **Architecture**: MVVM-style screen state with `ObservableObject` view models
- **Data**: Local `LearningWordRepository` sample data and validation rules
- **Networking/Media**: Naver image search integration, Kingfisher image loading
- **Notifications/Analytics**: Firebase Analytics, Firebase Messaging
- **Monetization**: Google Mobile Ads banner integration
- **Distribution Assets**: App Store screenshots and GitHub Pages product page

## Project Structure

```text
WordQuizDaily/
├── WordQuizDaily/
│   ├── WordQuizDaily/              # Main SwiftUI app target
│   │   ├── Models/                 # Learning words, Naver response models
│   │   ├── Views/                  # Home, quiz, settings, AdMob views
│   │   ├── Network/                # Naver API clients
│   │   ├── Services/               # FCM service and notification manager
│   │   ├── Helpers/                # Localization and formatting helpers
│   │   └── Resources/Localizations # ko, en, ja strings
│   ├── WordQuizWidget/             # Widget extension
│   └── NotificationServiceExtension/
├── AppStoreScreenshots/            # Store-ready screenshots
├── docs/                           # Product page and project documentation
└── tools/                          # Screenshot framing utility
```

## Getting Started

### Requirements

- macOS with Xcode 15 or newer
- iOS 17.0+ deployment target for the main app
- CocoaPods if you want to install pod-based dependencies
- Firebase configuration file for local notification/analytics builds

### Local Setup

1. Clone the repository.
2. Run `pod install` inside the `WordQuizDaily/` directory if the `Pods/` support files are not present locally.
3. Copy `WordQuizDaily/WordQuizDaily/Config.xcconfig.example` to `WordQuizDaily/WordQuizDaily/Config.xcconfig` and fill in local API/ad identifiers.
4. Add a valid `GoogleService-Info.plist` to the app target when building Firebase-enabled flows.
5. Open `WordQuizDaily/WordQuizDaily.xcworkspace` in Xcode.
6. Confirm signing settings for the app, widget, and notification extension targets.
7. Build and run the `WordQuizDaily` scheme on an iOS simulator or device.

`GoogleService-Info.plist` and local `.xcconfig` files are intentionally ignored by Git because they contain environment-specific configuration.

## Documentation

- [Documentation Index](docs/README.md)
- [Architecture Overview](docs/architecture.md)
- [Foreign Learner MVP Scope](docs/foreign-learner-mvp.md)
- [Current Structure Analysis](docs/foreign-learner-mvp-analysis.md)
- [Reviewer QA Checklist](docs/qa/foreign-learner-mvp-checklist.md)

## Product Direction

The next product milestone focuses on foreign Korean learners. The MVP keeps the existing today-word, quiz, and reminder flows, then strengthens them with:

- English meaning
- Easy Korean definition
- Romanization
- Part of speech
- Difficulty
- Korean example sentence
- English example translation
- Incorrect-answer feedback

This keeps the learning experience clear, reviewable, and resilient without requiring a new backend during the MVP phase.

## Privacy

WordQuizDaily does not require account creation for the core learning flow. The MVP learning content is local-first and does not depend on server-side personal study history.

## Contact

- Developer: Jongwon Jeong
- Email: jjwon2149@gmail.com

## Commit Convention

- `feat`: new feature
- `fix`: bug fix
- `docs`: documentation update
- `style`: formatting-only change
- `refactor`: code refactor
- `test`: test update
- `chore`: build or maintenance task
