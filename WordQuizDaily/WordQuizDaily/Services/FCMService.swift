//
//  FCMService.swift
//  WordQuizDaily
//
//  Created by 정종원 on FCM Migration
//

import Foundation
import Firebase
import FirebaseMessaging
import Combine
import UserNotifications

// MARK: - FCM 알림 모델
struct FCMNotification {
    let title: String
    let body: String
    let data: [String: Any]
    let date: Date
    
    init(userInfo: [AnyHashable: Any]) {
        self.title = userInfo["gcm.notification.title"] as? String ?? ""
        self.body = userInfo["gcm.notification.body"] as? String ?? ""
        self.data = userInfo as? [String: Any] ?? [:]
        self.date = Date()
    }
}

// MARK: - FCM 토큰 상태
enum FCMTokenStatus {
    case loading
    case success(String)
    case failure(Error)
}

// MARK: - FCM 서비스
class FCMService: ObservableObject {
    static let shared = FCMService()
    
    // MARK: - Publishers
    @Published var fcmToken: String?
    @Published var tokenStatus: FCMTokenStatus = .loading
    @Published var isNotificationAuthorized: Bool = false
    
    // Combine Subjects
    private let fcmTokenSubject = PassthroughSubject<String?, Never>()
    private let notificationReceivedSubject = PassthroughSubject<FCMNotification, Never>()
    private let notificationTappedSubject = PassthroughSubject<[AnyHashable: Any], Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNotificationObservers()
        requestFCMToken()
    }
    
    // MARK: - Public Publishers
    var fcmTokenPublisher: AnyPublisher<String?, Never> {
        fcmTokenSubject.eraseToAnyPublisher()
    }
    
    var notificationReceivedPublisher: AnyPublisher<FCMNotification, Never> {
        notificationReceivedSubject.eraseToAnyPublisher()
    }
    
    var notificationTappedPublisher: AnyPublisher<[AnyHashable: Any], Never> {
        notificationTappedSubject.eraseToAnyPublisher()
    }
}

// MARK: - FCM Token Management
extension FCMService {
    
    func requestFCMToken() {
        Messaging.messaging().token { [weak self] token, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching FCM registration token: \(error)")
                    self?.tokenStatus = .failure(error)
                } else if let token = token {
                    print("FCM registration token: \(token)")
                    self?.fcmToken = token
                    self?.tokenStatus = .success(token)
                    self?.fcmTokenSubject.send(token)
                    
                    // UserDefaults에 저장
                    UserDefaults.standard.set(token, forKey: "FCMToken")
                }
            }
        }
    }
    
    func updateFCMToken(_ token: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.fcmToken = token
            if let token = token {
                self?.tokenStatus = .success(token)
                self?.fcmTokenSubject.send(token)
                UserDefaults.standard.set(token, forKey: "FCMToken")
            }
        }
    }
    
    func getStoredFCMToken() -> String? {
        return UserDefaults.standard.string(forKey: "FCMToken")
    }
}

// MARK: - Notification Handling
extension FCMService {
    
    private func setupNotificationObservers() {
        // FCM 토큰 업데이트 감지
        NotificationCenter.default.publisher(for: Notification.Name("FCMToken"))
            .compactMap { $0.userInfo?["token"] as? String }
            .sink { [weak self] token in
                self?.updateFCMToken(token)
            }
            .store(in: &cancellables)
        
        // 딥링크 처리
        NotificationCenter.default.publisher(for: Notification.Name("HandleDeepLink"))
            .compactMap { $0.object as? String }
            .sink { [weak self] deepLink in
                self?.handleDeepLink(deepLink)
            }
            .store(in: &cancellables)
    }
    
    func handleNotificationReceived(userInfo: [AnyHashable: Any]) {
        let notification = FCMNotification(userInfo: userInfo)
        
        DispatchQueue.main.async { [weak self] in
            self?.notificationReceivedSubject.send(notification)
        }
        
        // 알림 수신 로그
        print("FCM Notification received: \(notification.title) - \(notification.body)")
    }
    
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.notificationTappedSubject.send(userInfo)
        }
        
        print("FCM Notification tapped: \(userInfo)")
    }
    
    private func handleDeepLink(_ deepLink: String) {
        print("Handling deep link: \(deepLink)")
        
        // 딥링크에 따른 화면 이동 로직
        switch deepLink {
        case "quiz":
            // 퀴즈 화면으로 이동
            NotificationCenter.default.post(name: Notification.Name("NavigateToQuiz"), object: nil)
        case "home":
            // 홈 화면으로 이동
            NotificationCenter.default.post(name: Notification.Name("NavigateToHome"), object: nil)
        case "todayWord":
            // 오늘의 단어 화면으로 이동
            NotificationCenter.default.post(name: Notification.Name("NavigateToTodayWord"), object: nil)
        default:
            break
        }
    }
}

// MARK: - Permission Management
extension FCMService {
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isNotificationAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermission() -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { promise in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
                promise(.success(granted))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func openSettings() {
        if let bundle = Bundle.main.bundleIdentifier,
           let settings = URL(string: UIApplication.openSettingsURLString + bundle) {
            if UIApplication.shared.canOpenURL(settings) {
                UIApplication.shared.open(settings)
            }
        }
    }
}

// MARK: - 다국어 지원
extension FCMService {
    
    func getLocalizedNotificationContent(for language: String = Locale.current.language.languageCode?.identifier ?? "ko") -> (title: String, body: String) {
        
        let todayWord = UserDefaults.shared.string(forKey: "TodayWord") ?? "단어"
        let todayDefinition = UserDefaults.shared.string(forKey: "TodayWordDefinition") ?? "뜻"
        
        switch language {
        case "ko":
            return (
                title: "오늘의 단어: \(todayWord)",
                body: "뜻: \(todayDefinition)"
            )
        case "en":
            return (
                title: "Word of the Day: \(todayWord)",
                body: "Meaning: \(todayDefinition)"
            )
        default:
            return (
                title: "오늘의 단어: \(todayWord)",
                body: "뜻: \(todayDefinition)"
            )
        }
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    static let shared = UserDefaults(suiteName: "group.wordQuizWidget") ?? UserDefaults.standard
}
