//
//  HolidayService.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import Foundation

struct HolidayService {
    
    // 2025 ~ 2026 법정 공휴일 (근로자의 날 포함)
    private static let holidays: Set<String> = [
        // 2025
        "2025-01-01", // 신정
        "2025-01-28", // 설날 연휴
        "2025-01-29", // 설날
        "2025-01-30", // 설날 연휴
        "2025-03-01", // 삼일절
        "2025-05-01", // 근로자의 날
        "2025-05-05", // 어린이날
        "2025-05-06", // 어린이날 대체공휴일
        "2025-06-06", // 현충일
        "2025-08-15", // 광복절
        "2025-10-03", // 개천절
        "2025-10-05", // 추석 연휴
        "2025-10-06", // 추석
        "2025-10-07", // 추석 연휴
        "2025-10-08", // 대체공휴일
        "2025-10-09", // 한글날
        "2025-12-25", // 크리스마스
        // 2026
        "2026-01-01", // 신정
        "2026-02-16", // 설날 연휴
        "2026-02-17", // 설날
        "2026-02-18", // 설날 연휴
        "2026-03-01", // 삼일절
        "2026-03-02", // 대체공휴일
        "2026-05-01", // 근로자의 날
        "2026-05-05", // 어린이날
        "2026-05-25", // 석가탄신일
        "2026-06-06", // 현충일
        "2026-08-15", // 광복절
        "2026-08-17", // 대체공휴일
        "2026-09-24", // 추석 연휴
        "2026-09-25", // 추석
        "2026-09-26", // 추석 연휴
        "2026-10-03", // 개천절
        "2026-10-05", // 대체공휴일
        "2026-10-09", // 한글날
        "2026-12-25", // 크리스마스
    ]
    
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()
    
    // 날짜 → DayType 자동 판별
    static func dayType(for date: Date) -> DayType {
        let key = formatter.string(from: date)
        if holidays.contains(key) { return .holiday }
        
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 1: return .holiday   // 일요일
        case 7: return .saturday  // 토요일
        default: return .weekday
        }
    }
    
    static func isHoliday(_ date: Date) -> Bool {
        dayType(for: date) == .holiday
    }
}
