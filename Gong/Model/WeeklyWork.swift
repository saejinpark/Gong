//
//  WeeklyWork.swift
//  Gong
//
//  Created by 박세진 on 3/1/25.
//
import Foundation
import SwiftData

@Model
class WeeklyWork {
    var weekNumber: Int
    var belongingMonth: MonthlyWork?  // 🔗 속하는 월 (기존 `parentMonthlyWork` → `belongingMonth`)
    @Relationship(deleteRule: .cascade) var dailyWorks: [DailyWork] = []  // 🔗 연결된 DailyWork들

    init(weekNumber: Int, belongingMonth: MonthlyWork? = nil, dailyWorks: [DailyWork] = []) {
        self.weekNumber = weekNumber
        self.belongingMonth = belongingMonth
        self.dailyWorks = dailyWorks
    }
    /// 📅 주간 총 공수
    var totalHours: Double {
        dailyWorks.reduce(0) { $0 + $1.hours }
    }

    /// 💰 주간 총 수입
    var totalIncome: Int {
        dailyWorks.reduce(0) { $0 + Int($1.dailyWage * $1.hours * (1 - $1.taxPercentage / 100)) }
    }

    /// 🏠 주간 총 숙박비
    var totalAccommodationCost: Int {
        dailyWorks.reduce(0) { $0 + Int($1.accommodationCost) }
    }
    
    var totalMealCost: Int {
        dailyWorks.reduce(0) { $0 + Int($1.mealCost) }
    }
    
    var netIncome: Int {
        totalIncome - totalAccommodationCost - totalMealCost
    }
}
