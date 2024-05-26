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
        VStack{
            //문제 이미지 뷰
            VStack{
                answerImageView(quizViewModel: quizViewModel)
            }
            .padding()
            Spacer()
            //문제 설명 뷰
            VStack(alignment: .leading){
                answerExplainView(quizViewModel: quizViewModel)
            }
            Spacer()
            //문항
            VStack(alignment: .leading){
                ChoiceView(quizViewModel: quizViewModel)
            }
        }//VStack
        .padding()
    }
}

//MARK: - 문제 이미지 뷰
struct answerImageView: View {
    @ObservedObject var quizViewModel: QuizViewModel
    
    var body: some View {
        if quizViewModel.isLoading {
            ProgressView("Loading...")
                .frame(width: 200, height: 200)
        } else {
            if let imageData = quizViewModel.imageData {
                if imageData.items.count > 2 {
                    let thirdImage = imageData.items[2]
                    KFImage(URL(string: thirdImage.link))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                } else if let firstImage = imageData.items.first {
                    KFImage(URL(string: firstImage.link))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                }
            }
        }
    }
}

//MARK: - 문제 설명 뷰
struct answerExplainView: View {
    
    @ObservedObject var quizViewModel: QuizViewModel
    var body: some View {
        ScrollView {
            Text(quizViewModel.correctWordDefinition)
                .fixedSize(horizontal: false, vertical: true) // 가로 스크롤 비활성화, 세로 스크롤 활성화
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width - 20, height: 100)
        .foregroundColor(.white)
        .background(Color.black)
        .cornerRadius(8)
        .shadow(color: .gray, radius: 2, x: 0, y: 2)
    }
}


//MARK: - 문항 뷰
struct ChoiceView: View {
    
    @ObservedObject var quizViewModel: QuizViewModel
    @State private var isAnswerCorrect = false
    
    var body: some View {
        
        VStack{
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
                    Text("  \(index + 1).  \(word) ")
                        .padding()
                        .frame(width: UIScreen.main.bounds.width - 20, height: 50, alignment: .leading)
                        .foregroundColor(.white)
                        .background(Color.black)
                        .cornerRadius(8)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    
                }
                .disabled(quizViewModel.isLoading) // 로딩 중일 때 버튼 비활성화
                .padding(5)
            }
        }
    }
}


#Preview {
    QuizView()
}
