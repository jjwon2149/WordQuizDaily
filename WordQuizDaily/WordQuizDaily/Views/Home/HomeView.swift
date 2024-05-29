//
//  HomeView.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var isLoaded = false
    
    var body: some View {
        VStack{
            Text("오늘의 단어")
                .font(.title2)
                .padding(.leading, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.black)
            
            Spacer()
            
            VStack {
                
                Spacer()
                    .frame(height: 50)
                
                VStack {
                    Text(homeViewModel.toDayWord)
                        .padding()
                        .frame(width: UIScreen.main.bounds.width * 0.8, height: 50)
                        .foregroundColor(.black)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                }
                
                VStack {
                    // 데이터가 업데이트되면
                    if !homeViewModel.toDayWordDefinition.isEmpty {
                        Text(homeViewModel.toDayWordDefinition)
                            .padding()
                            .frame(width: UIScreen.main.bounds.width * 0.8, height: 50)
                            .foregroundColor(.black)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    }
                }
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
        .environmentObject(HomeViewModel())
}
