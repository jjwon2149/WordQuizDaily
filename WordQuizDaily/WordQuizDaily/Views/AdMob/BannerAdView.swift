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
    let onLoadStateChange: (Bool) -> Void
    
    init(adUnitID: String? = nil, onLoadStateChange: @escaping (Bool) -> Void = { _ in }) {
        #if DEBUG
        // 디버그 모드에서는 테스트 광고 ID 사용
        self.adUnitID = "ca-app-pub-3940256099942544/2435281174"
        #else
        self.adUnitID = adUnitID ?? Bundle.main.object(forInfoDictionaryKey: "ADMOB_BANNER_AD_UNIT_ID") as? String ?? "ca-app-pub-3940256099942544/2435281174"
        #endif
        self.onLoadStateChange = onLoadStateChange
    }
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator
        
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

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoadStateChange: onLoadStateChange)
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        private let onLoadStateChange: (Bool) -> Void

        init(onLoadStateChange: @escaping (Bool) -> Void) {
            self.onLoadStateChange = onLoadStateChange
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            DispatchQueue.main.async {
                self.onLoadStateChange(true)
            }
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            DispatchQueue.main.async {
                self.onLoadStateChange(false)
            }
        }
    }
}

struct AdMobBannerView: View {
    let adUnitID: String
    @State private var isBannerSlotVisible = false
    @State private var availableWidth: CGFloat = 0
    
    init(adUnitID: String? = nil) {
        #if DEBUG
        // 디버그 모드에서는 테스트 광고 ID 사용
        self.adUnitID = "ca-app-pub-3940256099942544/2435281174"
        #else
        self.adUnitID = adUnitID ?? Bundle.main.object(forInfoDictionaryKey: "ADMOB_BANNER_AD_UNIT_ID") as? String ?? "ca-app-pub-3940256099942544/2435281174"
        #endif
    }
    
    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width >= AdSizeBanner.size.width {
                BannerAdView(adUnitID: adUnitID) { isLoaded in
                    isBannerSlotVisible = isLoaded
                }
                .frame(width: AdSizeBanner.size.width, height: AdSizeBanner.size.height)
                .frame(maxWidth: .infinity)
                .opacity(isBannerSlotVisible ? 1 : 0)
            }
            Color.clear
                .allowsHitTesting(false)
                .onAppear { availableWidth = proxy.size.width }
                .onChange(of: proxy.size.width) { _, width in
                    availableWidth = width
                    if width < AdSizeBanner.size.width { isBannerSlotVisible = false }
                }
        }
        .frame(height: availableWidth >= AdSizeBanner.size.width ? (isBannerSlotVisible ? AdSizeBanner.size.height : 0) : 0)
        .clipped()
        .accessibilityHidden(!(isBannerSlotVisible) || availableWidth < AdSizeBanner.size.width)
        .padding(.top, isBannerSlotVisible && availableWidth >= AdSizeBanner.size.width ? 8 : 0)
    }
}

#Preview {
    AdMobBannerView()
}
