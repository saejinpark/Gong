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
}
