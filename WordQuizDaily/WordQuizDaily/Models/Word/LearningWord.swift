//
//  LearningWord.swift
//  WordQuizDaily
//

import Foundation

enum LearningWordDifficulty: String, Codable, CaseIterable, Comparable, Hashable {
    case beginner
    case intermediate
    case advanced

    private var sortOrder: Int {
        switch self {
        case .beginner:
            return 0
        case .intermediate:
            return 1
        case .advanced:
            return 2
        }
    }

    static func < (lhs: LearningWordDifficulty, rhs: LearningWordDifficulty) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    var displayName: String {
        rawValue.capitalized
    }
}

struct LearningWord: Identifiable, Codable, Hashable {
    let id: String
    let word: String
    let englishMeaning: String
    let easyKoreanDefinition: String
    let romanization: String
    let partOfSpeech: String
    let difficulty: String
    let example: String
    let exampleTranslation: String
    let incorrectFeedback: String

    init(
        id: String? = nil,
        korean: String,
        englishMeaning: String,
        simpleKoreanDefinition: String,
        romanization: String,
        partOfSpeech: String,
        difficulty: LearningWordDifficulty,
        exampleSentence: String,
        exampleTranslation: String,
        incorrectFeedback: String
    ) {
        self.id = id ?? korean
        self.word = korean
        self.englishMeaning = englishMeaning
        self.easyKoreanDefinition = simpleKoreanDefinition
        self.romanization = romanization
        self.partOfSpeech = partOfSpeech
        self.difficulty = difficulty.displayName
        self.example = exampleSentence
        self.exampleTranslation = exampleTranslation
        self.incorrectFeedback = incorrectFeedback
    }

    init(
        word: String,
        englishMeaning: String,
        easyKoreanDefinition: String,
        romanization: String,
        partOfSpeech: String,
        difficulty: String,
        example: String,
        exampleTranslation: String,
        incorrectFeedback: String
    ) {
        self.id = word
        self.word = word
        self.englishMeaning = englishMeaning
        self.easyKoreanDefinition = easyKoreanDefinition
        self.romanization = romanization
        self.partOfSpeech = partOfSpeech
        self.difficulty = difficulty
        self.example = example
        self.exampleTranslation = exampleTranslation
        self.incorrectFeedback = incorrectFeedback
    }

    var korean: String {
        word
    }

    var simpleKoreanDefinition: String {
        easyKoreanDefinition
    }

    var easyKoreanDescription: String {
        easyKoreanDefinition
    }

    var exampleSentence: String {
        example
    }

    var displayDefinition: String {
        easyKoreanDefinition
    }

    var requiredTextFields: [(name: String, value: String)] {
        [
            ("id", id),
            ("korean", word),
            ("englishMeaning", englishMeaning),
            ("easyKoreanDefinition", easyKoreanDefinition),
            ("romanization", romanization),
            ("partOfSpeech", partOfSpeech),
            ("difficulty", difficulty),
            ("example", example),
            ("exampleTranslation", exampleTranslation),
            ("incorrectFeedback", incorrectFeedback)
        ]
    }
}
