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
    /// 세금 공제 방식 (기존 데이터는 기본값 = 일용직 원천징수)
    var taxModeRaw: String = TaxMode.withholding.rawValue
    /// 기록 생성 시각 — 같은 날 여러 건의 정렬용
    var createdAt: Date = Date.now

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
        site: Site? = nil,
        taxMode: TaxMode = .withholding
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
        self.taxModeRaw = taxMode.rawValue
        self.createdAt = .now
    }

    var taxMode: TaxMode {
        get { TaxMode(rawValue: taxModeRaw) ?? .withholding }
        set { taxModeRaw = newValue.rawValue }
    }

    // MARK: - 계산
    var taxableAmount: Int {
        PayCalculator.taxable(manUnit: manUnit, wage: wage)
    }

    var allowanceTotal: Int {
        mealAllowance + lodgingAllowance + transportAllowance
    }

    var taxBreakdown: TaxBreakdown {
        PayCalculator.tax(taxable: taxableAmount, mode: taxMode)
    }

    var tax: Int {
        taxBreakdown.total
    }

    var netAmount: Int {
        PayCalculator.net(taxable: taxableAmount, tax: taxBreakdown, allowances: allowanceTotal)
    }
}
