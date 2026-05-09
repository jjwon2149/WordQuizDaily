//
//  QuizView.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import SwiftUI
import Kingfisher

struct QuizView: View {

    @EnvironmentObject var quizViewModel: QuizViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    answerExplainView()
                    answerImageView()
                    ChoiceView()
                    QuizFeedbackView()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationTitle(LocalizedStringKey(LocalizationKeys.Quiz.title))
        }
    }
}

//MARK: - 문제 이미지 뷰
struct answerImageView: View {
    @EnvironmentObject var quizViewModel: QuizViewModel

    var body: some View {
        VStack {
            if quizViewModel.isImageLoading {
                ProgressView(LocalizedStringKey(LocalizationKeys.Quiz.loadingImages))
                    .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180, alignment: .center)
            } else if let imageItem = quizViewModel.imageData?.preferredItem,
                      !imageItem.imageURLCandidates.isEmpty {
                AnswerRemoteImage(
                    imageItem: imageItem,
                    onFailure: quizViewModel.handleImageRenderFailure,
                    onUnavailable: quizViewModel.handleAllImageCandidatesFailed
                )
                .id("\(imageItem.thumbnail)-\(imageItem.link)")
            } else if quizViewModel.hasImageRenderFailed || quizViewModel.imageError != nil {
                unavailablePlaceholder
            } else {
                neutralPlaceholder
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var neutralPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180, alignment: .center)
    }

    private var unavailablePlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.title2)
                .foregroundColor(.secondary)
            Text(LocalizedStringKey(LocalizationKeys.Quiz.imageUnavailable))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180, alignment: .center)
    }
}

struct AnswerRemoteImage: View {
    let imageItem: NaverItem
    let onFailure: (URL, Error) -> Void
    let onUnavailable: () -> Void

    @State private var imageURLIndex = 0

    private var imageURLs: [URL] {
        imageItem.imageURLCandidates
    }

    var body: some View {
        if imageURLs.indices.contains(imageURLIndex) {
            let imageURL = imageURLs[imageURLIndex]
            KFImage(imageURL)
                .onFailure { error in
                    onFailure(imageURL, error)
                    DispatchQueue.main.async {
                        if imageURLIndex + 1 < imageURLs.count {
                            imageURLIndex += 1
                        } else {
                            onUnavailable()
                        }
                    }
                }
                .placeholder {
                    ProgressView(LocalizedStringKey(LocalizationKeys.Quiz.loadingImages))
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180, alignment: .center)
        } else {
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180, alignment: .center)
                .onAppear(perform: onUnavailable)
        }
    }
}

//MARK: - 문제 설명 뷰
struct answerExplainView: View {

    @EnvironmentObject var quizViewModel: QuizViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if quizViewModel.isLoading {
                ProgressView(LocalizedStringKey(LocalizationKeys.Common.loading))
                    .frame(maxWidth: .infinity, minHeight: 90, alignment: .center)
            } else {
                if let learningWord = quizViewModel.correctLearningWord {
                    Text(learningWord.difficulty)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundColor(.blue)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())
                }

                Text(quizViewModel.correctWordDefinition)
                    .font(.body)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .gray.opacity(0.35), radius: 2, x: 0, y: 2)
    }
}


//MARK: - 문항 뷰
struct ChoiceView: View {

    @EnvironmentObject var quizViewModel: QuizViewModel

