//
//  WorkEntry.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import Foundation
import SwiftData

@Model
class WorkEntry {
    var date: Date
    var manUnit: Double
    var wage: Int
    var mealAllowance: Int
    var lodgingAllowance: Int
    var transportAllowance: Int
    var dayType: DayType
    var weatherCondition: WeatherCondition
    var workTag: WorkTag?
    var memo: String
    var isPaid: Bool
    var site: Site?
    
    init(
        date: Date,
        manUnit: Double = 1.0,
        wage: Int = 0,
        mealAllowance: Int = 0,
        lodgingAllowance: Int = 0,
        transportAllowance: Int = 0,
        dayType: DayType = .weekday,
        weatherCondition: WeatherCondition = .sunny,
        workTag: WorkTag? = nil,
        memo: String = "",
        isPaid: Bool = false,
        site: Site? = nil
    ) {
        self.date = date
        self.manUnit = manUnit
        self.wage = wage
        self.mealAllowance = mealAllowance
        self.lodgingAllowance = lodgingAllowance
        self.transportAllowance = transportAllowance
        self.dayType = dayType
        self.weatherCondition = weatherCondition
        self.workTag = workTag
        self.memo = memo
        self.isPaid = isPaid
        self.site = site
    }
    
    // MARK: - 계산
    var taxableAmount: Int {
        Int(manUnit * Double(wage))
    }
    
    var allowanceTotal: Int {
        mealAllowance + lodgingAllowance + transportAllowance
    }
    
    var tax: Int {
        let base = taxableAmount - 150_000
        guard base > 0 else { return 0 }
        let incomeTax = Int(Double(base) * 0.06 * 0.45)
        let localTax = Int(Double(incomeTax) * 0.1)
        return incomeTax + localTax
    }
    
    var netAmount: Int {
        taxableAmount - tax + allowanceTotal
    }
}
