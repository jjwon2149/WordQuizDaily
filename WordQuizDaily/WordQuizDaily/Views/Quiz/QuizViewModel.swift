//
//  QuizViewModel.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/27/24.
//

import Foundation
import Kingfisher

enum QuizAnswerState: Equatable {
    case waitingForAnswer
    case correct
    case incorrect
}

class QuizViewModel: ObservableObject, NaverNetworkDelegate {

    @Published var choiceWord = [String]()
    @Published var correctWord: String = ""
    @Published var correctWordDefinition: String = ""
    @Published var correctLearningWord: LearningWord?
    @Published var selectedWord: String?
    @Published var answerState: QuizAnswerState = .waitingForAnswer
    @Published var wordDataDictionary = [String: WordData]()
    @Published var imageData: NaverImageData?
    @Published var isLoading = false
    @Published var isImageLoading = false
    @Published var errorMessage: String?

    var naverNetwork = NaverNetwork.shared
    let hardKoreanWords = HardKoreanWords()
    private let learningWordRepository: LearningWordProviding

    var hasSubmittedAnswer: Bool {
        answerState != .waitingForAnswer
    }

    var isSelectedAnswerCorrect: Bool {
        answerState == .correct
    }

    init(learningWordRepository: LearningWordProviding = LearningWordRepository.shared) {
        self.learningWordRepository = learningWordRepository
        naverNetwork.delegate = self
        fetchData()
    }

    func fetchData() {
        Task {
            await setupNewQuiz()
        }
    }

    // 퀴즈 셋업
    @MainActor
    func setupNewQuiz() async {
        isLoading = true
        errorMessage = nil
        imageData = nil
        selectedWord = nil
        answerState = .waitingForAnswer

        if let learningWord = learningWordRepository.randomWord(excluding: []) {
            applyQuizWord(learningWord)
            isLoading = false
            fetchImageForWord(learningWord.korean)
            return
        }

        correctLearningWord = nil
        correctWord = hardKoreanWords.hardWords.randomElement() ?? ""
        correctWordDefinition = "설명을 가져올 수 없습니다."
        choiceWord = generateFallbackChoices()
        isLoading = false
    }

    // 보기 생성
    func generateChoices() -> [String] {
        guard let correctLearningWord else {
            return generateFallbackChoices()
        }

        return learningWordRepository
            .choices(for: correctLearningWord, count: 4)
            .map(\.korean)
    }

    func generateFallbackChoices() -> [String] {
        var choices = [correctWord]
        while choices.count < 4 {
            guard let randomWord = hardKoreanWords.hardWords.randomElement() else {
                break
            }
            if !choices.contains(randomWord) {
                choices.append(randomWord)
            }
        }
        return choices.shuffled()
    }

    private func applyQuizWord(_ word: LearningWord) {
        correctLearningWord = word
        correctWord = word.korean
        correctWordDefinition = word.displayDefinition
        wordDataDictionary[word.korean] = WordData(learningWord: word)
        choiceWord = learningWordRepository
            .choices(for: word, count: 4)
            .map(\.korean)
    }

    // MARK: - KoreanWordSearchAPI

    func handleWordData(word: String, wordData: WordData?) async {
        DispatchQueue.main.async {
            if let wordData = wordData {
                self.wordDataDictionary[word] = wordData
                if word == self.correctWord {
                    Task {
                        await self.fetchCorrectWordDefinition()
                    }
                }
            } else {
                self.errorMessage = "\(word) 단어 데이터를 가져오지 못함"
            }
            self.isLoading = false
        }
    }

    func fetchCorrectWordDefinition() async {
        guard let wordData = wordDataDictionary[correctWord] else {
            DispatchQueue.main.async {
                self.correctWordDefinition = "설명을 가져올 수 없습니다."
                self.isLoading = false
            }
            return
        }

        if let definition = wordData.firstDefinition {
            DispatchQueue.main.async {
                self.correctWordDefinition = definition
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

    @discardableResult
    func checkAnswer(selectedWord: String) -> Bool {
        guard !isLoading, !hasSubmittedAnswer else {
            return isSelectedAnswerCorrect
        }

        self.selectedWord = selectedWord
        let isCorrect = selectedWord == correctWord
        answerState = isCorrect ? .correct : .incorrect
        return isCorrect
    }

    @MainActor
    func moveToNextQuiz() {
        guard !isLoading else { return }
        fetchData()
    }

    // MARK: - NaverSearchAPI

    func fetchImageForWord(_ word: String) {
        DispatchQueue.main.async {
            self.isImageLoading = true
        }

        naverNetwork.requestSearchImage(query: word) { [weak self] in
            DispatchQueue.main.async {
                self?.isImageLoading = false
            }
        }
    }

    // MARK: - NaverNetworkDelegate

    func imageDataUpdated(_ imageData: NaverImageData?) {
        DispatchQueue.main.async { [weak self] in
            self?.imageData = imageData
            self?.isImageLoading = false
        }
    }

    // MARK: - Error Handling

    func handleNetworkError(_ error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            self.isImageLoading = false
        }
    }
}
