//
//  NotificationService.swift
//  WordQuizNotificationServiceExtension
//
//  Created by 정종원 on FCM Migration
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // FCM 알림 커스터마이징
            customizeNotificationContent(bestAttemptContent)
            
            // 이미지 다운로드 (필요시)
            if let imageURLString = bestAttemptContent.userInfo["image_url"] as? String,
               let imageURL = URL(string: imageURLString) {
                downloadImage(from: imageURL) { attachment in
                    if let attachment = attachment {
                        bestAttemptContent.attachments = [attachment]
                    }
                    contentHandler(bestAttemptContent)
                }
            } else {
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // 시간 만료 시 처리
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func customizeNotificationContent(_ content: UNMutableNotificationContent) {
        // 알림 내용 커스터마이징
        
        // 다국어 처리
        let language = Locale.current.language.languageCode?.identifier ?? "ko"
        
        if let wordData = content.userInfo["todayWord"] as? String,
           let definitionData = content.userInfo["todayDefinition"] as? String {
            
            switch language {
            case "ko":
                content.title = "오늘의 단어: \(wordData)"
                content.body = "뜻: \(definitionData)"
            case "en":
                content.title = "Word of the Day: \(wordData)"
                content.body = "Meaning: \(definitionData)"
            default:
                content.title = "오늘의 단어: \(wordData)"
                content.body = "뜻: \(definitionData)"
            }
        }
        
        // 배지 설정
        content.badge = 1
        
        // 사운드 설정
        content.sound = UNNotificationSound.default
        
        // 카테고리 설정 (액션 버튼 등)
        content.categoryIdentifier = "WORD_QUIZ_CATEGORY"
    }
    
    private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                completion(nil)
                return
            }
            
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFile = tempDirectory.appendingPathComponent(url.lastPathComponent)
            
            do {
                try FileManager.default.moveItem(at: localURL, to: tempFile)
                let attachment = try UNNotificationAttachment(identifier: "image", url: tempFile)
                completion(attachment)
            } catch {
                print("Error creating notification attachment: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
}
