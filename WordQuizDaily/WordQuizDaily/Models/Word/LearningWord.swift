import Foundation
import LearningCore

typealias LearningWord = LearningCore.LearningWord
typealias LearningWordDifficulty = LearningCore.LearningLevel
typealias LearningWordPartOfSpeech = LearningCore.PartOfSpeech

extension LearningWord {
    var korean: String { word }
    var simpleKoreanDefinition: String { easyKoreanDefinition }
    var easyKoreanDescription: String { easyKoreanDefinition }
    var exampleSentence: String { example }

    func meaning(for languageCode: String = LocalizationHelper.currentLanguage) -> String {
        LocalizationHelper.normalizedLanguageCode(languageCode) == "en" ? englishMeaning : easyKoreanDefinition
    }

    func exampleTranslation(for languageCode: String = LocalizationHelper.currentLanguage) -> String? {
        LocalizationHelper.normalizedLanguageCode(languageCode) == "en" ? exampleTranslation : nil
    }

    func feedbackDescription(for languageCode: String = LocalizationHelper.currentLanguage) -> String { meaning(for: languageCode) }

    func localizedDifficulty(for languageCode: String = LocalizationHelper.currentLanguage) -> String {
        let key: String
        switch level {
        case .beginner: key = LocalizationKeys.Word.difficultyEasy
        case .intermediate: key = LocalizationKeys.Word.difficultyMedium
        case .advanced: key = LocalizationKeys.Word.difficultyHard
        }
        return LocalizationHelper.localizedString(for: key, language: languageCode)
    }

    func localizedPartOfSpeech(for languageCode: String = LocalizationHelper.currentLanguage) -> String {
        let key: String
        switch partOfSpeech {
        case .noun: key = LocalizationKeys.Word.partOfSpeechNoun
        case .verb: key = LocalizationKeys.Word.partOfSpeechVerb
        case .adjective: key = LocalizationKeys.Word.partOfSpeechAdjective
        }
        return LocalizationHelper.localizedString(for: key, language: languageCode)
    }
}
