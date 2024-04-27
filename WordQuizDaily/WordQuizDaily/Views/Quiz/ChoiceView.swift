//
//  ChoiceView.swift
//  WordQuizDaily
//
//  Created by 정종원 on 2/22/24.
//

import SwiftUI

struct ChoiceView: View {
    
    @ObservedObject var quizViewModel: QuizViewModel
    @State private var isAnswerCorrect = false
    
    var body: some View {
        
        VStack{
            ForEach(quizViewModel.choiceWord.indices, id: \.self) { index in
                let word = quizViewModel.choiceWord[index]
                Button(action: {
                    isAnswerCorrect = quizViewModel.checkAnswer(selectedWord: word)
                    if isAnswerCorrect {
                        quizViewModel.fetchData()
                    }
                    print("선택된 단어: \(word), 정답?: \(isAnswerCorrect)")
                }) {
                    Text("  \(index + 1).  \(word) ")
                        .padding()
                        .frame(width: UIScreen.main.bounds.width - 20, height: 50, alignment: .leading)
                        .foregroundColor(.white)
                        .background(Color.black)
                        .cornerRadius(8)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    
                }
                .padding(5)
            }
        }
    }
}

#Preview {
    ChoiceView(quizViewModel: QuizViewModel())
}
