//
//  Calendardfas.swift
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
}
