//
//  LocalizationHelper.swift
//  WordQuizDaily
//
//  Created on 2025-07-18.
//  로컬라이제이션을 위한 헬퍼 클래스
//

import Foundation
import SwiftUI

// MARK: - 로컬라이제이션 헬퍼
struct LocalizationHelper {
    
    /// 현재 설정된 언어 코드 반환
    static var currentLanguage: String {
        if #available(iOS 16, *) {
            return Locale.current.language.languageCode?.identifier ?? "ko"
        } else {
            return Locale.current.languageCode ?? "ko"
        }
    }
    
    /// 앱에서 지원하는 언어 목록
    static let supportedLanguages = ["ko", "en", "ja"]
    
    /// 언어 이름 매핑
    static let languageNames: [String: String] = [
        "ko": "한국어",
        "en": "English",
        "ja": "日本語"
    ]

    /// 지원 언어 코드로 정규화
    /// - Parameter language: 언어 코드 (예: "ko", "en-US", "ja")
    /// - Returns: 앱에서 지원하는 언어 코드
    static func normalizedLanguageCode(_ language: String?) -> String {
        guard let languageCode = language?.split(separator: "-").first.map(String.init),
              supportedLanguages.contains(languageCode) else {
            return "ko"
        }

        return languageCode
    }
    
    /// 특정 키에 대한 로컬라이즈된 문자열 반환
    /// - Parameters:
    ///   - key: 로컬라이제이션 키
    ///   - arguments: 문자열 포맷 인수
    /// - Returns: 로컬라이즈된 문자열
    static func localizedString(for key: String, arguments: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, arguments: arguments)
    }

    /// 특정 언어 리소스에서 로컬라이즈된 문자열 반환
    /// - Parameters:
    ///   - key: 로컬라이제이션 키
    ///   - language: 언어 코드
    ///   - arguments: 문자열 포맷 인수
    /// - Returns: 로컬라이즈된 문자열
    static func localizedString(for key: String, language: String, arguments: CVarArg...) -> String {
        let normalizedLanguage = normalizedLanguageCode(language)
        let bundlePath = Bundle.main.path(forResource: normalizedLanguage, ofType: "lproj")
        let bundle = bundlePath.flatMap(Bundle.init(path:)) ?? .main
        let format = NSLocalizedString(key, bundle: bundle, comment: "")

        return String(format: format, locale: Locale(identifier: normalizedLanguage), arguments: arguments)
    }
}

// MARK: - String Extension for Localization
extension String {
    
    /// 로컬라이제이션된 문자열 반환
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// 매개변수와 함께 로컬라이제이션된 문자열 반환
    /// - Parameter arguments: 포맷 인수
    /// - Returns: 로컬라이즈된 문자열
    func localized(with arguments: CVarArg...) -> String {
        let format = NSLocalizedString(self, comment: "")
        return String(format: format, arguments: arguments)
    }
}

// MARK: - LocalizedStringKey Extensions
extension LocalizedStringKey {
    
    /// String으로부터 LocalizedStringKey 생성
    /// - Parameter key: 로컬라이제이션 키
    init(_ key: String) {
        self.init(stringLiteral: key)
    }
}

// MARK: - SwiftUI Preview를 위한 로케일 설정
extension View {
    
    /// SwiftUI 프리뷰에서 특정 언어로 표시
    /// - Parameter language: 언어 코드 (예: "ko", "en", "ja")
    /// - Returns: 언어가 설정된 뷰
    func previewLocale(_ language: String) -> some View {
        self.environment(\.locale, Locale(identifier: language))
    }
}

// MARK: - 로컬라이제이션 키 열거형
enum LocalizationKeys {
    
    // MARK: Common
    enum Common {
        static let ok = "common.ok"
        static let cancel = "common.cancel"
        static let save = "common.save"
        static let delete = "common.delete"
        static let edit = "common.edit"
        static let done = "common.done"
        static let loading = "common.loading"
        static let error = "common.error"
        static let retry = "common.retry"
        static let close = "common.close"
    }
    
    // MARK: Tab Bar
    enum Tab {
        static let home = "tab.home"
        static let quiz = "tab.quiz"
        static let settings = "tab.settings"
    }
    
    // MARK: Home Screen
    enum Home {
        static let title = "home.title"
        static let subtitle = "home.subtitle"
        static let todayWord = "home.todayWord"
        static let startQuiz = "home.startQuiz"
        static let studyCount = "home.studyCount"
        static let streakCount = "home.streakCount"
    }

    // MARK: Today's Word
    enum TodayWord {
        static let cardTitle = "todayWord.card.title"
        static let detailTitle = "todayWord.detail.title"
        static let meaningTitle = "todayWord.meaning.title"
        static let easyKoreanTitle = "todayWord.easyKorean.title"
        static let romanizationTitle = "todayWord.romanization.title"
        static let exampleTitle = "todayWord.example.title"
        static let difficultyTitle = "todayWord.difficulty.title"
        static let emptyMessage = "todayWord.empty.message"
    }
    
