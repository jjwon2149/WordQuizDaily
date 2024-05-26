//
//  QuizView.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import SwiftUI
import Kingfisher
struct QuizView: View {
    
    @ObservedObject var quizViewModel = QuizViewModel()
    @State var isAnswerCorrect = false
    
    var body: some View {
        
        VStack{
            
            //MARK: - 문제의 이미지
            VStack{
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
            .padding()
            
            Spacer()
            
            //MARK: - 문제의 뜻
            VStack(alignment: .leading){
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
            
            Spacer()
            
            //MARK: - 보기
            VStack(alignment: .leading){
                
                ChoiceView(quizViewModel: quizViewModel)
            }
            
            
        }//VStack
        .padding()
    }
}


#Preview {
    QuizView()
}
