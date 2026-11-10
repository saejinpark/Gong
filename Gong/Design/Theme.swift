//
//  Theme.swift
//  Gong
//
//  공수장 디자인 토큰.
//
//  콘셉트 "현장": 안전 조끼의 형광 노랑, 먹물 같은 차콜(잉크), 작업일지 종이색.
//  공(工)은 공수의 공이자 H빔 단면 — 아이콘이 여기서 나온다. 일한 날은 도장처럼 찍힌다.
//  장갑 낀 손, 햇빛 아래 화면, 돋보기가 필요한 눈이 기본값:
//  큰 숫자, 높은 대비, 넉넉한 터치 영역, 시스템 글자 크기 존중.
//

import SwiftUI
import UIKit

enum Theme {

    // MARK: - 색
    enum Colors {

        /// 라이트/다크에서 다른 색
        private static func dynamic(light: UIColor, dark: UIColor) -> Color {
            Color(UIColor { trait in trait.userInterfaceStyle == .dark ? dark : light })
        }
        private static func hex(_ v: UInt32) -> UIColor {
            UIColor(red: CGFloat((v >> 16) & 0xFF) / 255,
                    green: CGFloat((v >> 8) & 0xFF) / 255,
                    blue: CGFloat(v & 0xFF) / 255, alpha: 1)
        }

        /// 형광 노랑 — 면(fill)으로만 쓴다. 위에는 항상 잉크색 글자.
        static let brand = Color(hex(0xFFC400))
        /// 브랜드 면 위의 글자·아이콘
        static let onBrand = Color(hex(0x1C1C1E))
        /// 옅은 노랑 배경 (선택 상태, 안내 카드)
        static let brandSoft = dynamic(light: hex(0xFFC400).withAlphaComponent(0.18), dark: hex(0xFFC400).withAlphaComponent(0.22))
        /// 흰 바탕 위 글자·아이콘·링크용 액센트 (라이트는 진한 호박색, 다크는 노랑). Assets AccentColor와 동일.
        static let accentText = Color.accentColor

        /// 잉크 — 히어로 카드와 주요 숫자의 바탕
        static let ink = dynamic(light: hex(0x1C1C1E), dark: hex(0x26262B))
        /// 잉크 위 본문 글자
        static let onInk = Color.white
        /// 잉크 위 강조 숫자
        static let onInkAccent = Color(hex(0xFFC400))
        static let onInkMuted = Color.white.opacity(0.7)

        /// 돈이 들어옴·완료·정상 1공수
        static let positive = dynamic(light: hex(0x1E8E4A), dark: hex(0x3DD172))
        /// 못 받음·주의·태그
        static let warning = dynamic(light: hex(0xD9771B), dark: hex(0xFF9F3D))
        /// 세금·삭제·공휴일·2공수 이상
        static let danger = dynamic(light: hex(0xD93025), dark: hex(0xFF6B5E))
        /// 토요일·1.5공수
        static let saturday = dynamic(light: hex(0x2563EB), dark: hex(0x6FA3FF))
        static let holiday = danger

        /// 화면 바탕 — 작업일지 종이 / 깊은 밤
        static let background = dynamic(light: hex(0xF4F1EA), dark: hex(0x0F0F11))
        /// 카드
        static let surface = dynamic(light: hex(0xFFFFFF), dark: hex(0x1C1C1F))
        /// 카드 안의 한 단계 들어간 면
        static let surfaceInset = dynamic(light: hex(0xEFEBE2), dark: hex(0x2A2A2E))
        static let separator = dynamic(light: hex(0xE4DFD4), dark: hex(0x303036))

        static let textPrimary = dynamic(light: hex(0x1C1C1E), dark: hex(0xF2F2F5))
        static let textSecondary = dynamic(light: hex(0x6B675F), dark: hex(0xA6A6AE))
        static let textTertiary = dynamic(light: hex(0xB5B0A6), dark: hex(0x5C5C64))

        /// 공수 크기 색: 쉼 → 반공수 → 정상 → 잔업 → 특근
        static func manUnit(_ value: Double) -> Color {
            switch value {
            case ..<0.1:   return textTertiary
            case 0.1..<1:  return textSecondary
            case 1..<1.5:  return positive
            case 1.5..<2:  return saturday
            default:       return danger
            }
        }

        /// 현장 구분 색 (8개). Site.colorIndex로 고른다.
        static let sitePalette: [Color] = [
            Color(hex(0xF59E0B)), // 호박
            Color(hex(0x3B82F6)), // 파랑
            Color(hex(0x22A06B)), // 초록
            Color(hex(0xDB4C8C)), // 분홍
            Color(hex(0x8B5CF6)), // 보라
            Color(hex(0x14A3B3)), // 청록
            Color(hex(0xC2703A)), // 벽돌
            Color(hex(0x6B7280)), // 회색
        ]

        /// 배경색 위에 흰 글자보다 잉크 글자가 더 잘 읽히면 true (WCAG 대비비 비교)
        static func prefersDarkText(on color: Color) -> Bool {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
                .getRed(&r, green: &g, blue: &b, alpha: &a)
            func lin(_ c: CGFloat) -> CGFloat { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
            let lum = 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
            let inkLum: CGFloat = 0.0118  // #1C1C1E
            let contrastWhite = 1.05 / (lum + 0.05)
            let contrastInk = (lum + 0.05) / (inkLum + 0.05)
            return contrastInk > contrastWhite
        }

        static func site(_ index: Int) -> Color {
            sitePalette[((index % sitePalette.count) + sitePalette.count) % sitePalette.count]
        }
    }

    // MARK: - 글꼴
    /// 전부 둥근 체(SF Rounded). 숫자는 고정폭(monospacedDigit)으로.
    enum Fonts {
        static let heroAmount = Font.system(.largeTitle, design: .rounded).weight(.heavy)
        static let screenTitle = Font.system(.largeTitle, design: .rounded).weight(.heavy)
        static let amountLarge = Font.system(.title2, design: .rounded).weight(.bold)
        static let amount = Font.system(.body, design: .rounded).weight(.bold)
        static let amountSmall = Font.system(.subheadline, design: .rounded).weight(.bold)

        static let title = Font.system(.title3, design: .rounded).weight(.bold)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .rounded)
        static let label = Font.system(.subheadline, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let caption2 = Font.system(.caption2, design: .rounded)

        static let badge = Font.system(.caption2, design: .rounded).weight(.heavy)
        static let dayNumber = Font.system(.subheadline, design: .rounded).weight(.semibold)
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
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let lg: CGFloat = 22
        static let pill: CGFloat = 999
    }

    /// 최소 터치 영역 (HIG 44pt)
    static let minTapTarget: CGFloat = 44
}
