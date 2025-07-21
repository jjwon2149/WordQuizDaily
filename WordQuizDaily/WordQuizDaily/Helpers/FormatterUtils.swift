//
//  FormatterUtils.swift
//  WordQuizDaily
//
//  Created on 2025-07-18.
//  다국어 지원을 위한 포맷터 유틸리티
//

import Foundation

// MARK: - 포맷터 유틸리티
struct FormatterUtils {
    
    // MARK: - 날짜 포맷터
    
    /// 현재 로케일에 맞는 날짜 포맷터
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    /// 시간 포맷터
    static var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    /// 커스텀 날짜 포맷터
    /// - Parameter format: 날짜 포맷 문자열
    /// - Returns: 설정된 DateFormatter
    static func customDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = format
        return formatter
    }
    
    /// 일본어 연호 지원 날짜 포맷터
    static var japaneseDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .japanese)
        formatter.dateStyle = .medium
        return formatter
    }
    
    // MARK: - 숫자 포맷터
    
    /// 기본 숫자 포맷터
    static var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter
    }
    
    /// 퍼센트 포맷터
    static var percentFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }
    
    /// 점수 포맷터
    static var scoreFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    // MARK: - 통화 포맷터
    
    /// 현재 로케일의 통화 포맷터
    static var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        return formatter
    }
    
    /// 특정 통화 포맷터
    /// - Parameter currencyCode: 통화 코드 (예: "USD", "JPY", "KRW")
    /// - Returns: 설정된 NumberFormatter
    static func currencyFormatter(for currencyCode: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter
    }
    
    // MARK: - 측정 포맷터
    
    /// 길이 측정 포맷터
    static var lengthFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.current
        formatter.unitStyle = .medium
        return formatter
    }
    
    /// 무게 측정 포맷터
    static var weightFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.current
        formatter.unitStyle = .medium
        return formatter
    }
    
    // MARK: - 헬퍼 메서드
    
    /// 현재 로케일에 맞는 날짜 문자열 반환
    /// - Parameter date: 포맷할 날짜
    /// - Returns: 로케일에 맞는 날짜 문자열
    static func localizedDateString(from date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    /// 현재 로케일에 맞는 시간 문자열 반환
    /// - Parameter date: 포맷할 날짜
    /// - Returns: 로케일에 맞는 시간 문자열
    static func localizedTimeString(from date: Date) -> String {
        return timeFormatter.string(from: date)
    }
    
    /// 현재 로케일에 맞는 숫자 문자열 반환
    /// - Parameter number: 포맷할 숫자
    /// - Returns: 로케일에 맞는 숫자 문자열
    static func localizedNumberString(from number: NSNumber) -> String {
        return numberFormatter.string(from: number) ?? "\(number)"
    }
    
    /// 점수 문자열 반환
    /// - Parameter score: 점수
    /// - Returns: 포맷된 점수 문자열
    static func localizedScoreString(from score: Int) -> String {
        return scoreFormatter.string(from: NSNumber(value: score)) ?? "\(score)"
    }
    
    /// 퍼센트 문자열 반환
    /// - Parameter value: 퍼센트 값 (0.0 ~ 1.0)
    /// - Returns: 포맷된 퍼센트 문자열
    static func localizedPercentString(from value: Double) -> String {
        return percentFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value * 100))%"
    }
    
    /// 상대적 시간 문자열 반환 (예: "2시간 전", "1일 전")
    /// - Parameter date: 기준 날짜
    /// - Returns: 상대적 시간 문자열
    static func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// 언어별 특수 포맷 처리
    /// - Parameter text: 원본 텍스트
    /// - Returns: 언어별 특수 포맷이 적용된 텍스트
    static func localizedSpecialFormat(text: String) -> String {
        let currentLanguage: String
        if #available(iOS 16, *) {
            currentLanguage = Locale.current.language.languageCode?.identifier ?? "ko"
        } else {
            currentLanguage = Locale.current.languageCode ?? "ko"
        }
        
        switch currentLanguage {
        case "ja":
            // 일본어: 전각 숫자 사용 (필요시)
            return text.replacingOccurrences(of: "0", with: "０")
                      .replacingOccurrences(of: "1", with: "１")
                      .replacingOccurrences(of: "2", with: "２")
                      .replacingOccurrences(of: "3", with: "３")
                      .replacingOccurrences(of: "4", with: "４")
                      .replacingOccurrences(of: "5", with: "５")
                      .replacingOccurrences(of: "6", with: "６")
                      .replacingOccurrences(of: "7", with: "７")
                      .replacingOccurrences(of: "8", with: "８")
                      .replacingOccurrences(of: "9", with: "９")
        case "ko":
            // 한국어: 특별한 포맷 없음
            return text
        case "en":
            // 영어: 특별한 포맷 없음
            return text
        default:
            return text
        }
    }
}

// MARK: - Date Extension
extension Date {
    
    /// 현재 로케일에 맞는 날짜 문자열
    var localizedDateString: String {
        return FormatterUtils.localizedDateString(from: self)
    }
    
    /// 현재 로케일에 맞는 시간 문자열
    var localizedTimeString: String {
        return FormatterUtils.localizedTimeString(from: self)
    }
    
    /// 상대적 시간 문자열
    var relativeTimeString: String {
        return FormatterUtils.relativeTimeString(from: self)
    }
}

// MARK: - Number Extension
extension Int {
    
    /// 현재 로케일에 맞는 숫자 문자열
    var localizedString: String {
        return FormatterUtils.localizedNumberString(from: NSNumber(value: self))
    }
    
    /// 점수 형태의 문자열
    var localizedScoreString: String {
        return FormatterUtils.localizedScoreString(from: self)
    }
}

// MARK: - Double Extension
extension Double {
    
    /// 현재 로케일에 맞는 숫자 문자열
    var localizedString: String {
        return FormatterUtils.localizedNumberString(from: NSNumber(value: self))
    }
    
    /// 퍼센트 형태의 문자열
    var localizedPercentString: String {
        return FormatterUtils.localizedPercentString(from: self)
    }
}
