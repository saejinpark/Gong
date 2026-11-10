//
//  WeatherCondition.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import Foundation

enum WeatherCondition: String, Codable, CaseIterable {
    case sunny  = "맑음"
    case cloudy = "흐림"
    case rainy  = "비"
    case snowy  = "눈"
    case storm  = "폭풍"
    
    var emoji: String {
        switch self {
        case .sunny:  return "☀️"
        case .cloudy: return "☁️"
        case .rainy:  return "🌧️"
        case .snowy:  return "🌨️"
        case .storm:  return "⛈️"
        }
    }

    /// 화면 표시용 (rawValue는 저장값이라 바꾸지 않는다)
    var title: String {
        switch self {
        case .sunny:  return String(localized: "맑음")
        case .cloudy: return String(localized: "흐림")
        case .rainy:  return String(localized: "비")
        case .snowy:  return String(localized: "눈")
        case .storm:  return String(localized: "폭풍")
        }
    }
}
