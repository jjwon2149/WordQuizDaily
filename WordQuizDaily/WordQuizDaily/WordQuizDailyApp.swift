//
//  WordQuizDailyApp.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import SwiftUI

@main
struct WordQuizDailyApp: App {
    // AppDelegate 연동
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(FCMService.shared)
        }
    }
}
