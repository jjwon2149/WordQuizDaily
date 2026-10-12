//
//  ContentView.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var learningStore: LearningStore
    @StateObject private var quizViewModel: QuizViewModel
    @StateObject private var homeViewModel: HomeViewModel
    // FCM 기반 알림 매니저로 교체
    @StateObject var notificationManager = FCMNotificationManager()
    @EnvironmentObject var fcmService: FCMService
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection = 2

    init() {
        let store = LearningStore()
        _learningStore = StateObject(wrappedValue: store)
        _quizViewModel = StateObject(wrappedValue: QuizViewModel(learningStore: store))
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(learningStore: store))
    }
    
    var body: some View {
        TabView(selection: $selection) {
            
            QuizView()
                .environmentObject(quizViewModel)
                .tag(1)
                .tabItem {
                    Label(LocalizedStringKey(LocalizationKeys.Tab.quiz), systemImage: "questionmark.circle")
                }
            
            HomeView()
                .environmentObject(homeViewModel)
                .tag(2)
                .tabItem {
                    Label(LocalizedStringKey(LocalizationKeys.Tab.home), systemImage: "house.circle.fill")
                }
            
            SettingView()
                .environmentObject(notificationManager)
                .tag(3)
                .tabItem {
                    Label(LocalizedStringKey(LocalizationKeys.Tab.settings), systemImage: "gearshape.fill")
                }
        }
        .environmentObject(learningStore)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToQuiz"))) { _ in
            selection = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToHome"))) { _ in
            selection = 2
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToTodayWord"))) { _ in
            selection = 2 // 홈 화면으로 이동 (오늘의 단어가 홈에 있다고 가정)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StartReview"))) { _ in
            quizViewModel.startReview()
            selection = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LearningProgressReset"))) { _ in
            quizViewModel.leaveReview()
        }
        .onChange(of: learningStore.selectedLevel) { _, _ in
            if !quizViewModel.isReviewMode { quizViewModel.fetchData() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                homeViewModel.fetchTodayWordOnceADay()
                notificationManager.refreshAuthorizationAndSchedule()
            }
        }
    }
}

#Preview {
    ContentView()
        .previewLocale("ko")
}

// MARK: - 다국어 프리뷰
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewLocale("ko")
                .previewDisplayName("Korean")
            
            ContentView()
                .previewLocale("en")
                .previewDisplayName("English")
            
            ContentView()
                .previewLocale("ja")
                .previewDisplayName("Japanese")
        }
    }
}
