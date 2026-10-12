import Foundation
import LearningCore

protocol LearningWordProviding {
    var words: [LearningWord] { get }
    var koreanWords: [String] { get }
    func word(id: String) -> LearningWord?
    func word(korean: String) -> LearningWord?
    func word(for date: Date, calendar: Calendar) -> LearningWord?
    func randomWord(excluding excludedIDs: Set<String>) -> LearningWord?
    func choices(for correctWord: LearningWord, count: Int) -> [LearningWord]
}

struct LearningWordRepository: LearningWordProviding {
    static let shared = LearningWordRepository()
    let words: [LearningWord]
    let loadErrorDescription: String?

    init(words: [LearningWord]? = nil) {
        if let words { self.words = words; self.loadErrorDescription = nil }
        else { self.words = LearningWordCatalog.bundled.words; self.loadErrorDescription = LearningWordCatalog.bundledLoadError.map(String.init(describing:)) }
    }

    var koreanWords: [String] { words.map(\.word) }
    var isAvailable: Bool { !words.isEmpty }
    func word(id: String) -> LearningWord? { words.first { $0.id == id } }
    func word(korean: String) -> LearningWord? { words.first { $0.word == korean } }
    func word(for date: Date = Date(), calendar: Calendar = .current) -> LearningWord? { DailyWordSelector.select(from: words, date: date, calendar: calendar) }
    func randomWord(excluding excludedIDs: Set<String> = []) -> LearningWord? { words.filter { !excludedIDs.contains($0.id) }.randomElement() }
    func choices(for correctWord: LearningWord, count: Int = 4) -> [LearningWord] {
        let candidates = words.filter { $0.id != correctWord.id && $0.level == correctWord.level && $0.partOfSpeech == correctWord.partOfSpeech }
        return Array(([correctWord] + candidates.shuffled().prefix(max(0, count - 1))).prefix(count)).shuffled()
    }
}
