# Foreign Learner MVP QA Checklist

Use this checklist when reviewing PRs for the WordQuizDaily foreign Korean learner MVP. Mark an item only after checking the implementation, the simulator or device behavior, and any changed content files.

## Review Gate

- [ ] The PR description states which surfaces changed: Home, Quiz, Notification, local word data, localization, or shared storage.
- [ ] The PR includes screenshots or a short recording for every changed screen in at least Korean and English.
- [ ] Core learning flows work with network disabled after install-time data is available.
- [ ] Existing tabs remain available: Home, Quiz, and Settings.
- [ ] No user-facing Korean, English, or Japanese string is introduced without localization keys unless it is sample learning content.
- [ ] No API key, FCM token, personal data, or debug-only credential is committed.

## Existing Feature Regression

### Home: Today's Word

- [ ] The Home tab opens without crashing on a clean install.
- [ ] Today's word is visible and uses the expected local word source for the MVP.
- [ ] Today's word has all learner-facing fields available where the design requires them: Korean word, English meaning, easy Korean explanation, example sentence, romanization, and difficulty.
- [ ] The displayed word and explanation do not clip on small devices or with longer words such as `고정관념`, `사시사철`, or `포털사이트`.
- [ ] Returning to Home during the same day does not unexpectedly change the word.
- [ ] Existing shared storage behavior is preserved or intentionally migrated: `TodayWord` and `TodayWordDefinition` continue to support widgets and notifications.
- [ ] If local data is missing or malformed, Home shows a recoverable fallback instead of an empty card or crash.
- [ ] Home still works when external dictionary and image APIs are unavailable.

### Quiz

- [ ] Quiz opens from the tab bar and from notification deep links, if the PR touches notification routing.
- [ ] Each quiz round has exactly one correct answer and no duplicate choices.
- [ ] Distractors are real Korean words from the approved local data set.
- [ ] Choices are similar enough to be useful but not misleading because of identical spelling, identical meaning, or repeated romanization.
- [ ] Selecting the correct answer advances to the next question or shows the expected success state.
- [ ] Selecting a wrong answer shows learner-friendly feedback and does not silently skip the question.
- [ ] Wrong-answer feedback explains why the selected choice is wrong or gives the correct meaning; it is not only "Incorrect."
- [ ] The question prompt, choices, feedback, and any image fallback remain usable offline.
- [ ] Loading states do not permanently disable answer buttons after a failed image or network request.
- [ ] Quiz content is not blocked by Naver image failures; images are enhancement only.

### Notifications

- [ ] Settings still exposes the push notification toggle.
- [ ] Turning notifications on requests iOS notification permission only when needed.
- [ ] Denying permission turns the toggle back off and shows a clear localized alert.
- [ ] Turning notifications off removes pending local backup notifications.
- [ ] Changing notification time updates the pending local backup schedule.
- [ ] Notification title/body use the current locale where supported.
- [ ] Notification content uses the same local/shared today's word data shown on Home.
- [ ] Tapping a notification routes to the intended tab without breaking normal tab navigation.
- [ ] FCM-specific changes preserve local backup notification behavior for offline or server-failure cases.

## Learning Content Quality

Every production word entry added or changed for the MVP should pass these checks.

### Required Fields

- [ ] Korean word is present in Hangul.
- [ ] English meaning is present.
- [ ] Easy Korean explanation is present.
- [ ] Korean example sentence is present.
- [ ] Romanization is present.
- [ ] Difficulty is present.
- [ ] Wrong-answer feedback is present or can be generated from local content.
- [ ] Entry has a stable identifier or another deterministic way to avoid duplicate records.

### English Meaning

- [ ] Uses plain English suitable for a Korean learner, generally one short phrase.
- [ ] Gives the meaning used in the example, not an unrelated dictionary sense.
- [ ] Avoids rare English vocabulary when a simple synonym is available.
- [ ] Avoids unexplained grammar labels as the only meaning.
- [ ] Does not include machine-translation artifacts, awkward fragments, or mixed-language punctuation.

### Easy Korean Explanation

- [ ] Explains the word with easier Korean than the target word.
- [ ] Avoids circular definitions that repeat only the target word or a close derivative.
- [ ] Uses complete, natural Korean sentences.
- [ ] Keeps the explanation short enough for a mobile card.
- [ ] Avoids culturally specific references unless the example also gives context.

### Example Sentence

- [ ] Includes the target word exactly as learners should recognize it.
- [ ] Is natural Korean, not a dictionary fragment.
- [ ] Is short enough to scan on a phone.
- [ ] Matches the selected meaning and difficulty.
- [ ] Avoids sensitive, political, violent, or adult contexts unless the word cannot be taught otherwise.

### Romanization

- [ ] Follows one consistent romanization standard across the data set.
- [ ] Preserves spacing in a way that helps learners map romanization to Hangul.
- [ ] Handles batchim and sound changes consistently.
- [ ] Is supplemental only; Hangul remains the primary learning text.
- [ ] Does not mix romanization styles for the same syllable pattern.

### Difficulty

- [ ] Uses the MVP's agreed scale consistently, such as beginner/intermediate/advanced or TOPIK-style levels.
- [ ] Difficulty matches word frequency, abstraction, grammar burden, and example sentence complexity.
- [ ] Distractors in a quiz round are close enough in difficulty to keep the quiz fair.
- [ ] Advanced words include enough explanation for learners who do not know Sino-Korean roots.

