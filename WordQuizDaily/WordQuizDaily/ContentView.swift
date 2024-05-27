//
//  ContentView.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var quizViewModel = QuizViewModel()
    @StateObject var notificationManager = NotificationManager()
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
                .tag(2)
                .tabItem {
                    Label("Home", systemImage: "house.circle.fill")
                }
            
            SettingView()
                .environmentObject(notificationManager)
                .tag(3)
                .tabItem {
                    Label("Notification", systemImage: "bell.circle.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
