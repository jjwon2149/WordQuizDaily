//
//  HomeViewModel.swift
//  WordQuizDaily
//
//  Created by 정종원 on 2/29/24.
//

import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    
    @Published var toDayWord: String = ""
    @Published var toDayWordDefinition: String = ""
    @Published var todayLearningWord: LearningWord?
    @Published var wordDataDictionary = [String: WordData]()
    @Published var errorMessage: String?

    private let learningWordRepository: LearningWordProviding
    private let todayWordIDKey = "TodayLearningWordID"
    private let todayWordDateKey = "TodayLearningWordDate"
        
    init(learningWordRepository: LearningWordProviding = LearningWordRepository.shared) {
        self.learningWordRepository = learningWordRepository
        fetchTodayWordOnceADay()
    }
    
    func fetchTodayWordOnceADay() {
        let todayDate = Self.todayDateToken()

        if let storedDate = UserDefaults.shared.string(forKey: todayWordDateKey),
           storedDate == todayDate,
           let storedWordID = UserDefaults.shared.string(forKey: todayWordIDKey),
           let storedWord = learningWordRepository.word(id: storedWordID) {
            applyTodayWord(storedWord)
            return
        }

        guard let word = learningWordRepository.word(for: Date(), calendar: .current)
                ?? learningWordRepository.randomWord(excluding: []) else {
            errorMessage = "로컬 학습 단어를 찾을 수 없습니다."
            return
        }

        applyTodayWord(word)
    }
    
    func fetchTodayWord() async {
        await MainActor.run {
            guard let word = learningWordRepository.word(for: Date(), calendar: .current)
                    ?? learningWordRepository.randomWord(excluding: []) else {
                errorMessage = "로컬 학습 단어를 찾을 수 없습니다."
                return
            }

            applyTodayWord(word)
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
            print("\(word) 단어 데이터를 가져오지 못함 ")
        }
        
    }

    private func applyTodayWord(_ word: LearningWord) {
        todayLearningWord = word
        toDayWord = word.korean
        toDayWordDefinition = word.displayDefinition
        wordDataDictionary[word.korean] = WordData(learningWord: word)

        UserDefaults.shared.set(word.id, forKey: todayWordIDKey)
        UserDefaults.shared.set(Self.todayDateToken(), forKey: todayWordDateKey)
        UserDefaults.shared.set(toDayWord, forKey: "TodayWord")
        UserDefaults.shared.set(toDayWordDefinition, forKey: "TodayWordDefinition")
        UserDefaults.shared.set(word.easyKoreanDefinition, forKey: "TodayWordEasyKorean")
        UserDefaults.shared.set(word.englishMeaning, forKey: "TodayWordEnglishMeaning")
        UserDefaults.shared.set(word.romanization, forKey: "TodayWordRomanization")
        UserDefaults.shared.set(word.difficulty, forKey: "TodayWordDifficulty")
        UserDefaults.shared.set(word.partOfSpeech, forKey: "TodayWordPartOfSpeech")
        UserDefaults.shared.set(word.example, forKey: "TodayWordExample")
        UserDefaults.shared.set(word.exampleTranslation, forKey: "TodayWordExampleTranslation")
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

    private static func todayDateToken(date: Date = Date(), calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}
