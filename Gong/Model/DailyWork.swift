//
//  DailyWork.swift
//  Gong
//
//  Created by 박세진 on 2/27/25.
//

import SwiftData
import Foundation


@Model
class DailyWork {
    var workDate: Date
    var dayNumber: Int
    var hours: Double
    var memo: String
    var dailyWage: Double
    var taxPercentage: Double
    var mealCost: Double
    var accommodationCost: Double
    var isDummy: Bool
    var isSelected: Bool = false
    var belongingWeek: WeeklyWork?  // 🔗 속하는 주 (기존 `parentWeeklyWork` → `belongingWeek`)

    init(
        workDate: Date,
        dayNumber: Int,
        hours: Double,
        memo: String = "",
        dailyWage: Double,
        taxPercentage: Double,
        mealCost: Double,
        accommodationCost: Double,
        isDummy: Bool = false,
        belongingWeek: WeeklyWork? = nil
    ) {
        self.workDate = workDate
        self.dayNumber = dayNumber
        self.hours = hours
        self.memo = memo
        self.dailyWage = dailyWage
        self.taxPercentage = taxPercentage
        self.mealCost = mealCost
        self.accommodationCost = accommodationCost
        self.isDummy = isDummy
        self.belongingWeek = belongingWeek
    }
    
    func calculateNetIncome() -> Int {
        let grossIncome = dailyWage * hours // ✅ 공수 × 일급
        let taxAmount = grossIncome * (taxPercentage / 100) // ✅ 세금 계산
        let netIncome = grossIncome - taxAmount - mealCost - accommodationCost // ✅ 세금과 숙박비 제외한 순수 급여
        return Int(netIncome) // ✅ 소수점 버리고 문자열로 변환
    }
}
