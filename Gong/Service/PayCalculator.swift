//
//  PayCalculator.swift
//  Gong
//
//  일당 → 세금 → 실수령액 계산을 한곳에서. (소득세법 §47의2, §59, §86 참고)
//

import Foundation

struct TaxBreakdown: Equatable {
    var incomeTax: Int
    var localTax: Int
    var total: Int { incomeTax + localTax }

    static let zero = TaxBreakdown(incomeTax: 0, localTax: 0)
}

enum PayCalculator {

    /// 일용근로소득 1일 근로소득공제
    static let dailyDeduction = 150_000
    /// 소득세율 6% × (1 − 세액공제 55%) = 2.7%
    static let withholdingRate = 0.06 * 0.45
    /// 소액부징수: 소득세가 1,000원 미만이면 징수하지 않음
    static let smallTaxThreshold = 1_000

    /// 10원 미만 절사 (국세징수법 상 원단위 절사 관행)
    static func truncateToTen(_ value: Double) -> Int {
        guard value > 0 else { return 0 }
        return Int(value / 10) * 10
    }

    static func tax(taxable: Int, mode: TaxMode) -> TaxBreakdown {
        guard taxable > 0 else { return .zero }
        switch mode {
        case .none:
            return .zero

        case .business:
            let income = truncateToTen(Double(taxable) * 0.03)
            let local = truncateToTen(Double(income) * 0.1)
            return TaxBreakdown(incomeTax: income, localTax: local)

        case .withholding:
            let base = taxable - dailyDeduction
            guard base > 0 else { return .zero }
            let income = truncateToTen(Double(base) * withholdingRate)
            guard income >= smallTaxThreshold else { return .zero }
            let local = truncateToTen(Double(income) * 0.1)
            return TaxBreakdown(incomeTax: income, localTax: local)
        }
    }

    static func taxable(manUnit: Double, wage: Int) -> Int {
        Int((manUnit * Double(wage)).rounded())
    }

    static func net(taxable: Int, tax: TaxBreakdown, allowances: Int) -> Int {
        taxable - tax.total + allowances
    }
}
