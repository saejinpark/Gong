//
//  Formatting.swift
//  Gong
//
//  공수·금액·날짜 표기를 앱 전체에서 통일. 모든 문구는 현지화된다.
//

import SwiftUI

enum Format {

    /// 지금 앱이 한국어로 표시되는지
    static var isKorean: Bool {
        (Bundle.main.preferredLocalizations.first ?? "ko").hasPrefix("ko")
    }

    // MARK: - 숫자

    /// 1 → "1", 1.5 → "1.5", 0.33 → "0.33"
    static func manUnit(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        return String(format: "%g", rounded)
    }

    /// 1.5 → "1.5공수" (언어별 단위: gongsu / 工 / công …)
    static func gongsu(_ value: Double) -> String {
        String(localized: "\(manUnit(value))공수", comment: "공수 수량. %@는 1, 1.5 같은 숫자")
    }

    /// 180000 → "180,000원"
    static func won(_ value: Int) -> String {
        String(localized: "\(value.formatted())원", comment: "원화 금액. %@는 쉼표가 들어간 숫자")
    }

    /// +/- 부호가 붙은 금액
    static func signedWon(_ value: Int) -> String {
        value >= 0 ? "+" + won(value) : "-" + won(-value)
    }

    /// 근무일수 "8일"
    static func days(_ count: Int) -> String {
        String(localized: "\(count)일", comment: "일수. 예: 8일")
    }

    /// 건수 "2건"
    static func count(_ count: Int) -> String {
        String(localized: "\(count)건", comment: "개수(기록 건수). 예: 2건")
    }

    /// 현장이 지정되지 않은 기록의 이름
    static var unassignedSite: String { String(localized: "현장 미지정") }

    // MARK: - 날짜

    private static func formatter(korean: String, template: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale.current
        if isKorean {
            f.locale = Locale(identifier: "ko_KR")
            f.dateFormat = korean
        } else {
            f.setLocalizedDateFormatFromTemplate(template)
        }
        return f
    }

    /// "2026년 11월" / "November 2026"
    static let monthTitle = formatter(korean: "yyyy년 M월", template: "yMMMM")
    /// "11월" / "November" (달력 헤더)
    static let monthName = formatter(korean: "M월", template: "LLLL")
    /// "11월 3일 (화)" / "Tue, Nov 3"
    static let dayTitle = formatter(korean: "M월 d일 (E)", template: "MMMdE")
    /// "2026년 11월 3일" / "November 3, 2026"
    static let fullDate = formatter(korean: "yyyy년 M월 d일", template: "yMMMMd")
    /// "11/3(화)" / "Tue 11/3"
    static let shortDay = formatter(korean: "M/d(E)", template: "MdE")

    static let fileStamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// 년/월 휠의 월 이름 ("11월" / "November")
    static func monthWheelLabel(_ month: Int) -> String {
        if isKorean { return "\(month)월" }
        let f = DateFormatter()
        f.locale = Locale.current
        let names = f.standaloneMonthSymbols ?? []
        return names.indices.contains(month - 1) ? names[month - 1].localizedCapitalized : "\(month)"
    }

    /// 월요일부터 시작하는 짧은 요일 이름 (월 화 … 일 / Mon Tue … Sun)
    static var weekdaySymbolsMondayFirst: [String] {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = isKorean ? Locale(identifier: "ko_KR") : Locale.current
        let s = cal.shortStandaloneWeekdaySymbols   // 일요일부터
        return Array(s[1...]) + [s[0]]
    }
}

extension Color {
    /// 공수 크기 색 — Theme 토큰으로 위임
    static func manUnit(_ value: Double) -> Color { Theme.Colors.manUnit(value) }
}
