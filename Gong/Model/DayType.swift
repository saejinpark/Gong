//
//  DayType.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import Foundation

enum DayType: String, Codable, CaseIterable {
    case weekday  = "평일"
    case saturday = "토요일"
    case holiday  = "공휴일"

    /// 화면 표시용 (rawValue는 저장값이라 바꾸지 않는다)
    var title: String {
        switch self {
        case .weekday:  return String(localized: "평일")
        case .saturday: return String(localized: "토요일")
        case .holiday:  return String(localized: "공휴일")
        }
    }
}
