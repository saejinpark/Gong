//
//  DailyWork.swift
//  Gong
//
//  Created by 박세진 on 3/1/25.
//

import Foundation

extension DailyWork {
    static func sampleData() -> DailyWork {
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        
        let workDate = calendar.date(from: DateComponents(year: year, month: month, day: day))!
        return DailyWork(workDate: workDate, dayNumber: 1, hours: 0, dailyWage: 100000, taxPercentage: 10, mealCost: 0, accommodationCost: 20000, isDummy: false)
    }
    
    static func sampleDummyData() -> DailyWork {
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        
        let workDate = calendar.date(from: DateComponents(year: year, month: month, day: day))!
        return DailyWork(workDate: workDate, dayNumber: 1, hours: 0, dailyWage: 0, taxPercentage: 0, mealCost: 0, accommodationCost: 0, isDummy: true)
    }
}
