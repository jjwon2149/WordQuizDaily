//
//  HomeViewModel.swift
//  WordQuizDaily
//
//  Created by 정종원 on 2/29/24.
//

import Foundation

extension UserDefaults {
    static var shared: UserDefaults {
        let appGroupId = "group.wordQuizWidget"
        return UserDefaults(suiteName: appGroupId)!
    }
}

class HomeViewModel: ObservableObject {
    
    let hardKoreanWords = HardKoreanWords()
    let wordNetwork = WordNetwork()
    
    @Published var toDayWord: String = ""
    @Published var toDayWordDefinition: String = ""
    @Published var wordDataDictionary = [String: WordData]()
    @Published var errorMessage: String?

    private let updateInterval: TimeInterval = 24 * 60 * 60 // 24시간
        
    init() {
        fetchTodayWordOnceADay()
    }
    
    func fetchTodayWordOnceADay() {
        
        if let storedWord = UserDefaults.shared.string(forKey: "TodayWord"),
           let storedDefinition = UserDefaults.shared.string(forKey: "TodayWordDefinition") {
            toDayWord = storedWord
            toDayWordDefinition = storedDefinition
        } else {
            Task {
                await fetchTodayWord()
            }
        }
    }
    
    func fetchTodayWord() async {
        toDayWord = hardKoreanWords.hardWords.randomElement() ?? ""
        do {
            let wordData = try await wordNetwork.searchWord(toDayWord)
            handleWordData(word: self.toDayWord, wordData: wordData)
        } catch {
            handleNetworkError(error)
        }
//        wordNetwork.searchWord(toDayWord) { wordData in
//            self.handleWordData(word: self.toDayWord, wordData: wordData)
//        }
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
    
    // 오늘의 단어의 설명 가져오기
    func fetchCorrectWordDefinition() {
        
        guard let wordData = wordDataDictionary[toDayWord] else {
            toDayWordDefinition = "설명을 가져올 수 없습니다."
            return
        }
        
        if let firstSense = wordData.channel.item.first?.sense.first {
            toDayWordDefinition = firstSense.definition
            
            UserDefaults.shared.set(toDayWord, forKey: "TodayWord")
            UserDefaults.shared.set(toDayWordDefinition, forKey: "TodayWordDefinition")
        } else {
            toDayWordDefinition = "설명을 찾을 수 없습니다."
            
        }
        
    }
    //MARK: - Error Handling
    func handleNetworkError(_ error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
    }
}
