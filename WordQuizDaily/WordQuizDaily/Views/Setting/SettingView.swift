//
//  SettingView.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import SwiftUI

struct SettingView: View {
    
    @EnvironmentObject var notificationManager: FCMNotificationManager
    @State private var isShowTermsOfService = false
    @State private var isShowAppVersion = false
    @State private var isShowCustomerService = false
    @State private var isShowFeedback = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // AdMob 배너 광고 - 최상단 위치
                AdMobBannerView()
                    .padding(.top, 10)
            }
            
            VStack(alignment: .leading, spacing: 10){
                Form {
                    //알림 설정 ex) 푸시알림, 효과음
                    Section(header: Text(LocalizedStringKey(LocalizationKeys.Settings.notificationSection)).font(.caption)) {
                        //NotiView
                        NotiView()
                        
                    }
                    //개인정보 보호 설정...?
                    Section(header: Text(LocalizedStringKey(LocalizationKeys.Settings.otherSection)).font(.caption)) {
                        Button(LocalizedStringKey(LocalizationKeys.Settings.termsOfService)) {
                            isShowTermsOfService = true
                        }
                        .foregroundStyle(.black)
                        .sheet(isPresented: self.$isShowTermsOfService, content: {
                            TermsofServiceView()
                        })
                        
                        Button(LocalizedStringKey(LocalizationKeys.Settings.appVersion)) {
                            isShowAppVersion = true
                        }
                        .foregroundStyle(.black)
                        .sheet(isPresented: self.$isShowAppVersion, content: {
                            AppVersionView()
                        })
                        
                        Button(LocalizedStringKey(LocalizationKeys.Settings.customerService)) {
                            isShowCustomerService = true
                        }
                        .foregroundStyle(.black)
                        .sheet(isPresented: self.$isShowCustomerService, content: {
                            CustomerServiceView()
                        })
                        
                        Button(LocalizedStringKey(LocalizationKeys.Settings.feedback)) {
                            isShowFeedback = true
                        }
                        .foregroundStyle(.black)
                        .sheet(isPresented: self.$isShowFeedback, content: {
                            FeedBackView()
                        })
                        
                    }
                    
                }
            }
            .navigationTitle(LocalizedStringKey(LocalizationKeys.Settings.title))
            
        } //NavigationStack
    }
}
//MARK: - NotiView
struct NotiView: View {
    
    @EnvironmentObject var notificationManager: FCMNotificationManager
    @State private var showDatePicker = false
    
    var body: some View {
        VStack(alignment: .leading){
            
            HStack {
                Text(LocalizedStringKey(LocalizationKeys.Settings.pushNotification))
                if notificationManager.isToggleOn {
                    DatePicker("", selection: $notificationManager.notificationTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.graphical)
//                        .onTapGesture {
//                            showDatePicker.toggle()
//                        }
                }
                Toggle("", isOn: $notificationManager.isToggleOn)
                    .onChange(of: notificationManager.isToggleOn) { oldValue, newValue in
                        if newValue {
                            showDatePicker = true
                        } else {
                            showDatePicker = false
                        }
                    }
            } //HStack
            .alert(isPresented: $notificationManager.isAlertOccurred) {
                //알림 설정이 꺼져있을 경우 설정창으로 이동
                Alert(
                    title: Text(LocalizedStringKey(LocalizationKeys.Notification.alertTitle)), 
                    message: Text(LocalizedStringKey(LocalizationKeys.Notification.alertMessage)), 
                    primaryButton: .cancel(Text(LocalizedStringKey(LocalizationKeys.Notification.alertGoToSettings)), action: {
                        notificationManager.openSettings()
                    }), 
                    secondaryButton: .destructive(Text(LocalizedStringKey(LocalizationKeys.Common.cancel)))
                )
            }
            .onTapGesture {
                if notificationManager.isToggleOn {
                    showDatePicker.toggle()
                }
            }
        } //VStack
    }
}

//MARK: - 서비스 약관
struct TermsofServiceView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(LocalizationKeys.TermsOfService.title))
                .font(.title)
                .padding(.bottom, 10)
            
            ScrollView {
                Text(LocalizedStringKey(LocalizationKeys.TermsOfService.content))
                    .padding()
            }
        }
        .padding()
    }
}

//MARK: - 앱 버전
struct AppVersionView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(LocalizationKeys.AppVersion.title))
                .font(.title)
                .padding(.bottom, 10)
            
            Text(LocalizedStringKey(LocalizationKeys.AppVersion.currentVersion))
                .padding(.bottom, 5)
            
            Text(LocalizedStringKey(LocalizationKeys.AppVersion.updateHistory))
                .padding()
        }
        .padding()
    }
}

//MARK: - 고객 지원
struct CustomerServiceView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(LocalizationKeys.CustomerService.title))
                .font(.title)
                .padding(.bottom, 10)
            
            Text(LocalizedStringKey(LocalizationKeys.CustomerService.contactInfo))
                .padding()
            
            Text(LocalizedStringKey(LocalizationKeys.CustomerService.faq))
                .font(.headline)
                .padding(.top, 10)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(LocalizationKeys.CustomerService.faqPassword))
                Text(LocalizedStringKey(LocalizationKeys.CustomerService.faqPasswordAnswer))
                    .padding(.bottom, 10)
                
                Text(LocalizedStringKey(LocalizationKeys.CustomerService.faqNotWorking))
                Text(LocalizedStringKey(LocalizationKeys.CustomerService.faqNotWorkingAnswer))
            }
            .padding()
        }
        .padding()
    }
}

//MARK: - 피드백
struct FeedBackView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(LocalizationKeys.Feedback.title))
                .font(.title)
                .padding(.bottom, 10)
            
            Text(LocalizedStringKey(LocalizationKeys.Feedback.content))
                .padding(.bottom, 10)
            
            Text(LocalizedStringKey(LocalizationKeys.Feedback.contactInfo))
                .padding()
        }
        .padding()
    }
}

#Preview("한국어") {
    SettingView()
        .environmentObject(FCMNotificationManager())
        .previewLocale("ko")
}

#Preview("English") {
    SettingView()
        .environmentObject(FCMNotificationManager())
        .previewLocale("en")
}

#Preview("日本語") {
    SettingView()
        .environmentObject(FCMNotificationManager())
        .previewLocale("ja")
}
