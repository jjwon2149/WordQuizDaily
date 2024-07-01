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
            
            HStack {
                Text("푸시 알림")
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
                Alert(title:Text("Notification Alert"), message: Text("알림 설정이 꺼져있습니다. 설정에서 알림을 켜주세요."), primaryButton: .cancel(Text("이동"), action: {
                    notificationManager.openSettings()
                }), secondaryButton: .destructive(Text("Cancel")))
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
            Text("서비스 약관")
                .font(.title)
                .padding(.bottom, 10)
            
            ScrollView {
                Text("""
                        최종 수정일: 2024년 07월 01일
                        
                        1. 개요
                        이 서비스 약관("약관")은 WordQuizDaily("앱")의 이용에 관한 법적 조건을 명시합니다. 개인 개발자인 정종원에 의해 제공되며, 사용자는 앱을 다운로드하거나 사용함으로써 이 약관에 동의하는 것으로 간주됩니다.
                        
                        2. 서비스 이용
                        2.1 허용된 사용: 사용자는 앱을 법적 목적으로만 사용해야 합니다. 불법적인 활동이나 당사의 정책을 위반하는 행위는 엄격히 금지됩니다.
                        2.2 제한된 사용: 사용자는 앱을 해킹, 스팸 발송, 바이러스 유포 등의 방식으로 사용할 수 없습니다. 당사는 사용자의 앱 접근을 제한할 권리를 가집니다.
                        
                        3. API 사용
                        3.1 외부 API: 본 앱은 네이버 이미지 검색 API와 우리말샘 단어 검색 API를 사용합니다. 사용자는 해당 API 제공자의 이용 약관을 준수해야 합니다.
                        
                        4. 콘텐츠
                        4.1 사용자 콘텐츠: 사용자는 앱에 업로드하거나 게시한 모든 콘텐츠에 대한 권리를 보유합니다. 그러나 사용자는 당사에 해당 콘텐츠를 앱 내에서 사용할 수 있는 비독점적, 영구적, 취소 불가능한 권리를 부여합니다.
                        4.2 금지된 콘텐츠: 사용자는 명예 훼손, 음란물, 폭력, 증오 발언 등을 포함한 불법적인 콘텐츠를 게시할 수 없습니다.
                        
                        5. 개인정보 보호
                        5.1 개인정보 수집: 본 앱은 로그인이 필요하지 않습니다. 사용자의 개인정보는 수집되지 않으며, 따라서 별도의 개인정보 처리방침은 없습니다.
                        
                        6. 제3자 서비스
                        앱은 제3자 서비스나 콘텐츠를 포함할 수 있습니다. 당사는 제3자 서비스에 대해 책임지지 않으며, 사용자는 해당 제3자 서비스의 약관을 준수해야 합니다.
                        
                        7. 면책 조항
                        앱은 "있는 그대로" 제공되며, 당사는 앱의 정확성, 신뢰성, 완전성에 대해 보증하지 않습니다. 사용자는 앱 사용에 따른 모든 위험을 감수해야 합니다.
                        
                        8. 책임 제한
                        법이 허용하는 최대 한도 내에서, 당사는 앱 사용과 관련된 직간접적 손해에 대해 책임지지 않습니다.
                        
                        9. 약관의 변경
                        당사는 언제든지 이 약관을 수정할 권리를 가집니다. 변경 사항은 앱 내에 게시되며, 사용자는 변경된 약관에 동의하는 것으로 간주됩니다.
                        
                        10. 종료
                        당사는 사용자가 이 약관을 위반하는 경우 언제든지 사전 통보 없이 사용자의 앱 접근을 종료할 수 있습니다.
                        
                        11. 준거법 및 분쟁 해결
                        이 약관은 대한민국 법에 따라 해석되며, 약관과 관련된 모든 분쟁은 대한민국의 법원에 전속 관할권이 있습니다.
                        
                        12. 연락처 정보
                        약관에 관한 질문은 아래 연락처로 문의해 주십시오:
                        
                        정종원
                        이메일: jjwon2149@gmail.com
                        """)
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
            Text("앱 버전")
                .font(.title)
                .padding(.bottom, 10)
            
            Text("현재 버전: 1.0.0")
                .padding(.bottom, 5)
            
            Text("""
                업데이트 내역:
                - 버전 1.0.0: 최초 릴리즈
                """)
            .padding()
        }
        .padding()
    }
}

//MARK: - 고객 지원
struct CustomerServiceView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("고객 지원")
                .font(.title)
                .padding(.bottom, 10)
            
            Text("""
                고객 지원 문의:
                - 이메일: jjwon2149@gmail.com
                """)
            .padding()
            
            Text("자주 묻는 질문")
                .font(.headline)
                .padding(.top, 10)
            
            Text("""
                Q: 비밀번호를 잊어버렸어요.
                A: 이 앱은 로그인이 없는디용
                
                Q: 앱이 제대로 작동하지 않아요.
                A: 앱을 재설치하거나 최신 버전으로 업데이트해보세요. 그래도 문제가 해결되지 않으면 고객 지원에 문의하세요.
                """)
            .padding()
            
            
        }
    }
}

//MARK: - 피드백
struct FeedBackView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("피드백")
                .font(.title)
                .padding(.bottom, 10)
            
            Text("""
                앱 사용 중 불편한 점이나 개선사항이 있다면 언제든지 피드백을 보내주세요. 여러분의 의견은 저희에게 큰 도움이 됩니다.
                
                피드백 보내기:
                - 이메일: jjwon2149@gmail.com
                - 날카로운 지적 해주시면 바로 반영 하겠습니다 ^_^
                """)
            .padding()
        }
    }
}

#Preview {
    SettingView()
        .environmentObject(NotificationManager())
}
