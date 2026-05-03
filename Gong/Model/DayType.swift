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
}
