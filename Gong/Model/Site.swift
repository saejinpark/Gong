//
//  Site.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import Foundation
import SwiftData

@Model
class Site {
    var name: String
    var defaultWage: Int
    var startDate: Date
    var location: String
    var memo: String
    var isActive: Bool
    /// 이 현장의 기본 세금 공제 방식 (기존 데이터는 일용직 원천징수)
    var taxModeRaw: String = TaxMode.withholding.rawValue
    /// 기본 식대 — 공수 입력 시 자동으로 채워짐
    var defaultMealAllowance: Int = 0
    @Relationship(deleteRule: .nullify) var entries: [WorkEntry] = []

    init(
        name: String,
        defaultWage: Int,
        startDate: Date = .now,
        location: String = "",
        memo: String = "",
        isActive: Bool = true,
        taxMode: TaxMode = .withholding,
        defaultMealAllowance: Int = 0
    ) {
        self.name = name
        self.defaultWage = defaultWage
        self.startDate = startDate
        self.location = location
        self.memo = memo
        self.isActive = isActive
        self.taxModeRaw = taxMode.rawValue
        self.defaultMealAllowance = defaultMealAllowance
    }

    var taxMode: TaxMode {
        get { TaxMode(rawValue: taxModeRaw) ?? .withholding }
        set { taxModeRaw = newValue.rawValue }
    }
}
