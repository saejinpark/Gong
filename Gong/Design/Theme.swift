//
//  Theme.swift
//  Gong
//
//  공수장 디자인 토큰. 색·글꼴·간격·모서리를 여기서만 정의하고 화면은 토큰만 쓴다.
//  현장에서 장갑 끼고, 햇빛 아래에서, 나이 든 눈으로도 읽히는 것이 목표:
//  큰 숫자, 높은 대비, 넉넉한 터치 영역, 시스템 글자 크기 존중.
//

import SwiftUI

enum Theme {

    // MARK: - 색
    enum Colors {
        /// 브랜드 색 (안전모 주황). Assets의 AccentColor와 같음.
        static let brand = Color.accentColor
        /// 브랜드 색의 옅은 배경 (선택 표시, 강조 카드)
        static let brandSoft = Color.accentColor.opacity(0.14)
        /// 브랜드 위에 올라가는 글자
        static let onBrand = Color.white

        /// 돈이 들어옴·완료
        static let positive = Color(red: 0.20, green: 0.66, blue: 0.33)
        /// 아직 못 받음·주의
        static let warning = Color(red: 0.95, green: 0.55, blue: 0.10)
        /// 세금·삭제·공휴일
        static let danger = Color(red: 0.88, green: 0.24, blue: 0.22)
        /// 토요일
        static let saturday = Color(red: 0.16, green: 0.47, blue: 0.90)
        /// 공휴일·일요일
        static let holiday = danger

        /// 화면 배경 (그룹 리스트 배경과 동일)
        static let background = Color(.systemGroupedBackground)
        /// 카드 배경
        static let surface = Color(.secondarySystemGroupedBackground)
        /// 반전 면 — 히어로 옆에서 브랜드색과 겹치지 않는 주요 행동 버튼용 (라이트=거의 검정, 다크=거의 흰색)
        static let inverseSurface = Color(.label)
        static let onInverse = Color(.systemBackground)
        /// 카드 안의 한 단계 더 들어간 면 (프리셋 버튼 등)
        static let surfaceInset = Color(.tertiarySystemGroupedBackground)
        static let separator = Color(.separator)

        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(.tertiaryLabel)

        /// 공수 크기 색: 쉼 → 반공수 → 정상 → 잔업 → 특근
        static func manUnit(_ value: Double) -> Color {
            switch value {
            case ..<0.1:   return Color(.systemGray2)
            case 0.1..<1:  return Color(.systemGray)
            case 1..<1.5:  return positive
            case 1.5..<2:  return saturday
            default:       return danger
            }
        }

        /// 현장 구분 색 (8개). Site.colorIndex로 고른다.
        static let sitePalette: [Color] = [
            Color(red: 0.96, green: 0.62, blue: 0.04), // 주황
            Color(red: 0.20, green: 0.55, blue: 0.95), // 파랑
            Color(red: 0.20, green: 0.70, blue: 0.45), // 초록
            Color(red: 0.86, green: 0.30, blue: 0.55), // 분홍
            Color(red: 0.55, green: 0.40, blue: 0.90), // 보라
            Color(red: 0.15, green: 0.65, blue: 0.70), // 청록
            Color(red: 0.80, green: 0.45, blue: 0.20), // 갈색
            Color(red: 0.45, green: 0.50, blue: 0.58), // 회색
        ]

        static func site(_ index: Int) -> Color {
            sitePalette[((index % sitePalette.count) + sitePalette.count) % sitePalette.count]
        }
    }

    // MARK: - 글꼴
    /// 숫자는 둥근 고정폭(rounded + monospacedDigit)으로: 금액이 흔들리지 않고 친근하게.
    enum Fonts {
        static let heroAmount = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let amountLarge = Font.system(.title2, design: .rounded).weight(.bold)
        static let amount = Font.system(.body, design: .rounded).weight(.semibold)
        static let amountSmall = Font.system(.subheadline, design: .rounded).weight(.semibold)

        static let title = Font.title3.weight(.bold)
        static let headline = Font.headline
        static let body = Font.body
        static let label = Font.subheadline
        static let caption = Font.caption
        static let caption2 = Font.caption2

        static let badge = Font.system(.caption2, design: .rounded).weight(.bold)
        static let dayNumber = Font.system(.footnote, design: .rounded)
    }

    // MARK: - 간격 · 모서리
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let pill: CGFloat = 999
    }

    /// 최소 터치 영역 (HIG 44pt)
    static let minTapTarget: CGFloat = 44
}
