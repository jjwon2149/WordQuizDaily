//
//  HomeViewModel.swift
//  WordQuizDaily
//
//  Created by 정종원 on 2/29/24.
//

import Foundation
import LearningCore
import WidgetKit

@MainActor
final class LearningStore: ObservableObject {
    @Published private(set) var progress: LearningProgress
    @Published var selectedLevel: LearningLevelSelection {
        didSet { defaults.set(selectedLevel.rawValue, forKey: Keys.level) }
    }
    @Published private(set) var persistenceError: String?

    let repository: LearningWordRepository
    private let recordStore: LearningRecordStore
    private let defaults: UserDefaults

    private enum Keys { static let level = "LearningLevelSelection" }

    init(repository: LearningWordRepository = .shared, defaults: UserDefaults = .standard, fileURL: URL? = nil) {
        self.repository = repository
        self.defaults = defaults
        let existingUser = UserDefaults.shared.string(forKey: "TodayLearningWordID") != nil || defaults.object(forKey: "hasUserAgreedNoti") != nil
        let restoredLevel = defaults.string(forKey: Keys.level).flatMap(LearningLevelSelection.init(rawValue:)) ?? (existingUser ? .all : .beginner)
        self.selectedLevel = restoredLevel
        defaults.set(restoredLevel.rawValue, forKey: Keys.level)
        let url = fileURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Learning/learning-progress.json")
        self.recordStore = LearningRecordStore(fileURL: url)
        do { self.progress = try recordStore.load() }
        catch { self.progress = LearningProgress(); self.persistenceError = LocalizationKeys.LearningProgress.loadError.localized }
    }

    var reviewCount: Int { progress.reviewWordIDs(validIDs: Set(repository.words.map(\.id)), limit: Int.max).count }
    var catalogLoadFailed: Bool { repository.loadErrorDescription != nil }
    var todayAnswerCount: Int { progress.answers(on: Date(), calendar: .current) }
    var reviewWordIDs: [String] { progress.reviewWordIDs(validIDs: Set(repository.words.map(\.id))) }

    @discardableResult
    func record(wordID: String, isCorrect: Bool, submissionID: UUID, at date: Date = Date()) -> Bool {
        var updated = progress
        guard updated.record(wordID: wordID, isCorrect: isCorrect, at: date, submissionID: submissionID) else { return false }
        do { try recordStore.save(updated); progress = updated; persistenceError = nil; return true }
        catch { persistenceError = LocalizationKeys.LearningProgress.saveError.localized; return false }
    }

