import Foundation

public enum LearningLevel: String, Codable, CaseIterable, Sendable {
    case beginner, intermediate, advanced

    public init?(legacyValue: String) {
        switch legacyValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "beginner", "easy": self = .beginner
        case "intermediate", "medium": self = .intermediate
        case "advanced", "hard": self = .advanced
        default: return nil
        }
    }
}

public enum LearningLevelSelection: String, Codable, CaseIterable, Sendable {
    case all, beginner, intermediate, advanced
    public var level: LearningLevel? { LearningLevel(rawValue: rawValue) }
}

public enum PartOfSpeech: String, Codable, CaseIterable, Sendable {
    case noun, verb, adjective
}

public struct LearningWord: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let word: String
    public let englishMeaning: String
    public let easyKoreanDefinition: String
    public let romanization: String
    public let partOfSpeech: PartOfSpeech
    public let level: LearningLevel
    public let example: String
    public let exampleTranslation: String
    public let incorrectFeedback: String
    public let conflictGroupIDs: [String]

    public init(id: String, word: String, englishMeaning: String, easyKoreanDefinition: String, romanization: String, partOfSpeech: PartOfSpeech, level: LearningLevel, example: String, exampleTranslation: String, incorrectFeedback: String, conflictGroupIDs: [String] = []) {
        self.id = id
        self.word = word
        self.englishMeaning = englishMeaning
        self.easyKoreanDefinition = easyKoreanDefinition
        self.romanization = romanization
        self.partOfSpeech = partOfSpeech
        self.level = level
        self.example = example
        self.exampleTranslation = exampleTranslation
        self.incorrectFeedback = incorrectFeedback
        self.conflictGroupIDs = conflictGroupIDs
    }

    private enum CodingKeys: String, CodingKey {
        case id, word, englishMeaning, easyKoreanDefinition, romanization, partOfSpeech, level
        case example, exampleTranslation, incorrectFeedback, conflictGroupIDs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        word = try container.decode(String.self, forKey: .word)
        englishMeaning = try container.decode(String.self, forKey: .englishMeaning)
        easyKoreanDefinition = try container.decode(String.self, forKey: .easyKoreanDefinition)
        romanization = try container.decode(String.self, forKey: .romanization)
        partOfSpeech = try container.decode(PartOfSpeech.self, forKey: .partOfSpeech)
        level = try container.decode(LearningLevel.self, forKey: .level)
        example = try container.decode(String.self, forKey: .example)
        exampleTranslation = try container.decode(String.self, forKey: .exampleTranslation)
        incorrectFeedback = try container.decode(String.self, forKey: .incorrectFeedback)
        conflictGroupIDs = try container.decodeIfPresent([String].self, forKey: .conflictGroupIDs) ?? []
    }

    public var difficulty: String { level.rawValue.capitalized }
    public var displayDefinition: String { easyKoreanDefinition }
}

public enum CatalogValidationError: Error, Equatable, CustomStringConvertible, Sendable {
    case emptyCatalog
    case duplicateID(String)
    case duplicateWord(String)
    case missingField(id: String)
    case insufficientLevel(LearningLevel, actual: Int)
    case insufficientGroup(LearningLevel, PartOfSpeech, actual: Int)
    case insufficientValidChoices(id: String, actual: Int)
    case ambiguousMeaning(id: String, otherID: String)

    public var description: String {
        switch self {
        case .emptyCatalog: return "The learning catalog is empty."
        case .duplicateID(let id): return "Duplicate word id: \(id)"
        case .duplicateWord(let word): return "Duplicate Korean word: \(word)"
        case .missingField(let id): return "Required content is missing for \(id)."
        case .insufficientLevel(let level, let count): return "\(level.rawValue) has \(count) words; 20 required."
        case .insufficientGroup(let level, let part, let count): return "\(level.rawValue)/\(part.rawValue) has \(count) words; 4 required."
        case .insufficientValidChoices(let id, let count): return "\(id) can form only \(count) non-conflicting distractors; 3 required."
        case .ambiguousMeaning(let id, let other): return "\(id) and \(other) have the same normalized meaning."
        }
    }
}

public enum CatalogLoadError: Error, Equatable, CustomStringConvertible, Sendable {
    case missingResource
    case unreadableResource(String)
    case invalidJSON(String)
    case invalidContent([CatalogValidationError])

    public var description: String {
        switch self {
        case .missingResource: return "The bundled learning catalog is missing."
        case .unreadableResource(let reason): return "The bundled learning catalog cannot be read: \(reason)"
        case .invalidJSON(let reason): return "The bundled learning catalog is malformed: \(reason)"
        case .invalidContent(let errors): return errors.map(\.description).joined(separator: "\n")
        }
    }
}

public struct LearningWordCatalog: Sendable {
    public let words: [LearningWord]

    public init(words: [LearningWord], enforceReleaseMinimums: Bool = true) throws {
        let errors = Self.validate(words, enforceReleaseMinimums: enforceReleaseMinimums)
        if let first = errors.first { throw first }
        self.words = words
    }

    private init(uncheckedWords: [LearningWord]) { words = uncheckedWords }

