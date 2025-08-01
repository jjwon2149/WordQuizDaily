//
//  BannerAdView.swift
//  WordQuizDaily
//
//  Created by GitHub Copilot on AdMob Integration
//

import SwiftUI
import GoogleMobileAds
import UIKit

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    
    init(adUnitID: String? = nil) {
        #if DEBUG
        // 디버그 모드에서는 테스트 광고 ID 사용
        self.adUnitID = "ca-app-pub-3940256099942544/2435281174"
        #else
        self.adUnitID = adUnitID ?? Bundle.main.object(forInfoDictionaryKey: "ADMOB_BANNER_AD_UNIT_ID") as? String ?? "ca-app-pub-3940256099942544/2435281174"
        #endif
    }
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            bannerView.rootViewController = window.rootViewController
        }
        
        bannerView.load(Request())
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // 업데이트가 필요한 경우 여기에 구현
    }
}

struct AdMobBannerView: View {
    let adUnitID: String
    
    init(adUnitID: String? = nil) {
        #if DEBUG
        // 디버그 모드에서는 테스트 광고 ID 사용
        self.adUnitID = "ca-app-pub-3940256099942544/2435281174"
        #else
        self.adUnitID = adUnitID ?? Bundle.main.object(forInfoDictionaryKey: "ADMOB_BANNER_AD_UNIT_ID") as? String ?? "ca-app-pub-3940256099942544/2435281174"
        #endif
    }
    
    var body: some View {
        BannerAdView(adUnitID: adUnitID)
            .frame(width: 320, height: 50) // 표준 배너 크기
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
}

#Preview {
    AdMobBannerView()
}
