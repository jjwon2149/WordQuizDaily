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
            VStack {

                Spacer()
                VStack {
                    //문제 설명 뷰
                    answerExplainView()
                    
                    //문제 이미지 뷰
                    answerImageView()
                    
                    //문항
                    ChoiceView()
                }
                Spacer()
            }
            .navigationTitle("단어 퀴즈")

        }
    }
}

//MARK: - 문제 이미지 뷰
struct answerImageView: View {
    @EnvironmentObject var quizViewModel: QuizViewModel
    
    var body: some View {
        
        VStack {
            if quizViewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8, minHeight: 200, maxHeight: 200, alignment: .center)
            } else {
                if let imageData = quizViewModel.imageData {
                    if imageData.items.count > 3 {
                        let thirdImage = imageData.items[2]
                        KFImage(URL(string: thirdImage.link))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.8, minHeight: 200, maxHeight: 200, alignment: .center)
                    } else if let firstImage = imageData.items.first {
                        KFImage(URL(string: firstImage.link))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.8, minHeight: 200, maxHeight: 200, alignment: .center)
                    }
                }
            }
            
        }
    }
}

//MARK: - 문제 설명 뷰
struct answerExplainView: View {
    
    @EnvironmentObject var quizViewModel: QuizViewModel
    
    var body: some View {
        ScrollView {
            Text(quizViewModel.correctWordDefinition)
                .fixedSize(horizontal: false, vertical: true) // 가로 스크롤 비활성화, 세로 스크롤 활성화
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width * 0.8, height: 100)
        .foregroundColor(.black)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .gray, radius: 2, x: 0, y: 2)
        .scrollIndicators(.automatic)
    }
}


//MARK: - 문항 뷰
struct ChoiceView: View {
    
    @EnvironmentObject var quizViewModel: QuizViewModel
    @State private var isAnswerCorrect = false
    
    var body: some View {
        
        VStack {
            ForEach(quizViewModel.choiceWord.indices, id: \.self) { index in
                let word = quizViewModel.choiceWord[index]
                Button(action: {
                    if quizViewModel.isLoading {
                        
                    } else {
                        isAnswerCorrect = quizViewModel.checkAnswer(selectedWord: word)
                        if isAnswerCorrect {
                            quizViewModel.fetchData()
                        }
                        print("선택된 단어: \(word), 정답?: \(isAnswerCorrect)")
                    }
                }) {
                    HStack {
                        Circle()
                            .fill(Color.white)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                            .overlay {
                                Text("\(index + 1)")
                                    .foregroundStyle(Color.black)
                            }
                        Text("\(word) ")
                            .padding()
                            .frame(width: UIScreen.main.bounds.width * 0.65, height: 50, alignment: .leading)
                            .foregroundColor(.black)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.8, height: 50, alignment: .leading)
                }
                .disabled(quizViewModel.isLoading) // 로딩 중일 때 버튼 비활성화
                .padding(5)
            }
        }
    }
}


#Preview {
    QuizView()
        .environmentObject(QuizViewModel())
}
