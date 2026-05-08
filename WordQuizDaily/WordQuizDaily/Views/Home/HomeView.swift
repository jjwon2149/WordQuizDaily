//
//  HomeView.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AdMobBannerView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        TodayWordSummaryCard(
                            word: homeViewModel.toDayWord,
                            learningWord: homeViewModel.todayLearningWord
                        )

                        if let learningWord = homeViewModel.todayLearningWord {
                            LearnerDetailCard(
                                title: LocalizedStringKey(LocalizationKeys.Word.englishMeaning),
                                text: learningWord.englishMeaning
                            )

                            LearnerDetailCard(
                                title: LocalizedStringKey(LocalizationKeys.Word.easyKorean),
                                text: learningWord.easyKoreanDefinition
                            )

                            ExampleDetailCard(learningWord: learningWord)
                        } else if !homeViewModel.toDayWordDefinition.isEmpty {
                            LearnerDetailCard(
                                title: LocalizedStringKey(LocalizationKeys.Word.easyKorean),
                                text: homeViewModel.toDayWordDefinition
                            )
                        } else {
                            ProgressView(LocalizedStringKey(LocalizationKeys.Common.loading))
                                .frame(maxWidth: .infinity, minHeight: 160)
                        }
                    }
                    .frame(maxWidth: 640, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizedStringKey(LocalizationKeys.Home.todayWord))
        }
    }

}

private struct TodayWordSummaryCard: View {
    let word: String
    let learningWord: LearningWord?

    private let columns = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible(), alignment: .leading)
    ]

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
                        value: learningWord.difficulty
                    )
                    MetadataBlock(
                        title: LocalizedStringKey(LocalizationKeys.Word.partOfSpeech),
                        value: learningWord.partOfSpeech
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

            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey(LocalizationKeys.Word.exampleTranslation))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(learningWord.exampleTranslation)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    HomeView()
        .environmentObject(HomeViewModel())
        .previewLocale("ko")
}

// MARK: - 다국어 프리뷰
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView()
                .environmentObject(HomeViewModel())
                .previewLocale("ko")
                .previewDisplayName("Korean")
            
            HomeView()
                .environmentObject(HomeViewModel())
                .previewLocale("en")
                .previewDisplayName("English")
            
            HomeView()
                .environmentObject(HomeViewModel())
                .previewLocale("ja")
                .previewDisplayName("Japanese")
        }
    }
}
