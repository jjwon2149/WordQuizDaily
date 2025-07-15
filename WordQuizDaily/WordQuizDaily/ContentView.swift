//
//  ContentView.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var quizViewModel = QuizViewModel()
    @StateObject var homeViewModel = HomeViewModel()
    // FCM 기반 알림 매니저로 교체
    @StateObject var notificationManager = FCMNotificationManager()
    @EnvironmentObject var fcmService: FCMService
    @State private var selection = 2
    
    var body: some View {
        TabView(selection: $selection) {
            
            QuizView()
                .environmentObject(quizViewModel)
                .tag(1)
                .tabItem {
                    Label("Quiz", systemImage: "questionmark.circle")
                }
            
            HomeView()
                .environmentObject(homeViewModel)
                .tag(2)
                .tabItem {
                    Label("Home", systemImage: "house.circle.fill")
                }
            
            SettingView()
                .environmentObject(notificationManager)
                .tag(3)
                .tabItem {
                    Label("Setting", systemImage: "gearshape.fill")
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToQuiz"))) { _ in
            selection = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToHome"))) { _ in
            selection = 2
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToTodayWord"))) { _ in
            selection = 2 // 홈 화면으로 이동 (오늘의 단어가 홈에 있다고 가정)
        }
    }
}

#Preview {
    ContentView()
}
