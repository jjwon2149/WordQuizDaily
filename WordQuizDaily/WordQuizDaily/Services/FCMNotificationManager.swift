//
//  FCMNotificationManager.swift
//  WordQuizDaily
//
//  Created by 정종원 on FCM Migration
//

import Foundation
import Combine
import UserNotifications
import SwiftUI

class FCMNotificationManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAlertOccurred: Bool = false
    @Published var notificationTime: Date = Date() {
        didSet {
            // FCM은 서버에서 스케줄링하므로 시간 변경 시 서버에 알림
            scheduleNotificationTime()
        }
    }
    @Published var isToggleOn: Bool = UserDefaults.standard.bool(forKey: "hasUserAgreedNoti") {
        didSet {
            UserDefaults.standard.set(isToggleOn, forKey: "hasUserAgreedNoti")
            handleToggleChange()
        }
    }
    @Published var isNotificationAuthorized: Bool = false
    
    // MARK: - Dependencies
    private let fcmService = FCMService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
        checkNotificationStatus()
    }
    
    private func setupBindings() {
        // FCM 토큰 변경 감지
        fcmService.fcmTokenPublisher
            .sink { [weak self] token in
                print("FCM Token updated: \(token ?? "nil")")
                // 필요시 서버에 토큰 전송
                self?.sendTokenToServer(token)
            }
            .store(in: &cancellables)
        
        // 알림 수신 감지
        fcmService.notificationReceivedPublisher
            .sink { [weak self] notification in
                self?.handleReceivedNotification(notification)
            }
            .store(in: &cancellables)
        
        // 알림 탭 감지
        fcmService.notificationTappedPublisher
            .sink { [weak self] userInfo in
                self?.handleNotificationTap(userInfo)
            }
            .store(in: &cancellables)
        
        // 권한 상태 바인딩
        fcmService.$isNotificationAuthorized
            .assign(to: \.isNotificationAuthorized, on: self)
            .store(in: &cancellables)
    }
}

// MARK: - Public Methods (기존 NotificationManager 인터페이스 유지)
extension FCMNotificationManager {
    
    func requestNotiAuthorization() {
        fcmService.requestNotificationPermission()
            .sink { [weak self] granted in
                if granted {
                    self?.isNotificationAuthorized = true
                    self?.scheduleNotificationTime()
                } else {
                    self?.isToggleOn = false
                    self?.isAlertOccurred = true
                }
            }
            .store(in: &cancellables)
    }
    
    func removeAllNotifications() {
        // FCM의 경우 서버에서 스케줄된 알림 취소 요청
        cancelServerNotifications()
        
        // 로컬 대기 중인 알림도 제거
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func openSettings() {
        fcmService.openSettings()
    }
}

// MARK: - Private Methods
private extension FCMNotificationManager {
    
    func checkNotificationStatus() {
        fcmService.checkNotificationPermission()
        
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isNotificationAuthorized = settings.authorizationStatus == .authorized
                
                if settings.authorizationStatus == .denied && self?.isToggleOn == true {
                    self?.isAlertOccurred = true
                    self?.isToggleOn = false
                }
            }
        }
    }
    
    func handleToggleChange() {
        if isToggleOn {
            requestNotiAuthorization()
        } else {
            removeAllNotifications()
        }
    }
    
    func scheduleNotificationTime() {
        guard isToggleOn && isNotificationAuthorized else { return }
        
        // 서버에 알림 시간 전송 (실제 구현에서는 API 호출)
        sendNotificationScheduleToServer()
        
        // 로컬 백업 알림도 설정 (FCM 실패 시를 대비)
        scheduleLocalBackupNotification()
    }
    
    func sendTokenToServer(_ token: String?) {
        guard let token = token else { return }
        
        // TODO: 실제 서버 API 호출
        print("Sending FCM token to server: \(token)")
        
        // 예시: 서버에 토큰 전송
        // NetworkService.shared.sendFCMToken(token) { result in
        //     // Handle result
        // }
    }
    
    func sendNotificationScheduleToServer() {
        guard let fcmToken = fcmService.fcmToken else { return }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        
        // TODO: 서버에 스케줄 정보 전송
        print("Scheduling notification at \(components.hour ?? 0):\(components.minute ?? 0)")
        
        // 예시: 서버에 스케줄 전송
        // let scheduleData = [
        //     "fcmToken": fcmToken,
        //     "hour": components.hour ?? 0,
        //     "minute": components.minute ?? 0,
        //     "timezone": TimeZone.current.identifier
        // ]
        // NetworkService.shared.scheduleNotification(scheduleData) { result in
        //     // Handle result
        // }
    }
    
    func cancelServerNotifications() {
        guard let fcmToken = fcmService.fcmToken else { return }
        
        // TODO: 서버에 알림 취소 요청
        print("Canceling server notifications for token: \(fcmToken)")
        
        // 예시: 서버에 취소 요청
        // NetworkService.shared.cancelNotifications(fcmToken) { result in
        //     // Handle result
        // }
    }
    
    func scheduleLocalBackupNotification() {
        // FCM 실패 시를 대비한 로컬 백업 알림
        let content = UNMutableNotificationContent()
        
        let localizedContent = fcmService.getLocalizedNotificationContent()
        content.title = localizedContent.title
        content.body = localizedContent.body
        content.sound = UNNotificationSound.default
        content.userInfo = ["source": "local_backup"]
        
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "backup_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling backup notification: \(error.localizedDescription)")
            } else {
                print("Backup notification scheduled successfully")
            }
        }
    }
    
    func handleReceivedNotification(_ notification: FCMNotification) {
        // 알림 수신 시 처리 로직
        print("FCM Notification received: \(notification.title)")
        
        // 필요시 UI 업데이트 또는 데이터 갱신
        DispatchQueue.main.async {
            // 예: 새로운 단어 데이터 업데이트
            if let wordData = notification.data["todayWord"] as? String,
               let definitionData = notification.data["todayDefinition"] as? String {
                UserDefaults.shared.set(wordData, forKey: "TodayWord")
                UserDefaults.shared.set(definitionData, forKey: "TodayWordDefinition")
            }
        }
    }
    
    func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        // 알림 탭 시 처리 로직
        print("FCM Notification tapped")
        
        // 특정 화면으로 이동하거나 상태 업데이트
        if let deepLink = userInfo["deepLink"] as? String {
            // 딥링크 처리는 FCMService에서 이미 처리됨
            print("Deep link from notification: \(deepLink)")
        }
    }
}

// MARK: - Migration Helper (기존 코드와의 호환성)
extension FCMNotificationManager {
    
    /// 기존 addNotification 메서드와 호환성을 위한 메서드
    /// FCM으로 마이그레이션 후에는 실제로 서버 스케줄링을 사용
    func addNotification(with time: Date) {
        self.notificationTime = time
    }
    
    /// 기존 코드에서 사용하던 저장된 단어 데이터 접근
    var storedWord: String? {
        return UserDefaults.shared.string(forKey: "TodayWord")
    }
    
    var storedDefinition: String? {
        return UserDefaults.shared.string(forKey: "TodayWordDefinition")
    }
}
