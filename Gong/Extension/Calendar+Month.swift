//
//  Calendar+Month.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import Foundation

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }

    /// 월요일 시작 기준, 해당 날짜가 속한 주의 월요일
    func startOfWeekMonday(for date: Date) -> Date {
        let weekdayOffset = (component(.weekday, from: date) - 2 + 7) % 7
        return self.date(byAdding: .day, value: -weekdayOffset, to: startOfDay(for: date)) ?? date
    }
}