    // MARK: Quiz Screen
    enum Quiz {
        static let title = "quiz.title"
        static let question = "quiz.question"
        static let nextButton = "quiz.nextButton"
        static let submitButton = "quiz.submitButton"
        static let finishButton = "quiz.finishButton"
        static let correct = "quiz.correct"
        static let incorrect = "quiz.incorrect"
        static let correctAnswer = "quiz.correctAnswer"
        static let score = "quiz.score"
        static let completion = "quiz.completion"
        static let totalScore = "quiz.totalScore"
        static let restartButton = "quiz.restartButton"
        static let homeButton = "quiz.homeButton"
        static let loadingImages = "quiz.loadingImages"
        static let imageUnavailable = "quiz.imageUnavailable"
        static let selectedWord = "quiz.selectedWord"
        static let isCorrect = "quiz.isCorrect"
        static let chooseWordPrompt = "quiz.prompt.chooseWord"
        static let chooseMeaningPrompt = "quiz.prompt.chooseMeaning"
        static let feedbackTitle = "quiz.feedback.title"
        static let feedbackCorrectTitle = "quiz.feedback.correctTitle"
        static let feedbackCorrectMessage = "quiz.feedback.correctMessage"
        static let feedbackIncorrectTitle = "quiz.feedback.incorrectTitle"
        static let feedbackIncorrectMessage = "quiz.feedback.incorrectMessage"
        static let feedbackTryAgain = "quiz.feedback.tryAgain"
        static let feedbackReviewMeaning = "quiz.feedback.reviewMeaning"
        static let resultTitle = "quiz.result.title"
        static let resultSummary = "quiz.result.summary"
        static let resultPerfect = "quiz.result.perfect"
        static let resultKeepPracticing = "quiz.result.keepPracticing"
    }
    
    // MARK: Settings Screen
    enum Settings {
        static let title = "settings.title"
        static let notification = "settings.notification"
        static let language = "settings.language"
        static let theme = "settings.theme"
        static let about = "settings.about"
        static let version = "settings.version"
        static let contact = "settings.contact"
        static let privacy = "settings.privacy"
        static let terms = "settings.terms"
        static let notificationSection = "settings.notificationSection"
        static let otherSection = "settings.otherSection"
        static let termsOfService = "settings.termsOfService"
        static let appVersion = "settings.appVersion"
        static let customerService = "settings.customerService"
        static let feedback = "settings.feedback"
        static let pushNotification = "settings.pushNotification"
    }
    
    // MARK: Notification Settings
    enum Notification {
        static let title = "notification.title"
        static let daily = "notification.daily"
        static let time = "notification.time"
        static let sound = "notification.sound"
        static let permissionTitle = "notification.permission.title"
        static let permissionMessage = "notification.permission.message"
        static let permissionSettings = "notification.permission.settings"
        static let alertTitle = "notification.alert.title"
        static let alertMessage = "notification.alert.message"
        static let alertGoToSettings = "notification.alert.goToSettings"
        static let wordOfDayTitle = "notification.wordOfDay.title"
        static let wordOfDayBodyMeaning = "notification.wordOfDay.bodyMeaning"
        static let wordOfDayBodyEasyKorean = "notification.wordOfDay.bodyEasyKorean"
        static let wordOfDayBodyDefinition = "notification.wordOfDay.bodyDefinition"
        static let wordOfDayBodyFallback = "notification.wordOfDay.bodyFallback"
        static let wordOfDayFallbackWord = "notification.wordOfDay.fallbackWord"
    }
    
    // MARK: Error Messages
    enum Error {
        static let network = "error.network"
        static let unknown = "error.unknown"
        static let dataLoad = "error.dataLoad"
        static let permission = "error.permission"
    }
    
    // MARK: Success Messages
    enum Success {
        static let save = "success.save"
        static let update = "success.update"
        static let delete = "success.delete"
    }
    
    // MARK: Word Related
    enum Word {
        static let meaning = "word.meaning"
        static let pronunciation = "word.pronunciation"
        static let example = "word.example"
        static let difficulty = "word.difficulty"
        static let category = "word.category"
        static let bookmark = "word.bookmark"
        static let learned = "word.learned"
        static let learning = "word.learning"
        static let notStarted = "word.notStarted"
        static let easyKorean = "word.easyKorean"
        static let romanization = "word.romanization"
        static let englishMeaning = "word.englishMeaning"
        static let partOfSpeech = "word.partOfSpeech"
        static let exampleKorean = "word.exampleKorean"
        static let exampleTranslation = "word.exampleTranslation"
        static let feedback = "word.feedback"
        static let answer = "word.answer"
        static let hint = "word.hint"
        static let detail = "word.detail"
        static let sourceDictionary = "word.sourceDictionary"
        static let difficultyEasy = "word.difficulty.easy"
        static let difficultyMedium = "word.difficulty.medium"
        static let difficultyHard = "word.difficulty.hard"
    }
    
    // MARK: Terms of Service
    enum TermsOfService {
        static let title = "terms.title"
        static let content = "terms.content"
    }
    
    // MARK: App Version
    enum AppVersion {
        static let title = "appVersion.title"
        static let currentVersion = "appVersion.current"
        static let updateHistory = "appVersion.updateHistory"
        static let version100 = "appVersion.version100"
    }
    
    // MARK: Customer Service
    enum CustomerService {
        static let title = "customerService.title"
        static let contactInfo = "customerService.contactInfo"
        static let faq = "customerService.faq"
        static let faqPassword = "customerService.faqPassword"
        static let faqPasswordAnswer = "customerService.faqPasswordAnswer"
        static let faqNotWorking = "customerService.faqNotWorking"
        static let faqNotWorkingAnswer = "customerService.faqNotWorkingAnswer"
    }
    
    // MARK: Feedback
    enum Feedback {
        static let title = "feedback.title"
        static let content = "feedback.content"
        static let contactInfo = "feedback.contactInfo"
    }
}
