//
//  AppDelegate.swift
//  WordQuizDaily
//
//  Created by 정종원 on FCM Migration
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase 초기화
        FirebaseApp.configure()
        // AdMob 초기화
        MobileAds.shared.start(completionHandler: nil)
        
        
        
        // FCM 델리게이트 설정
        Messaging.messaging().delegate = self
        
        // UNUserNotificationCenter 델리게이트 설정
        UNUserNotificationCenter.current().delegate = self
        
        // 푸시 알림 권한 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("FCM Permission granted: \(granted)")
            if let error = error {
                print("FCM Permission error: \(error.localizedDescription)")
            }
        }
        
        // 원격 알림 등록
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // APNs 토큰 수신
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token received: \(deviceToken)")
        
        // FCM에 APNs 토큰 설정
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // APNs 등록 실패
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    
    // FCM 토큰 갱신
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        
        // FCM 서비스에 토큰 전달
        FCMService.shared.updateFCMToken(fcmToken)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // 포그라운드에서 알림 수신
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        
        // FCM 알림 로깅
        print("Foreground notification received: \(userInfo)")
        
        // 포그라운드에서도 알림 표시
        completionHandler([[.banner, .badge, .sound]])
    }
    
    // 알림 탭 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        // 딥링크 처리
        handleNotificationResponse(userInfo: userInfo)
        
        completionHandler()
    }
    
    // 딥링크 처리 로직
    private func handleNotificationResponse(userInfo: [AnyHashable: Any]) {
        print("Notification tapped: \(userInfo)")
        
        // 특정 화면으로 이동하는 로직
        if let deepLink = userInfo["deepLink"] as? String {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name("HandleDeepLink"),
                    object: deepLink
                )
            }
        }
        
        // FCM 서비스에 알림 탭 이벤트 전달
        FCMService.shared.handleNotificationTap(userInfo: userInfo)
    }
}