    func resetProgress() {
        let empty = LearningProgress()
        do {
            try recordStore.save(empty)
            progress = empty
            persistenceError = nil
            NotificationCenter.default.post(name: Notification.Name("LearningProgressReset"), object: nil)
        }
        catch { persistenceError = LocalizationKeys.LearningProgress.saveError.localized }
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    
    @Published var toDayWord: String = ""
    @Published var toDayWordDefinition: String = ""
    @Published var todayLearningWord: LearningWord?
    @Published var wordDataDictionary = [String: WordData]()
    @Published var errorMessage: String?

    private let learningStore: LearningStore
    private var learningWordRepository: LearningWordProviding { learningStore.repository }
    private let todayWordIDKey = "TodayLearningWordID"
    private let todayWordDateKey = "TodayLearningWordDate"
        
    init(learningStore: LearningStore) {
        self.learningStore = learningStore
        fetchTodayWordOnceADay()
    }
    
    func fetchTodayWordOnceADay() {
        let now = Date()
        let calendar = Calendar.current
        let todayDate = DailyWordSelector.dayToken(for: now, calendar: calendar)

        if let storedDate = UserDefaults.shared.string(forKey: todayWordDateKey),
           storedDate == todayDate,
           let storedWordID = UserDefaults.shared.string(forKey: todayWordIDKey),
           let storedWord = learningWordRepository.word(id: storedWordID) {
            applyTodayWord(storedWord, date: now, calendar: calendar)
            return
        }

        let cache = UserDefaults.shared.string(forKey: todayWordIDKey).flatMap { id in
            UserDefaults.shared.string(forKey: todayWordDateKey).map { DailyWordCache(wordID: id, dayToken: $0) }
        }
        guard let word = DailyWordSelector.select(from: learningWordRepository.words, date: now, calendar: calendar, cache: cache) else {
            errorMessage = (learningStore.catalogLoadFailed ? LocalizationKeys.Error.catalogUnavailable : LocalizationKeys.Error.dataLoad).localized
            return
        }

        applyTodayWord(word, date: now, calendar: calendar)
    }
    
    func fetchTodayWord() async {
        await MainActor.run {
            let now = Date()
            let calendar = Calendar.current
            guard let word = learningWordRepository.word(for: now, calendar: calendar)
                    ?? learningWordRepository.randomWord(excluding: []) else {
                errorMessage = (learningStore.catalogLoadFailed ? LocalizationKeys.Error.catalogUnavailable : LocalizationKeys.Error.dataLoad).localized
                return
            }

            applyTodayWord(word, date: now, calendar: calendar)
        }
    }
    
    
    //MARK: - KoreanWordSearchAPI
    
    // 단어 데이터 처리 메서드
    func handleWordData(word: String, wordData: WordData?) {
        if let wordData = wordData {
            wordDataDictionary[word] = wordData
            // 정답 단어의 설명을 가져오기
            if word == toDayWord {
                fetchCorrectWordDefinition()
            }
        } else {
            errorMessage = LocalizationKeys.Error.dataLoad.localized
        }
        
    }

    private func applyTodayWord(_ word: LearningWord, date: Date, calendar: Calendar) {
        todayLearningWord = word
        toDayWord = word.korean
        toDayWordDefinition = word.displayDefinition
        wordDataDictionary[word.korean] = WordData(learningWord: word)

        UserDefaults.shared.set(word.id, forKey: todayWordIDKey)
        UserDefaults.shared.set(DailyWordSelector.dayToken(for: date, calendar: calendar), forKey: todayWordDateKey)
        UserDefaults.shared.set(toDayWord, forKey: "TodayWord")
        UserDefaults.shared.set(toDayWordDefinition, forKey: "TodayWordDefinition")
        UserDefaults.shared.set(word.easyKoreanDefinition, forKey: "TodayWordEasyKorean")
        UserDefaults.shared.set(word.englishMeaning, forKey: "TodayWordEnglishMeaning")
        UserDefaults.shared.set(word.romanization, forKey: "TodayWordRomanization")
        UserDefaults.shared.set(word.difficulty, forKey: "TodayWordDifficulty")
        UserDefaults.shared.set(word.partOfSpeech.rawValue, forKey: "TodayWordPartOfSpeech")
        UserDefaults.shared.set(word.example, forKey: "TodayWordExample")
        UserDefaults.shared.set(word.exampleTranslation, forKey: "TodayWordExampleTranslation")
        WidgetCenter.shared.reloadTimelines(ofKind: "WordQuizWidget")
    }
    
    // 오늘의 단어의 설명 가져오기
    func fetchCorrectWordDefinition() {
        
        guard let wordData = wordDataDictionary[toDayWord] else {
            toDayWordDefinition = "설명을 가져올 수 없습니다."
            return
        }
        
        if let definition = wordData.firstDefinition {
            toDayWordDefinition = definition
            
            UserDefaults.shared.set(toDayWord, forKey: "TodayWord")
            UserDefaults.shared.set(toDayWordDefinition, forKey: "TodayWordDefinition")
            UserDefaults.shared.set(toDayWordDefinition, forKey: "TodayWordEasyKorean")
        } else {
            toDayWordDefinition = "설명을 찾을 수 없습니다."
            
        }
        
    }
    //MARK: - Error Handling
    func handleNetworkError(_ error: Error) {
        errorMessage = error.localizedDescription
    }

}
