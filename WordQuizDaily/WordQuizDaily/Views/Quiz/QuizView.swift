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
            } else if let imageURL = imageURL {
                KFImage(imageURL)
                    .placeholder {
                        imagePlaceholder
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180, alignment: .center)
            } else {
                imagePlaceholder
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var imageURL: URL? {
        guard let imageData = quizViewModel.imageData else { return nil }
        let imageItem = imageData.items.count > 3 ? imageData.items[2] : imageData.items.first
        guard let imageLink = imageItem?.link else { return nil }
        return URL(string: imageLink)
    }

    private var imagePlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.title2)
                .foregroundColor(.secondary)
            Text(quizViewModel.correctLearningWord?.romanization ?? quizViewModel.correctWord)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180, alignment: .center)
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
                    HStack(spacing: 8) {
                        Text(learningWord.difficulty)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundColor(.blue)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(Capsule())

                        Text(learningWord.romanization)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
                    Text(LocalizationKeys.Quiz.correctAnswer.localized(with: learningWord.word))
                        .font(.headline)
                        .foregroundColor(.primary)

                    FeedbackDetailRow(titleKey: LocalizationKeys.Word.meaning, value: learningWord.englishMeaning)
                    FeedbackDetailRow(titleKey: LocalizationKeys.Word.difficulty, value: learningWord.difficulty)
                    FeedbackDetailRow(titleKey: LocalizationKeys.Word.example, value: learningWord.example)

                    Text(learningWord.exampleTranslation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(learningWord.easyKoreanDescription)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

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
