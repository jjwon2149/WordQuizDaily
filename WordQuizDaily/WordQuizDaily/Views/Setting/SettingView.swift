//
//  NotificationView.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import SwiftUI

struct SettingView: View {
    
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var isShowTermsOfService = false
    @State private var isShowAppVersion = false
    @State private var isShowCustomerService = false
    @State private var isShowFeedback = false
    
    var body: some View {
        NavigationStack {
            
            VStack(alignment: .leading, spacing: 10){
                Form{
                    //알림 설정 ex) 푸시알림, 효과음
                    Section(header: Text("알림 설정").font(.caption)) {
                        //NotiView
                        NotiView()
                            .padding()
                    }
                    //개인정보 보호 설정...?
                    Section(header: Text("기타 설정").font(.caption)) {
                        Button("서비스 약관") {
                            isShowTermsOfService = true
                        }
                        .foregroundStyle(.black)
                        .sheet(isPresented: self.$isShowTermsOfService, content: {
                            TermsofServiceView()
                        })
                        
                        Button("앱 버전") {
                            isShowAppVersion = true
                        }
                        .foregroundStyle(.black)
                        .sheet(isPresented: self.$isShowAppVersion, content: {
                            AppVersionView()
                        })
                        
                        Button("고객 지원") {
                            isShowCustomerService = true
                        }
                        .foregroundStyle(.black)
                        .sheet(isPresented: self.$isShowCustomerService, content: {
                            CustomerServiceView()
                        })
                        
                        Button("피드백") {
                            isShowFeedback = true
                        }
                        .foregroundStyle(.black)
                        .sheet(isPresented: self.$isShowFeedback, content: {
                            FeedBackView()
                        })
                    }
                    
                }
                
                
            }
            .navigationTitle("Setting")
            
        } //NavigationStack
    }
}
//MARK: - NotiView
struct NotiView: View {
    
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showDatePicker = false
    
    var body: some View {
        VStack(alignment: .leading){
            
            HStack(spacing: 10) {
                Text("푸시 알림")
                if notificationManager.isToggleOn {
                    DatePicker("", selection: $notificationManager.notificationTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.graphical)
                        .onTapGesture {
                            showDatePicker.toggle()
                        }
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
                Alert(
                    title: Text("Notification Alert"),
                    message: Text("notificationManager.alertMessage"),
                    dismissButton: .default(Text("OK"))
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
        VStack {
            Text("TermsofServiceView")
        }
    }
}

//MARK: - 앱 버전
struct AppVersionView: View {
    
    var body: some View {
        VStack {
            Text("AppVersionView")
        }
    }
}

//MARK: - 고객 지원
struct CustomerServiceView: View {
    
    var body: some View {
        VStack {
            Text("CustomerServiceView")
        }
    }
}

//MARK: - 피드백
struct FeedBackView: View {
    
    var body: some View {
        VStack {
            Text("FeedBackView")
        }
    }
}

#Preview {
    SettingView()
        .environmentObject(NotificationManager())
}
