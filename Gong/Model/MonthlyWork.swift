//
//  MonthlyWork.swift
//  Gong
//
//  Created by 박세진 on 2/27/25.
//

import Foundation
import SwiftData

@Model
class MonthlyWork {
    var year: Int
    var month: Int
    @Relationship(deleteRule: .cascade) var weeklyWorks: [WeeklyWork] = []  // 🔗 연결된 WeeklyWork들

    init(year: Int, month: Int, weeklyWorks: [WeeklyWork] = []) {
        self.year = year
        self.month = month
        self.weeklyWorks = weeklyWorks
    }
    
    func generateWeeklyWork() {
        var weeks: [WeeklyWork] = []
        var currentWeek: [DailyWork] = []
        var weekNumber = 1
        var dayCounter = 1 // ✅ 날짜 카운터

        let calendar = Calendar.current
        let firstDayOfMonth = calendar.date(from: DateComponents(year: self.year, month: self.month, day: 1))!
        let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!
        let totalDays = range.count

        let weekdayIndex = calendar.component(.weekday, from: firstDayOfMonth) - 1  // (일요일 = 0, 월요일 = 1, ..., 토요일 = 6)

        // 🟢 1일 전의 빈 칸을 더미 데이터로 채우기
        for _ in 0..<weekdayIndex {
            let dummyWork = DailyWork(workDate: Date(), dayNumber: 0, hours: 0, dailyWage: 0, taxPercentage: 0, mealCost: 0, accommodationCost: 0, isDummy: true)
            currentWeek.append(dummyWork)
        }

        // 🟢 실제 날짜 데이터 추가
        for day in 1...totalDays {
            let workDate = calendar.date(from: DateComponents(year: self.year, month: self.month, day: day))!
            let dailyWork = DailyWork(workDate: workDate, dayNumber: dayCounter, hours: 0, dailyWage: 0, taxPercentage: 0, mealCost: 0, accommodationCost: 0, isDummy: false)
            currentWeek.append(dailyWork)
            dayCounter += 1

            // ✅ 한 주(7일) 채워지면 WeeklyWork 추가
            if currentWeek.count == 7 {
                weeks.append(WeeklyWork(weekNumber: weekNumber, dailyWorks: currentWeek))
                currentWeek = []
                weekNumber += 1
            }
        }

        // ✅ 마지막 남은 주 추가
        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                let dummyWork = DailyWork(workDate: Date(), dayNumber: currentWeek.count, hours: 0, dailyWage: 0, taxPercentage: 0, mealCost: 0, accommodationCost: 0, isDummy: true)
                currentWeek.append(dummyWork)
            }
            weeks.append(WeeklyWork(weekNumber: weekNumber, dailyWorks: currentWeek))
        }

        self.weeklyWorks = weeks
    }

    
    var totalHours: Double {
        weeklyWorks.reduce(0) { $0 + $1.totalHours }
    }

    /// 💰 월간 총 수입
    var totalIncome: Int {
        weeklyWorks.reduce(0) { $0 + $1.totalIncome }
    }

    /// 🏠 월간 총 숙박비
    var totalAccommodationCost: Int {
        weeklyWorks.reduce(0) { $0 + $1.totalAccommodationCost }
    }
    
    
    var totalMealCost: Int {
        weeklyWorks.reduce(0) { $0 + $1.totalMealCost }
    }
    /// 💰 월간 순수 수입 (총 수입 - 총 숙박비)
    var netIncome: Int {
        totalIncome - totalAccommodationCost - totalMealCost
    }
}
