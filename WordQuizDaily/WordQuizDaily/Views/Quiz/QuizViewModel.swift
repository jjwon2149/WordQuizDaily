//
//  QuizViewModel.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/27/24.
//

import Foundation
import Kingfisher
import LearningCore

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
    @Published var imageError: NaverImageError?
    @Published var hasImageRenderFailed = false
    @Published var isLoading = false
    @Published var isImageLoading = false
    @Published var errorMessage: String?
    @Published private(set) var isReviewMode = false
    @Published private(set) var isReviewComplete = false
    @Published private(set) var reviewCorrectCount = 0
    @Published private(set) var reviewTotalCount = 0

    var naverNetwork = NaverNetwork.shared
    private let learningStore: LearningStore
    private var learningWordRepository: LearningWordProviding { learningStore.repository }
    private var imageRequestWord: String?
    private var imageRequestGate = RequestIdentityGate()
    private var recentWordIDs: [String] = []
    private var submissionID = UUID()
    private var reviewSession: ReviewSession?

    var hasSubmittedAnswer: Bool {
        answerState != .waitingForAnswer
    }

    var isSelectedAnswerCorrect: Bool {
        answerState == .correct
    }

    init(learningStore: LearningStore) {
        self.learningStore = learningStore
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
        imageError = nil
        hasImageRenderFailed = false
        isImageLoading = false
        imageRequestWord = nil
        selectedWord = nil
        answerState = .waitingForAnswer
        correctLearningWord = nil
        correctWord = ""
        correctWordDefinition = ""
        choiceWord = []

        let question: QuizQuestion
        do {
            if isReviewMode {
                guard let learningWord = reviewSession?.currentWordID.flatMap(learningWordRepository.word(id:)) else {
                    isReviewComplete = true
                    isLoading = false
                    return
                }
                question = try QuizSelector.question(for: learningWord, words: learningWordRepository.words)
            } else {
                question = try QuizSelector.question(
                    words: learningWordRepository.words,
                    selection: learningStore.selectedLevel,
                    recentIDs: recentWordIDs
                )
            }
        } catch {
            errorMessage = (learningStore.catalogLoadFailed ? LocalizationKeys.Error.catalogUnavailable : LocalizationKeys.Quiz.insufficientChoices).localized
            isLoading = false
            return
        }

        let learningWord = question.answer
        applyQuizWord(learningWord, choices: question.choices)
        recentWordIDs.append(learningWord.id)
        recentWordIDs = Array(recentWordIDs.suffix(3))
        submissionID = UUID()
        fetchImageForWord(learningWord.korean)
        isLoading = false
    }

    private func applyQuizWord(_ word: LearningWord, choices: [LearningWord]) {
        correctLearningWord = word
        correctWord = word.korean
        correctWordDefinition = word.displayDefinition
        wordDataDictionary[word.korean] = WordData(learningWord: word)
        choiceWord = choices.map(\.korean)
    }

    /*
        A missing or invalid local catalog is handled above as a recoverable state.
        Core quiz behavior never falls back to network or the legacy hard-word list.
    */

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
    @MainActor
    func checkAnswer(selectedWord: String) -> Bool {
        guard !isLoading,
              !hasSubmittedAnswer,
              correctLearningWord != nil,
              choiceWord.contains(selectedWord) else {
            return isSelectedAnswerCorrect
        }

        let isCorrect = selectedWord == correctWord
        if let id = correctLearningWord?.id {
            guard learningStore.record(wordID: id, isCorrect: isCorrect, submissionID: submissionID) else {
                errorMessage = learningStore.persistenceError ?? LocalizationKeys.Error.dataLoad.localized
                return false
            }
        }
        self.selectedWord = selectedWord
        answerState = isCorrect ? .correct : .incorrect
        errorMessage = nil
        if isReviewMode {
            reviewSession?.submit(isCorrect: isCorrect)
            reviewCorrectCount = reviewSession?.correctCount ?? reviewCorrectCount
        }
        return isCorrect
    }

    @MainActor
    func moveToNextQuiz() {
        guard !isLoading else { return }
        fetchData()
    }

    @MainActor
    func startReview() {
        let ids = learningStore.reviewWordIDs
        reviewSession = ReviewSession(wordIDs: ids)
        reviewTotalCount = ids.count
        reviewCorrectCount = 0
        isReviewComplete = ids.isEmpty
        isReviewMode = !ids.isEmpty
        fetchData()
    }

    @MainActor
    func leaveReview() {
        isReviewMode = false
        isReviewComplete = false
        reviewSession = nil
        fetchData()
    }

    // MARK: - NaverSearchAPI

    func fetchImageForWord(_ word: String) {
        imageData = nil
        imageError = nil
        hasImageRenderFailed = false
        imageRequestWord = word
        isImageLoading = true

        let requestID = imageRequestGate.begin()
        naverNetwork.requestSearchImage(query: word, requestID: requestID) { [weak self] in
            DispatchQueue.main.async {
                guard self?.imageRequestWord == word, self?.imageRequestGate.accepts(requestID) == true else { return }
                self?.isImageLoading = false
            }
        }
    }

    // MARK: - NaverNetworkDelegate

    func imageDataUpdated(_ result: Result<NaverImageData, NaverImageError>, requestID: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  self.imageRequestWord == self.correctWord,
                  self.imageRequestGate.accepts(requestID) else { return }

            switch result {
            case .success(let imageData):
                self.imageData = imageData
                self.imageError = nil
            case .failure(let error):
                self.imageData = nil
                self.imageError = error
            }
            self.isImageLoading = false
        }
    }

    func handleImageRenderFailure(url: URL, error: Error) {
        hasImageRenderFailed = true
    }

    func handleAllImageCandidatesFailed() {
        DispatchQueue.main.async {
            self.hasImageRenderFailed = true
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
