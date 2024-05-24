//
//  QuizViewModel.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/27/24.
//

import Foundation
import Kingfisher

class QuizViewModel: ObservableObject, NaverNetworkDelegate {
    
    let hardKoreanWords = HardKoreanWords()
    let wordNetwork = WordNetwork()
    
    @Published var choiceWord = [String]()
    @Published var correctWord: String = ""
    @Published var correctWordDefinition: String = ""
    @Published var wordDataDictionary = [String: WordData]()
    @Published var imageData: NaverImageData?
    @Published var isLoading = false
    @Published var errorMessage: String? //에러메세지
    
    var naverNetwork = NaverNetwork.shared
    
    init() {
        naverNetwork.delegate = self
        fetchData()
    }
    
    func fetchData() {
        Task {
            await setupNewQuiz()
        }
    }
    
    //퀴즈 셋업
    @MainActor
    func setupNewQuiz() async {
        isLoading = true
        correctWord = hardKoreanWords.hardWords.randomElement() ?? ""
        choiceWord = await generateChoices()
        
        do {
            let wordData = try await wordNetwork.searchWord(correctWord)
            await handleWordData(word: correctWord, wordData: wordData)
        } catch {
            handleNetworkError(error)
        }
        
        isLoading = false
    }
    
    //보기 생성
    func generateChoices() async -> [String] {
        var choices = [correctWord]
        while choices.count < 4 {
            let randomWord = hardKoreanWords.hardWords.randomElement()!
            if !choices.contains(randomWord) {
                choices.append(randomWord)
            }
        }
        return choices.shuffled()
    }
    
    //MARK: - KoreanWordSearchAPI
    
    // 단어 데이터 처리 메서드
    func handleWordData(word: String, wordData: WordData?) async {
        DispatchQueue.main.async {
            if let wordData = wordData {
                self.wordDataDictionary[word] = wordData
                if word == self.correctWord {
                    Task {
                        await self.fetchCorrectWordDefinition()
                        self.fetchImageForWord(self.correctWord)
                    }
                }
            } else {
                self.errorMessage = "\(word) 단어 데이터를 가져오지 못함"
            }
            self.isLoading = false
        }
    }
    
    // 정답 단어의 설명 가져오기
    func fetchCorrectWordDefinition() async {
        guard let wordData = wordDataDictionary[correctWord] else {
            DispatchQueue.main.async {
                self.correctWordDefinition = "설명을 가져올 수 없습니다."
                self.isLoading = false
            }
            return
        }
        
        if let firstSense = wordData.channel.item.first?.sense.first {
            DispatchQueue.main.async {
                self.correctWordDefinition = firstSense.definition
                print(self.correctWordDefinition)
            }
        } else {
            DispatchQueue.main.async {
                self.correctWordDefinition = "설명을 찾을 수 없습니다."
            }
        }
        DispatchQueue.main.async {
            self.isLoading = false
        }
        
    }
    
    //정답 확인 메서드 확인용
    func checkAnswer(selectedWord: String) -> Bool {
        return selectedWord == correctWord
    }
    //MARK: - NaverSearchAPI
    
    func fetchImageForWord (_ word: String) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        naverNetwork.requestSearchImage(query: word){ [weak self] in
            // 이미지 데이터 로드 완료 시에만 isLoading을 false로 설정
            DispatchQueue.main.async {
                self?.isLoading = false
            }
        }
    }
    
    //MARK: - NaverNetworkDelegate
    func imageDataUpdated(_ imageData: NaverImageData?) {
        //publishing changes from background threads is not allowed의 에러가 나와 변경.
        DispatchQueue.main.async { [weak self] in
            self?.imageData = imageData
        }
    }
    
    //MARK: - Error Handling
    func handleNetworkError(_ error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
