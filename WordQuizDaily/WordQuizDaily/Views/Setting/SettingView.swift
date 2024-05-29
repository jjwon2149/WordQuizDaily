//
//  NotificationView.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import SwiftUI

struct SettingView: View {
    
    @EnvironmentObject var notificationManager: NotificationManager
    
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
                        Text("서비스약관")
                        Text("앱버전")
                        Text("고객지원")
                        Text("피드백")
                    }
                    
                    //기타 설정 ex) 서비스약관, 앱버전, 고객지원, 피드백
                    Section(header: Text("기타 설정").font(.caption)) {
                        
                    }
                }
            }
        } //NavigationStack
    }
}
//MARK: - NotiView
struct NotiView: View {
    
    @EnvironmentObject var notificationManager: NotificationManager

    var body: some View {
        VStack(alignment: .leading){
            
            HStack(spacing: 10) {
                Text("푸시 알림")
                if notificationManager.isToggleOn {
                    DatePicker("", selection: $notificationManager.notificationTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.graphical)
                }
                Toggle("", isOn: $notificationManager.isToggleOn)
            } //HStack
            .alert(isPresented: $notificationManager.isAlertOccurred) {
                Alert(
                    title: Text("Notification Alert"),
                    message: Text("notificationManager.alertMessage"),
                    dismissButton: .default(Text("OK"))
                )
            }
        } //VStack
    }
}
#Preview {
    SettingView()
        .environmentObject(NotificationManager())
}
