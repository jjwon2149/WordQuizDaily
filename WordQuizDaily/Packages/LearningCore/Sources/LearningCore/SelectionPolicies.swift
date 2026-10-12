import Foundation

public struct DailyWordCache: Equatable, Sendable {
    public let wordID: String
    public let dayToken: String
    public init(wordID: String, dayToken: String) { self.wordID = wordID; self.dayToken = dayToken }
}

public enum DailyWordSelector {
    public static func dayToken(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.era, .year, .month, .day], from: date)
        return "\(components.era ?? 1)-\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    public static func legacyDayToken(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    public static func select(from words: [LearningWord], date: Date, calendar: Calendar, cache: DailyWordCache? = nil) -> LearningWord? {
        guard !words.isEmpty else { return nil }
        let acceptedTokens = [dayToken(for: date, calendar: calendar), legacyDayToken(for: date, calendar: calendar)]
        if let cache, acceptedTokens.contains(cache.dayToken), let cached = words.first(where: { $0.id == cache.wordID }) {
            return cached
        }
        let components = calendar.dateComponents([.era, .year, .month, .day], from: date)
        let ordinal = (components.era ?? 1) * 10_000_000
            + (components.year ?? 0) * 10_000
            + (components.month ?? 0) * 100
            + (components.day ?? 0)
        return words[((ordinal % words.count) + words.count) % words.count]
    }
}

public enum QuizSelectionError: Error, Equatable {
    case noEligibleWord
    case insufficientChoices
}

public struct QuizQuestion: Equatable, Sendable {
    public let answer: LearningWord
    public let choices: [LearningWord]
    public init(answer: LearningWord, choices: [LearningWord]) { self.answer = answer; self.choices = choices }
}

public enum QuizSelector {
    public static func question(words: [LearningWord], selection: LearningLevelSelection, recentIDs: [String], randomIndex: (Int) -> Int = { Int.random(in: 0..<$0) }) throws -> QuizQuestion {
        let levelWords = words.filter { selection.level == nil || $0.level == selection.level }
        guard !levelWords.isEmpty else { throw QuizSelectionError.noEligibleWord }

        let answerPool = eligibleAnswerPool(words: levelWords, recentIDs: recentIDs)
        guard !answerPool.isEmpty else { throw QuizSelectionError.noEligibleWord }

        let eligibleAnswers = answerPool.filter { answer in
            !distractorTriples(for: answer, words: words).isEmpty
        }
        guard !eligibleAnswers.isEmpty else { throw QuizSelectionError.insufficientChoices }
        let answer = eligibleAnswers[bounded(randomIndex(eligibleAnswers.count), count: eligibleAnswers.count)]
        return try question(for: answer, words: words, randomIndex: randomIndex)
    }

    public static func question(for answer: LearningWord, words: [LearningWord], randomIndex: (Int) -> Int = { Int.random(in: 0..<$0) }) throws -> QuizQuestion {
        let triples = distractorTriples(for: answer, words: words)
        guard !triples.isEmpty else { throw QuizSelectionError.insufficientChoices }
        let picked = triples[bounded(randomIndex(triples.count), count: triples.count)]
        var result = [answer] + picked
        if result.count > 1 {
            result.swapAt(0, bounded(randomIndex(result.count), count: result.count))
        }
        return QuizQuestion(answer: answer, choices: result)
    }

    private static func distractorTriples(for answer: LearningWord, words: [LearningWord]) -> [[LearningWord]] {
        let sameGroup = words.filter {
            $0.id != answer.id && $0.level == answer.level && $0.partOfSpeech == answer.partOfSpeech
        }
        return LearningWordCatalog.compatibleDistractorTriples(for: answer, candidates: sameGroup)
    }

    static func eligibleAnswerPool(words: [LearningWord], recentIDs: [String]) -> [LearningWord] {
        var excluded = Array(recentIDs.suffix(3))
        var answerPool = words.filter { !excluded.contains($0.id) }
        while answerPool.isEmpty, !excluded.isEmpty {
            excluded.removeFirst()
            answerPool = words.filter { !excluded.contains($0.id) }
        }
        return answerPool
    }

    private static func bounded(_ value: Int, count: Int) -> Int {
        min(max(value, 0), count - 1)
    }
}

public struct RequestIdentityGate: Sendable {
    public private(set) var currentID: UUID?
    public init() {}
    @discardableResult public mutating func begin() -> UUID { let id = UUID(); currentID = id; return id }
    public func accepts(_ id: UUID) -> Bool { currentID == id }
}

public enum NotificationSchedulePolicy {
    public static let requestIdentifier = "dailyLearningReminder.v2"
    public static func shouldSchedule(toggleOn: Bool, authorized: Bool) -> Bool { toggleOn && authorized }
}
