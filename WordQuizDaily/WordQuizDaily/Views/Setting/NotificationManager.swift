//
//  NotificationManager.swift
//  WordQuizDaily
//
//  Created by 정종원 on 5/26/24.
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    @Published var isAlertOccurred: Bool = false
    @Published var notificationTime: Date = Date() {
        didSet {
            //set notification with the time
            removeAllNotifications()
            addNotification(with: notificationTime)
        }
    }
    @Published var isToggleOn: Bool = UserDefaults.standard.bool(forKey: "hasUserAgreedNoti") {
        didSet {
            if isToggleOn {
                UserDefaults.standard.set(true, forKey: "hasUserAgreedNoti")
                UserDefaults.standard.synchronize()
                requestNotiAuthorization()
            } else {
                UserDefaults.standard.set(false, forKey: "hasUserAgreedNoti")
                UserDefaults.standard.synchronize()
                removeAllNotifications()
            }
        }
    }
    
    func requestNotiAuthorization() {
        //noti 설정 가져오기
        //상태에 따라 다른 액션 수행
        notificationCenter.getNotificationSettings { settings in
            //승인이 되어있지 않은 경우 request
            if settings.authorizationStatus != .authorized {
                self.notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if let error = error {
                        print("notificationCenter Error: \(error.localizedDescription)")
                    }
                    
                    //노티피케이션 최초 승인
                    if granted {
                        self.addNotification(with: self.notificationTime)
                    } else {
                        //노티피케이션 최초 거부
                        DispatchQueue.main.async {
                            self.isToggleOn = false
                        }
                    }
                    
                }
            }
            
            //Notification이 거부되어 있는경우 alert
            if settings.authorizationStatus == .denied {
                //알림 띄운 뒤 설정 창으로 이동
                DispatchQueue.main.async {
                    self.isAlertOccurred = true
                }
            }
        }
    }
    
    func removeAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    //time에 반복되는 노티피케이션 추가
    func addNotification(with time: Date) {
        //이 객체를 사용하여 알림의 제목과 메시지, 재생할 사운드 또는 앱의 배지에 할당할 값을 지정할 수 있습니다.
        let content = UNMutableNotificationContent()
        
        //TODO: 오늘의 단어 데이터와 연결하기
        content.title = "오늘의 단어: ??"
        content.subtitle = "오늘의 단어뜻 들어갈곳"
        content.sound = UNNotificationSound.default
        
        let dateComponent = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: true)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            }
        }
    }
        
}
