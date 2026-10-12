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
import LearningCore

class FCMNotificationManager: ObservableObject {
    @Published var isAlertOccurred = false
    @Published var isNotificationAuthorized = false
    @Published var alertTitleKey = LocalizationKeys.Notification.alertTitle
    @Published var alertMessageKey = LocalizationKeys.Notification.alertMessage

    @Published var notificationTime: Date {
        didSet {
            guard !isInitializing else { return }
            persistNotificationTime()
            synchronizeSchedule()
        }
    }

    @Published var isToggleOn: Bool {
        didSet {
            guard !isInitializing, isToggleOn != oldValue else { return }
            defaults.set(isToggleOn, forKey: Self.notificationToggleKey)
            handleToggleChange()
        }
    }

    private static let notificationToggleKey = "hasUserAgreedNoti"
    private static let notificationHourKey = "dailyLearningReminderHour"
    private static let notificationMinuteKey = "dailyLearningReminderMinute"
    private static let legacyRequestIdentifier = "backup_notification"

    private let fcmService: FCMService
    private let notificationCenter: UNUserNotificationCenter
    private let defaults: UserDefaults
    private var permissionRequestID: UUID?
    private var authorizationRefreshID: UUID?
    private var scheduleRevision = UUID()
    private var isScheduleAddInFlight = false
    private var isInitializing = true
    private var cancellables = Set<AnyCancellable>()

    init(
        fcmService: FCMService = .shared,
        notificationCenter: UNUserNotificationCenter = .current(),
        defaults: UserDefaults = .standard
    ) {
        self.fcmService = fcmService
        self.notificationCenter = notificationCenter
        self.defaults = defaults
        self.isToggleOn = defaults.bool(forKey: Self.notificationToggleKey)

        self.notificationTime = Self.restoredNotificationTime(from: defaults)

        isInitializing = false
        persistNotificationTime()
        setupAuthorizationBinding()
        refreshAuthorizationAndSchedule()
    }

    private func setupAuthorizationBinding() {
        fcmService.$isNotificationAuthorized
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authorized in
                self?.isNotificationAuthorized = authorized
            }
            .store(in: &cancellables)
    }
}

// MARK: - Public Methods (기존 NotificationManager 인터페이스 유지)
extension FCMNotificationManager {
    func requestNotiAuthorization() {
        let requestID = UUID()
        authorizationRefreshID = nil
        permissionRequestID = requestID

        fcmService.requestNotificationPermission()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] granted in
                guard let self, self.permissionRequestID == requestID else { return }
                self.permissionRequestID = nil

                // The toggle may have been switched off while the system prompt was visible.
                guard self.isToggleOn else {
                    self.removeScheduledReminder()
                    return
                }

                self.isNotificationAuthorized = granted
                self.fcmService.isNotificationAuthorized = granted
                if granted {
                    self.synchronizeSchedule()
                } else {
                    self.disableToggleForUnavailableAuthorization(showAlert: true)
                }
            }
            .store(in: &cancellables)
    }

    func removeAllNotifications() {
        permissionRequestID = nil
        scheduleRevision = UUID()
        removeScheduledReminder()
    }

    func openSettings() {
        fcmService.openSettings()
    }

    /// Reconciles the saved preference with current system permission and locale.
    /// Call whenever the app becomes active so Settings changes and language changes
    /// are reflected in the repeating local reminder.
    func refreshAuthorizationAndSchedule() {
        let refreshID = UUID()
        authorizationRefreshID = refreshID
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self,
                      self.authorizationRefreshID == refreshID,
                      self.permissionRequestID == nil else { return }
                self.authorizationRefreshID = nil
                self.restoreNotificationTimeForCurrentTimeZone()
                let authorized = Self.isAuthorized(settings.authorizationStatus)
                self.isNotificationAuthorized = authorized
                self.fcmService.isNotificationAuthorized = authorized

                if self.isToggleOn && !authorized {
                    self.disableToggleForUnavailableAuthorization(
                        showAlert: settings.authorizationStatus == .denied
                    )
                } else {
                    self.synchronizeSchedule()
                }
            }
        }
    }

    func addNotification(with time: Date) {
        notificationTime = time
    }

    var storedWord: String? {
        UserDefaults.shared.string(forKey: "TodayWord")
    }

    var storedDefinition: String? {
        UserDefaults.shared.string(forKey: "TodayWordDefinition")
    }
}

private extension FCMNotificationManager {
    static func isAuthorized(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func restoredNotificationTime(from defaults: UserDefaults) -> Date {
        let now = Date()
        let calendar = Calendar.current
        guard defaults.object(forKey: notificationHourKey) != nil,
              defaults.object(forKey: notificationMinuteKey) != nil else {
            return now
        }

        let hour = defaults.integer(forKey: notificationHourKey)
        let minute = defaults.integer(forKey: notificationMinuteKey)
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
    }

    func persistNotificationTime() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        defaults.set(components.hour ?? 0, forKey: Self.notificationHourKey)
        defaults.set(components.minute ?? 0, forKey: Self.notificationMinuteKey)
    }

    func restoreNotificationTimeForCurrentTimeZone() {
        isInitializing = true
        notificationTime = Self.restoredNotificationTime(from: defaults)
        isInitializing = false
    }

    func handleToggleChange() {
        if isToggleOn {
            requestNotiAuthorization()
        } else {
            permissionRequestID = nil
            synchronizeSchedule()
        }
    }

    func disableToggleForUnavailableAuthorization(showAlert: Bool) {
        permissionRequestID = nil
        if isToggleOn {
            isToggleOn = false
        } else {
            removeScheduledReminder()
        }
        if showAlert {
            alertTitleKey = LocalizationKeys.Notification.alertTitle
            alertMessageKey = LocalizationKeys.Notification.alertMessage
            isAlertOccurred = true
        }
    }

    func synchronizeSchedule() {
        scheduleRevision = UUID()
        let revision = scheduleRevision

        guard NotificationSchedulePolicy.shouldSchedule(
            toggleOn: isToggleOn,
            authorized: isNotificationAuthorized
        ) else {
            removeScheduledReminder()
            return
        }

        // Wait for the current add to finish, then apply only the newest desired state.
        guard !isScheduleAddInFlight else { return }

        let content = UNMutableNotificationContent()
        let localizedContent = fcmService.getLocalizedReminderContent()
        content.title = localizedContent.title
        content.body = localizedContent.body
        content.sound = .default
        content.userInfo = ["source": "daily_learning_reminder", "deepLink": "home"]

        let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationSchedulePolicy.requestIdentifier,
            content: content,
            trigger: trigger
        )

        isScheduleAddInFlight = true
        removeScheduledReminder()
        notificationCenter.add(request) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isScheduleAddInFlight = false

                guard self.scheduleRevision == revision else {
                    self.synchronizeSchedule()
                    return
                }

                if error != nil {
                    self.disableToggleAfterSchedulingFailure()
                }
            }
        }
    }

    func disableToggleAfterSchedulingFailure() {
        if isToggleOn {
            isToggleOn = false
        } else {
            removeScheduledReminder()
        }
        alertTitleKey = "notification.scheduleError.title"
        alertMessageKey = "notification.scheduleError.message"
        isAlertOccurred = true
    }

    func removeScheduledReminder() {
        let identifiers = [
            NotificationSchedulePolicy.requestIdentifier,
            Self.legacyRequestIdentifier
        ]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
