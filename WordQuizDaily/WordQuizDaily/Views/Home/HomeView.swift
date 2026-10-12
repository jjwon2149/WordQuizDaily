//
//  HomeView.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var learningStore: LearningStore
    @Environment(\.locale) private var locale
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        TodayWordSummaryCard(
                            word: homeViewModel.toDayWord,
                            learningWord: homeViewModel.todayLearningWord,
                            languageCode: locale.identifier
                        )

                        LearningProgressCard(
                            todayCount: learningStore.todayAnswerCount,
                            reviewCount: learningStore.reviewCount
                        )
                        if let persistenceError = learningStore.persistenceError {
                            Label(persistenceError, systemImage: "exclamationmark.triangle")
                                .font(.footnote).foregroundStyle(.red)
                                .accessibilityLabel(persistenceError)
                        }

                        if let learningWord = homeViewModel.todayLearningWord {
                            let languageCode = locale.identifier
                            let normalizedLanguage = LocalizationHelper.normalizedLanguageCode(languageCode)

                            if normalizedLanguage == "en" {
                                LearnerDetailCard(
                                    title: LocalizedStringKey(LocalizationKeys.Word.englishMeaning),
                                    text: learningWord.englishMeaning
                                )
                            }

                            LearnerDetailCard(
                                title: LocalizedStringKey(LocalizationKeys.Word.easyKorean),
                                text: learningWord.easyKoreanDefinition
                            )

                            ExampleDetailCard(
                                learningWord: learningWord,
                                languageCode: languageCode
                            )
                        } else if !homeViewModel.toDayWordDefinition.isEmpty {
                            LearnerDetailCard(
                                title: LocalizedStringKey(LocalizationKeys.Word.easyKorean),
                                text: homeViewModel.toDayWordDefinition
                            )
                        } else if let message = homeViewModel.errorMessage {
                            ContentUnavailableView {
                                Label(LocalizedStringKey(LocalizationKeys.Common.error), systemImage: "exclamationmark.triangle")
                            } description: { Text(message) } actions: {
                                Button(LocalizedStringKey(LocalizationKeys.Common.retry)) { homeViewModel.fetchTodayWordOnceADay() }
                            }
                        } else {
                            ProgressView(LocalizedStringKey(LocalizationKeys.Common.loading)).frame(maxWidth: .infinity, minHeight: 160)
                        }
                    }
                    .frame(maxWidth: 640, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                }
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AdMobBannerView()
                    .background(Color(.systemGroupedBackground))
            }
            .navigationTitle(LocalizedStringKey(LocalizationKeys.Home.todayWord))
        }
    }

}

private struct LearningProgressCard: View {
    let todayCount: Int
    let reviewCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey(LocalizationKeys.LearningProgress.title)).font(.headline)
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(LocalizedStringKey(LocalizationKeys.LearningProgress.todaySolved)).font(.caption).foregroundStyle(.secondary)
                    Label("\(todayCount)", systemImage: "checklist").font(.title3.bold())
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text(LocalizedStringKey(LocalizationKeys.LearningProgress.toReview)).font(.caption).foregroundStyle(.secondary)
                    Label("\(reviewCount)", systemImage: "arrow.clockwise").font(.title3.bold())
                }
            }
            Text(LocalizedStringKey(reviewCount == 0 ? LocalizationKeys.LearningProgress.empty : LocalizationKeys.LearningProgress.summary))
                .font(.subheadline).foregroundStyle(.secondary)
            Button {
                NotificationCenter.default.post(name: Notification.Name("StartReview"), object: nil)
            } label: {
                Label(LocalizedStringKey(LocalizationKeys.LearningProgress.startReview), systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(reviewCount == 0)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct TodayWordSummaryCard: View {
    let word: String
    let learningWord: LearningWord?
    let languageCode: String

    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 16, alignment: .leading)]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(word.isEmpty ? LocalizationKeys.Common.loading.localized : word)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                if let romanization = learningWord?.romanization {
                    Text(romanization)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let learningWord {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                    MetadataBlock(
                        title: LocalizedStringKey(LocalizationKeys.Word.difficulty),
                        value: learningWord.localizedDifficulty(for: languageCode)
                    )
                    MetadataBlock(
                        title: LocalizedStringKey(LocalizationKeys.Word.partOfSpeech),
                        value: learningWord.localizedPartOfSpeech(for: languageCode)
                    )
                    MetadataBlock(
                        title: LocalizedStringKey(LocalizationKeys.Word.romanization),
                        value: learningWord.romanization
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}

private struct MetadataBlock: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LearnerDetailCard: View {
    let title: LocalizedStringKey
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ExampleDetailCard: View {
    let learningWord: LearningWord
    let languageCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey(LocalizationKeys.Word.example))
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(learningWord.example)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            if let exampleTranslation = learningWord.exampleTranslation(for: languageCode) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey(LocalizationKeys.Word.exampleTranslation))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(exampleTranslation)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    let store = LearningStore()
    HomeView()
        .environmentObject(HomeViewModel(learningStore: store))
        .environmentObject(store)
        .previewLocale("ko")
}

// MARK: - 다국어 프리뷰
struct HomeView_Previews: PreviewProvider {
    static let store = LearningStore()
    static var previews: some View {
        Group {
            HomeView()
                .environmentObject(HomeViewModel(learningStore: store))
                .environmentObject(store)
                .previewLocale("ko")
                .previewDisplayName("Korean")
            
            HomeView()
                .environmentObject(HomeViewModel(learningStore: store))
                .environmentObject(store)
                .previewLocale("en")
                .previewDisplayName("English")
            
            HomeView()
                .environmentObject(HomeViewModel(learningStore: store))
                .environmentObject(store)
                .previewLocale("ja")
                .previewDisplayName("Japanese")
        }
    }
}
