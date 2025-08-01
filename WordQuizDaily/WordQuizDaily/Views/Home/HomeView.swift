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
        NavigationStack{
            ZStack {
                // AdMob 배너 광고 - 최상단 위치
                AdMobBannerView()
                    .padding(.top, 10)
            }
            VStack{
                
                VStack {
                    
                    Spacer()
                        .frame(height: 150)
                    
                    VStack {
                        Text(homeViewModel.toDayWord)
                            .padding()
                            .frame(width: UIScreen.main.bounds.width * 0.8, height: 50)
                            .foregroundColor(.black)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    }
                    Spacer()
                        .frame(height: 50)
                    VStack {
                        // 데이터가 업데이트되면
                        if !homeViewModel.toDayWordDefinition.isEmpty {
                            Text(homeViewModel.toDayWordDefinition)
                                .padding()
                                .frame(width: UIScreen.main.bounds.width * 0.8, height: 200)
                                .foregroundColor(.black)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                        }
                    }
                }
                
                Spacer()
                
            }
            .navigationTitle(LocalizedStringKey(LocalizationKeys.Home.todayWord))

        }
        .onReceive(homeViewModel.$toDayWordDefinition) { _ in
            self.isLoaded = true
        }
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