    public static let bundledResult: Result<LearningWordCatalog, CatalogLoadError> = {
        guard let url = Bundle.module.url(forResource: "learning_words", withExtension: "json") else {
            return .failure(.missingResource)
        }
        let data: Data
        do { data = try Data(contentsOf: url) }
        catch { return .failure(.unreadableResource(error.localizedDescription)) }
        return decode(data: data)
    }()

    public static let bundled: LearningWordCatalog = {
        switch bundledResult {
        case .success(let catalog): return catalog
        case .failure: return LearningWordCatalog(uncheckedWords: [])
        }
    }()

    public static var bundledLoadError: CatalogLoadError? {
        guard case .failure(let error) = bundledResult else { return nil }
        return error
    }

    public static func decode(data: Data, enforceReleaseMinimums: Bool = true) -> Result<LearningWordCatalog, CatalogLoadError> {
        let decoded: [LearningWord]
        do { decoded = try JSONDecoder().decode([LearningWord].self, from: data) }
        catch { return .failure(.invalidJSON(error.localizedDescription)) }
        let errors = validate(decoded, enforceReleaseMinimums: enforceReleaseMinimums)
        guard errors.isEmpty else { return .failure(.invalidContent(errors)) }
        return .success(LearningWordCatalog(uncheckedWords: decoded))
    }

    public func word(id: String) -> LearningWord? { words.first { $0.id == id } }

    public static func validate(_ words: [LearningWord], enforceReleaseMinimums: Bool = true) -> [CatalogValidationError] {
        guard !words.isEmpty else { return [.emptyCatalog] }
        var errors: [CatalogValidationError] = []
        var ids = Set<String>(), korean = Set<String>()
        for item in words {
            if !ids.insert(item.id).inserted { errors.append(.duplicateID(item.id)) }
            if !korean.insert(item.word).inserted { errors.append(.duplicateWord(item.word)) }
            let fields = [item.id, item.word, item.englishMeaning, item.easyKoreanDefinition, item.romanization, item.example, item.exampleTranslation, item.incorrectFeedback]
            if fields.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                errors.append(.missingField(id: item.id))
            }
        }
        if enforceReleaseMinimums {
            for level in LearningLevel.allCases {
                let levelCount = words.filter { $0.level == level }.count
                if levelCount < 20 { errors.append(.insufficientLevel(level, actual: levelCount)) }
                for part in PartOfSpeech.allCases {
                    let count = words.filter { $0.level == level && $0.partOfSpeech == part }.count
                    if count < 4 { errors.append(.insufficientGroup(level, part, actual: count)) }
                }
            }
            for answer in words {
                let group = words.filter { $0.id != answer.id && $0.level == answer.level && $0.partOfSpeech == answer.partOfSpeech }
                let maximum = maximumCompatibleDistractorCount(for: answer, candidates: group)
                if maximum < 3 { errors.append(.insufficientValidChoices(id: answer.id, actual: maximum)) }
            }
        }
        return errors
    }

    public static func normalizedMeaning(_ value: String) -> String {
        meaningSegments(value).sorted().first ?? value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func meaningSegments(_ value: String) -> Set<String> {
        Set(value.lowercased().split(whereSeparator: { ";,/".contains($0) }).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty })
    }

    public static func conflicts(_ lhs: LearningWord, _ rhs: LearningWord) -> Bool {
        if !meaningSegments(lhs.englishMeaning).isDisjoint(with: meaningSegments(rhs.englishMeaning)) { return true }
        let lhsGroups = Set(lhs.conflictGroupIDs.map(normalizeConflictGroup).filter { !$0.isEmpty })
        let rhsGroups = Set(rhs.conflictGroupIDs.map(normalizeConflictGroup).filter { !$0.isEmpty })
        return !lhsGroups.isDisjoint(with: rhsGroups)
    }

    static func compatibleDistractorTriples(for answer: LearningWord, candidates: [LearningWord]) -> [[LearningWord]] {
        let eligible = candidates.filter { !conflicts(answer, $0) }
        guard eligible.count >= 3 else { return [] }
        var results: [[LearningWord]] = []
        for first in 0..<(eligible.count - 2) {
            for second in (first + 1)..<(eligible.count - 1) where !conflicts(eligible[first], eligible[second]) {
                for third in (second + 1)..<eligible.count where !conflicts(eligible[first], eligible[third]) && !conflicts(eligible[second], eligible[third]) {
                    results.append([eligible[first], eligible[second], eligible[third]])
                }
            }
        }
        return results
    }

    private static func maximumCompatibleDistractorCount(for answer: LearningWord, candidates: [LearningWord]) -> Int {
        let eligible = candidates.filter { !conflicts(answer, $0) }
        guard !eligible.isEmpty else { return 0 }
        if !compatibleDistractorTriples(for: answer, candidates: eligible).isEmpty { return 3 }
        for first in eligible.indices {
            for second in eligible.indices where first < second && !conflicts(eligible[first], eligible[second]) { return 2 }
        }
        return 1
    }

    private static func normalizeConflictGroup(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
