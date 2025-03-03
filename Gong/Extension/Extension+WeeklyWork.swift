//
//  WeeklyWork.swift
//  Gong
//
//  Created by 박세진 on 3/1/25.
//

import Foundation

extension WeeklyWork {
    static func sampleData(weekNumber: Int, belongingMonth: MonthlyWork? = nil) -> WeeklyWork {
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)

        var dailyWorks: [DailyWork] = []
        
        // ✅ 해당 주의 시작 날짜 계산 (1주 단위)
        guard let weekStartDate = calendar.date(from: DateComponents(year: year, month: month, day: (weekNumber - 1) * 7 + 1)) else {
            fatalError("Invalid week number for sample data")
        }
        
        for i in 0..<7 {
            guard let workDate = calendar.date(byAdding: .day, value: i, to: weekStartDate) else { continue }
            
            let dailyWork = DailyWork(
                workDate: workDate,
                dayNumber: i,
                hours: Double.random(in: 1...3),
                dailyWage: 100000,
                taxPercentage: 10,
                mealCost: 0,
                accommodationCost: 20000,
                isDummy: false,
                belongingWeek: nil // ✅ 후에 WeeklyWork에 추가될 것이므로 초기값은 nil
            )
            
            dailyWorks.append(dailyWork)
        }
        
        let weeklyWork = WeeklyWork(weekNumber: weekNumber, belongingMonth: belongingMonth, dailyWorks: dailyWorks)
        
        // ✅ DailyWork에 WeeklyWork 연결
        for i in 0..<dailyWorks.count {
            dailyWorks[i].belongingWeek = weeklyWork
        }

        return weeklyWork
    }
}