    var body: some View {
        VStack(spacing: 10) {
            ForEach(quizViewModel.choiceWord.indices, id: \.self) { index in
                let word = quizViewModel.choiceWord[index]
                Button(action: {
                    let isAnswerCorrect = quizViewModel.checkAnswer(selectedWord: word)
                    print("\(LocalizationKeys.Quiz.selectedWord.localized): \(word), \(LocalizationKeys.Quiz.isCorrect.localized)?: \(isAnswerCorrect)")
                }) {
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(width: 30, height: 30)
                            .foregroundColor(.primary)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())

                        Text(word)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer()

                        if let iconName = statusIconName(for: word) {
                            Image(systemName: iconName)
                                .foregroundColor(statusColor(for: word))
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background(choiceBackground(for: word))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(statusColor(for: word).opacity(0.45), lineWidth: quizViewModel.hasSubmittedAnswer ? 1.5 : 0)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(quizViewModel.isLoading || quizViewModel.hasSubmittedAnswer)
            }
        }
    }

    private func statusIconName(for word: String) -> String? {
        guard quizViewModel.hasSubmittedAnswer else { return nil }
        if word == quizViewModel.correctWord {
            return "checkmark.circle.fill"
        }
        if word == quizViewModel.selectedWord {
            return "xmark.circle.fill"
        }
        return nil
    }

    private func statusColor(for word: String) -> Color {
        guard quizViewModel.hasSubmittedAnswer else {
            return .clear
        }
        if word == quizViewModel.correctWord {
            return .green
        }
        if word == quizViewModel.selectedWord {
            return .red
        }
        return .clear
    }

    private func choiceBackground(for word: String) -> Color {
        guard quizViewModel.hasSubmittedAnswer else {
            return Color(.systemBackground)
        }
        if word == quizViewModel.correctWord {
            return Color.green.opacity(0.16)
        }
        if word == quizViewModel.selectedWord {
            return Color.red.opacity(0.14)
        }
        return Color(.systemBackground)
    }
}

struct QuizFeedbackView: View {

    @EnvironmentObject var quizViewModel: QuizViewModel
    @Environment(\.locale) private var locale

    var body: some View {
        if quizViewModel.hasSubmittedAnswer {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: quizViewModel.isSelectedAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(quizViewModel.isSelectedAnswerCorrect ? .green : .red)

                    Text(LocalizedStringKey(quizViewModel.isSelectedAnswerCorrect ? LocalizationKeys.Quiz.correct : LocalizationKeys.Quiz.incorrect))
                        .font(.headline)
                }

                if let selectedWord = quizViewModel.selectedWord, !quizViewModel.isSelectedAnswerCorrect {
                    Text("\(LocalizationKeys.Quiz.selectedWord.localized): \(selectedWord)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let learningWord = quizViewModel.correctLearningWord {
                    let languageCode = locale.identifier
                    let feedbackMeaning = learningWord.meaning(for: languageCode)
                    let feedbackDescription = learningWord.feedbackDescription(for: languageCode)

                    Text(LocalizationKeys.Quiz.correctAnswer.localized(with: learningWord.word))
                        .font(.headline)
                        .foregroundColor(.primary)

                    FeedbackDetailRow(titleKey: LocalizationKeys.Word.meaning, value: feedbackMeaning)
                    FeedbackDetailRow(titleKey: LocalizationKeys.Word.difficulty, value: learningWord.difficulty)
                    FeedbackDetailRow(titleKey: LocalizationKeys.Word.example, value: learningWord.example)

                    if let exampleTranslation = learningWord.exampleTranslation(for: languageCode) {
                        Text(exampleTranslation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if feedbackDescription != feedbackMeaning {
                        Text(feedbackDescription)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !quizViewModel.isSelectedAnswerCorrect {
                        FeedbackDetailRow(titleKey: LocalizationKeys.Feedback.title, value: learningWord.incorrectFeedback)
                    }
                }

                Button(action: {
                    quizViewModel.moveToNextQuiz()
                }) {
                    Label(LocalizedStringKey(LocalizationKeys.Quiz.nextButton), systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(quizViewModel.isLoading)
                .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .gray.opacity(0.35), radius: 2, x: 0, y: 2)
        }
    }
}

private struct FeedbackDetailRow: View {
    let titleKey: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(titleKey))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}


#Preview("한국어") {
    QuizView()
        .environmentObject(QuizViewModel())
        .previewLocale("ko")
}

#Preview("English") {
    QuizView()
        .environmentObject(QuizViewModel())
        .previewLocale("en")
}

#Preview("日本語") {
    QuizView()
        .environmentObject(QuizViewModel())
        .previewLocale("ja")
}