### Wrong-Answer Feedback

- [ ] Uses supportive, neutral language.
- [ ] Names the selected word or correct word when helpful.
- [ ] Gives a concrete clue, meaning contrast, or short correction.
- [ ] Does not shame the learner or use casual jokes that may confuse non-native speakers.
- [ ] Is localized or written so it can be safely localized without changing quiz logic.

## Local Data and Offline Behavior

- [ ] Core word learning data is bundled with the app or otherwise available without a live API request.
- [ ] Home can render a word, meaning, explanation, example, romanization, and difficulty in airplane mode.
- [ ] Quiz can generate questions, choices, answer checks, and feedback in airplane mode.
- [ ] External dictionary API responses are not required for the MVP core path.
- [ ] Naver image search failure does not block word or quiz content.
- [ ] App launch does not hang while waiting for network content.
- [ ] Local data parsing errors include a safe fallback and a reviewer-visible log or error state.
- [ ] Local data changes are deterministic enough for repeatable QA.
- [ ] Shared `UserDefaults` keys used by widgets or notifications are intentionally maintained or migrated.
- [ ] Any data migration has an update-install scenario, not only a clean-install scenario.

## Localization and Copy Quality

- [ ] Every new UI string has entries for `ko`, `en`, and `ja`, or the PR explicitly scopes the missing locale out.
- [ ] Existing localization keys are not duplicated with conflicting values in the same `.strings` file.
- [ ] English UI copy is natural for language learners and avoids developer wording such as "data load failed" when a clearer phrase exists.
- [ ] Korean UI copy uses consistent tone and spacing.
- [ ] Japanese UI copy uses a consistent polite tone and does not contain untranslated Korean names or fragments unless intentionally proper nouns.
- [ ] Button labels are short enough for the smallest supported device.
- [ ] Error, empty, permission-denied, and offline states are localized.
- [ ] Learning content and UI copy are reviewed separately; dictionary-style content should not force awkward UI wording.

## Manual QA Scenarios

### Home Scenario

- [ ] Clean install, launch the app, and confirm Home is selected by default.
- [ ] Confirm Today's Word shows the Korean word and required learner fields.
- [ ] Force quit and reopen; confirm the same day's word remains stable.
- [ ] Enable airplane mode and relaunch; confirm Home still shows usable local content.
- [ ] Change device language to English and Japanese; confirm title and surrounding UI localize correctly.
- [ ] Test a long word and long explanation fixture if the PR changes layouts.

### Quiz Scenario

- [ ] Open Quiz from the tab bar.
- [ ] Confirm one prompt, one correct answer, and four total choices.
- [ ] Select a wrong answer and verify feedback appears in the expected language.
- [ ] Select the correct answer and verify the next state is correct.
- [ ] Disable network and repeat one quiz round.
- [ ] Simulate image API failure or empty image results; confirm the quiz remains playable.
- [ ] Rotate device or test the smallest supported screen if layout changed.

### Notification Scenario

- [ ] Open Settings and turn push notifications on.
- [ ] Allow permission and confirm the toggle remains on.
- [ ] Change notification time and confirm the schedule updates.
- [ ] Turn notifications off and confirm pending local notifications are cleared.
- [ ] Repeat with permission denied and confirm localized alert behavior.
- [ ] Trigger or simulate a notification payload and verify title/body use today's local word.
- [ ] Tap the notification and confirm the app routes to Home or Quiz as designed.

### Multilingual Scenario

- [ ] Launch with Korean locale and review Home, Quiz, Settings, alerts, and feedback.
- [ ] Launch with English locale and review the same screens for natural learner-facing copy.
- [ ] Launch with Japanese locale and review the same screens for untranslated Korean or English fragments.
- [ ] Confirm formatted values, punctuation, and line breaks are readable in all supported locales.
- [ ] Confirm fallback behavior is acceptable for unsupported locales.

## PR Code Review Checklist

- [ ] Data models are typed and validated instead of relying on ad hoc string parsing.
- [ ] Local data loading is testable without network access.
- [ ] Async work updates SwiftUI state on the main actor or main queue.
- [ ] No new force unwrap can crash from malformed local data or missing API keys.
- [ ] Loading, empty, error, and offline states are represented explicitly.
- [ ] UI strings use `LocalizationKeys` or an equivalent established localization pattern.
- [ ] Shared storage changes consider app group behavior for widgets and notifications.
- [ ] Notification changes preserve permission-denied and toggle-off flows.
- [ ] Network features remain optional enhancements for the MVP core learning path.
- [ ] New dependencies are justified and do not duplicate existing SwiftUI, Combine, or networking capabilities.
- [ ] Debug `print` output does not expose tokens, API keys, or learner content unexpectedly.
- [ ] Accessibility labels or readable text are present for new controls.
- [ ] Reviewer can verify the PR with the manual scenarios above without hidden setup.

## Severity Guide

- [ ] Block release if core Home or Quiz learning content requires network access.
- [ ] Block release if a content entry is missing required learner fields.
- [ ] Block release if answer correctness can be wrong, duplicated, or ambiguous.
- [ ] Block release if notification permission denial creates a stuck toggle or broken settings state.
- [ ] Block release if a supported locale shows raw localization keys on primary screens.
- [ ] Request changes if copy is understandable but unnatural for foreign learners.
- [ ] Request changes if layout works only for short Korean words.
- [ ] Allow follow-up only for non-core polish that does not affect learning correctness, offline behavior, or existing feature regression.
