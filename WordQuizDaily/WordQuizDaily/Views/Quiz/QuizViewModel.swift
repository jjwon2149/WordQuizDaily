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
    
    var choiceWord = [String]()
    var correctWord: String = ""
    var correctWordDefinition: String = ""
    var wordDataDictionary = [String: WordData]()
    let naverNetwork = NaverNetwork.shared
    
    @Published var imageData: NaverImageData?
    @Published var isLoading = false
    
    init() {
        correctWord = hardKoreanWords.hardWords.randomElement() ?? ""
        generateChoices()
        
        naverNetwork.delegate = self
    }
    
    //보기 생성
    func generateChoices() {
        choiceWord.append(correctWord)
        
        while choiceWord.count < 4 {
            let randomWord = hardKoreanWords.hardWords.randomElement()!
            if !choiceWord.contains(randomWord) {
                choiceWord.append(randomWord)
            }
        }
        //보기 섞기
        choiceWord.shuffle()
        
        //단어 검색 및 데이터 저장
        for word in choiceWord {
            wordNetwork.searchWord(word) { wordData in
                self.handleWordData(word: word, wordData: wordData)
            }
        }
        print(choiceWord)
        isLoading = true // 네트워크 요청 시작 시 isLoading을 true
    }
    
    func fetchData() {
        
            correctWord = hardKoreanWords.hardWords.randomElement() ?? ""
            
            choiceWord.removeAll()
            generateChoices()
            
            fetchCorrectWordDefinition()
            fetchImageForWord(correctWord)
        }
    
    
    //MARK: - KoreanWordSearchAPI
    
    // 단어 데이터 처리 메서드
    func handleWordData(word: String, wordData: WordData?) {
        if let wordData = wordData {
            wordDataDictionary[word] = wordData
            // 정답 단어의 설명을 가져오기
            if word == correctWord {
                fetchCorrectWordDefinition()
                fetchImageForWord(correctWord)
            }
        } else {
            print("\(word) 단어 데이터를 가져오지 못함 ")
            isLoading = false // 데이터를 가져오지 못한 경우 isLoading을 false로 설정하여 프로그레스 뷰를 숨김
        }
        
        isLoading = false
    }
    
    // 정답 단어의 설명 가져오기
    func fetchCorrectWordDefinition() {
        isLoading = true
        
        guard let wordData = wordDataDictionary[correctWord] else {
            correctWordDefinition = "설명을 가져올 수 없습니다."
            isLoading = false // 작업 완료
            return
        }
        
        if let firstSense = wordData.channel.item.first?.sense.first {
            correctWordDefinition = firstSense.definition
            print(correctWordDefinition)
        } else {
            correctWordDefinition = "설명을 찾을 수 없습니다."
        }
        
        isLoading = false // 작업 완료
    }
    
    //정답 확인 메서드 확인용
    func checkAnswer(selectedWord: String) -> Bool {
        return selectedWord == correctWord
    }
    //MARK: - NaverSearchAPI
    
    func fetchImageForWord(_ word: String) {
        isLoading = true
        
        naverNetwork.requestSearchImage(query: word){ [weak self] in
            // 이미지 데이터 로드 완료 시에만 isLoading을 false로 설정
            self?.isLoading = false
        }
    }
    
    //MARK: - NaverNetworkDelegate
    func imageDataUpdated(_ imageData: NaverImageData?) {
        //publishing changes from background threads is not allowed의 에러가 나와 변경.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.imageData = imageData
        }
    }
}
