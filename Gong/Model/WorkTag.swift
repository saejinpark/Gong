//
//  WorkTag.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import Foundation

enum WorkTag: String, Codable, CaseIterable {
    case rainStop   = "우천중단"
    case earlyLeave = "조기퇴근"
    case absence    = "자진결근"
    case siteIssue  = "현장사정"

    /// 화면 표시용 (rawValue는 저장값이라 바꾸지 않는다)
    var title: String {
        switch self {
        case .rainStop:   return String(localized: "우천중단")
        case .earlyLeave: return String(localized: "조기퇴근")
        case .absence:    return String(localized: "자진결근")
        case .siteIssue:  return String(localized: "현장사정")
        }
    }
}
