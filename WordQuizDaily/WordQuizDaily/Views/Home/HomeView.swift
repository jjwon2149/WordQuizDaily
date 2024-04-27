//
//  HomeView.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import SwiftUI

struct HomeView: View {
    
    @ObservedObject var homeViewModel = HomeViewModel()
    @State private var isLoaded = false
    
    var body: some View {
        VStack(spacing: 20){
            
            Spacer()
            
            Text("📸 오늘의 단어 📸")
                .font(.title)
                .padding()
            
            Spacer()
            
            Text("오늘의 단어!")
                .padding()
                .frame(width: UIScreen.main.bounds.width - 20, height: 50)
                .foregroundColor(.white)
                .background(Color.black)
                .cornerRadius(8)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
            

            Text(homeViewModel.toDayWord)
                .padding()
                .frame(width: UIScreen.main.bounds.width - 20, height: 50)
                .foregroundColor(.white)
                .background(Color.black)
                .cornerRadius(8)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
            
            // 데이터가 업데이트되면
            if !homeViewModel.toDayWordDefinition.isEmpty {
                Text(homeViewModel.toDayWordDefinition)
                    .padding()
                    .frame(width: UIScreen.main.bounds.width - 20, height: 100)
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(8)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
            }
            
            Spacer()
            
        }
        .onReceive(homeViewModel.$toDayWordDefinition) { _ in
            self.isLoaded = true
        }
    }
    
}

#Preview {
    HomeView()
}
