//
//  TaxMode.swift
//  Gong
//
//  공제(세금) 방식. 현장마다 떼는 방식이 달라서 현장별 기본값 + 기록별 저장.
//

import Foundation

enum TaxMode: String, Codable, CaseIterable, Identifiable {
    /// 일용근로소득 원천징수: (일당 − 15만원) × 6% × (1 − 55%) = 2.7% + 지방소득세 10%
    case withholding
    /// 사업소득(프리랜서) 3.3% 공제: 소득세 3% + 지방소득세 0.3%
    case business
    /// 세금 공제 없음 (현금 지급 등)
    case none

    var id: String { rawValue }

    var title: String {
        switch self {
        case .withholding: return String(localized: "일용직 세금")
        case .business:    return String(localized: "3.3% 공제")
        case .none:        return String(localized: "공제 없음")
        }
    }

    var shortTitle: String {
        switch self {
        case .withholding: return String(localized: "일용직")
        case .business:    return String(localized: "3.3%")
        case .none:        return String(localized: "없음")
        }
    }

    var detail: String {
        switch self {
        case .withholding:
            return String(localized: "하루 15만원까지 비과세, 넘는 금액의 2.7%에 지방소득세 10%를 더해 뗍니다. 세금이 1,000원 미만이면 떼지 않아요(소액부징수).")
        case .business:
            return String(localized: "일당 전체의 3.3%(소득세 3% + 지방소득세 0.3%)를 뗍니다. 사업소득으로 신고하는 현장에서 써요.")
        case .none:
            return String(localized: "세금을 떼지 않고 일당을 그대로 받는 경우예요.")
        }
    }
}
