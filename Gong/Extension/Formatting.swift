//
//  Formatting.swift
//  Gong
//
//  공수·금액·날짜 표기를 앱 전체에서 통일.
//

import SwiftUI

enum Format {
    /// 1 → "1", 1.5 → "1.5", 0.33 → "0.33"
    static func manUnit(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        return String(format: "%g", rounded)
    }

    /// 180000 → "180,000원"
    static func won(_ value: Int) -> String {
        "\(value.formatted())원"
    }

    /// +/- 부호가 붙은 금액
    static func signedWon(_ value: Int) -> String {
        value >= 0 ? "+\(value.formatted())원" : "-\((-value).formatted())원"
    }

    private static let koLocale = Locale(identifier: "ko_KR")

    static let monthTitle: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy년 M월"
        f.locale = koLocale
        return f
    }()

    static let dayTitle: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M월 d일 (E)"
        f.locale = koLocale
        return f
    }()

    static let fullDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy년 M월 d일"
        f.locale = koLocale
        return f
    }()

    static let shortDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/d(E)"
        f.locale = koLocale
        return f
    }()

    static let fileStamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmm"
        f.locale = koLocale
        return f
    }()
}

extension Color {
    /// 공수 크기 색 — Theme 토큰으로 위임
    static func manUnit(_ value: Double) -> Color { Theme.Colors.manUnit(value) }
}
