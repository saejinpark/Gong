//
//  Components.swift
//  Gong
//
//  공수장 공용 컴포넌트. 화면은 이 조각들을 조립해서 만든다.
//

import SwiftUI

// MARK: - 카드

/// 그룹 배경 위에 올라가는 기본 카드
struct GCard<Content: View>: View {
    var padding: CGFloat = Theme.Spacing.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
    }
}

/// 이번 달 실수령처럼 "가장 먼저 봐야 할 숫자" 하나를 크게 보여주는 카드
struct HeroCard<Footer: View>: View {
    let title: String
    let amount: Int
    var caption: String? = nil
    var tint: Color = Theme.Colors.brand
    @ViewBuilder var footer: () -> Footer

    init(title: String, amount: Int, caption: String? = nil, tint: Color = Theme.Colors.brand,
         @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }) {
        self.title = title
        self.amount = amount
        self.caption = caption
        self.tint = tint
        self.footer = footer
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .font(Theme.Fonts.label)
                .foregroundStyle(Theme.Colors.onBrand.opacity(0.85))
            Text(Format.won(amount))
                .font(Theme.Fonts.heroAmount)
                .foregroundStyle(Theme.Colors.onBrand)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            if let caption {
                Text(caption)
                    .font(Theme.Fonts.label)
                    .foregroundStyle(Theme.Colors.onBrand.opacity(0.9))
            }
            footer()
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [tint, tint.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}

/// 작은 통계 타일 (이번 주 / 이번 달 등)
struct StatTile: View {
    let title: String
    let value: String
    var detail: String? = nil
    var tint: Color = Theme.Colors.brand

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(value)
                .font(Theme.Fonts.amountLarge)
                .foregroundStyle(tint)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            if let detail {
                Text(detail)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 글자

/// 금액 — 항상 고정폭 숫자, 부호별 색
struct MoneyText: View {
    enum Style { case plain, positive, negative, emphasis }

    let value: Int
    var style: Style = .plain
    var font: Font = Theme.Fonts.amountSmall

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
    }

    private var text: String {
        switch style {
        case .positive: return "+\(Format.won(value))"
        case .negative: return "-\(Format.won(value))"
        default: return Format.won(value)
        }
    }

    private var color: Color {
        switch style {
        case .plain: return Theme.Colors.textSecondary
        case .positive: return Theme.Colors.positive
        case .negative: return value > 0 ? Theme.Colors.danger : Theme.Colors.textSecondary
        case .emphasis: return Theme.Colors.brand
        }
    }
}

/// 설정 화면 등에서 쓰는 "라벨 — 값" 한 줄
struct KeyValueRow: View {
    let label: String
    let value: String
    var valueColor: Color = Theme.Colors.textSecondary
    var bold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.Fonts.label)
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(bold ? Theme.Fonts.amountSmall : Theme.Fonts.label)
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 배지 · 칩

/// 달력 셀과 기록 행에 쓰는 공수 배지
struct ManUnitBadge: View {
    let value: Double
    var compact: Bool = false

    var body: some View {
        Text(compact ? Format.manUnit(value) : "\(Format.manUnit(value))공수")
            .font(compact ? Theme.Fonts.badge : Theme.Fonts.amountSmall)
            .foregroundStyle(compact ? Theme.Colors.onBrand : Theme.Colors.manUnit(value))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: compact ? .infinity : nil)
            .padding(.vertical, compact ? 2 : 0)
            .background(compact ? Theme.Colors.manUnit(value) : .clear,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            .accessibilityLabel("\(Format.manUnit(value))공수")
    }
}

/// 입금 상태
struct PaidBadge: View {
    let isPaid: Bool

    var body: some View {
        Label(isPaid ? "입금완료" : "미입금", systemImage: isPaid ? "checkmark.circle.fill" : "clock")
            .font(Theme.Fonts.caption2.weight(.semibold))
            .foregroundStyle(isPaid ? Theme.Colors.positive : Theme.Colors.warning)
            .labelStyle(.titleAndIcon)
    }
}

/// 태그·세금 방식 같은 짧은 라벨
struct TagChip: View {
    let text: String
    var tint: Color = Theme.Colors.warning
    var filled: Bool = true

    var body: some View {
        Text(text)
            .font(Theme.Fonts.caption2.weight(.semibold))
            .foregroundStyle(filled ? Theme.Colors.onBrand : tint)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 3)
            .background(filled ? tint : tint.opacity(0.15), in: Capsule())
            .lineLimit(1)
    }
}

/// 현장 색 점
struct SiteDot: View {
    let colorIndex: Int
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(Theme.Colors.site(colorIndex))
            .frame(width: size, height: size)
    }
}

/// 현장 이름 + 색 점
struct SiteLabel: View {
    let site: Site?
    var font: Font = Theme.Fonts.label

    var body: some View {
        HStack(spacing: 6) {
            if let site {
                SiteDot(colorIndex: site.colorIndex)
            }
            Text(site?.name ?? "현장 미지정")
                .font(font)
                .lineLimit(1)
        }
    }
}

// MARK: - 버튼

/// 화면에서 가장 중요한 한 가지 행동 (오늘 1공수 기록 등)
struct BigActionButton: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String = "plus.circle.fill"
    var tint: Color = Theme.Colors.inverseSurface
    var foreground: Color = Theme.Colors.onInverse
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.brand)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Fonts.headline)
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Fonts.caption)
                            .opacity(0.85)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .opacity(0.7)
            }
            .foregroundStyle(foreground)
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(tint, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// 카드 안의 보조 버튼 (선택 상태 표시 가능)
struct ChoiceButton: View {
    let title: String
    var subtitle: String? = nil
    var isSelected: Bool = false
    var tint: Color = Theme.Colors.brand
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(Theme.Fonts.amount)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Fonts.caption2)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(isSelected ? Theme.Colors.onBrand : Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
            .padding(.vertical, Theme.Spacing.xs)
            .background(isSelected ? tint : Theme.Colors.surfaceInset,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 섹션 · 빈 화면

struct SectionTitle: View {
    let text: String
    var trailing: AnyView? = nil

    init(_ text: String) {
        self.text = text
    }

    init<T: View>(_ text: String, @ViewBuilder trailing: () -> T) {
        self.text = text
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack {
            Text(text)
                .font(Theme.Fonts.title)
            Spacer()
            trailing
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.xl)
        .padding(.bottom, Theme.Spacing.sm)
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    var message: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.textTertiary)
            Text(title)
                .font(Theme.Fonts.headline)
            if let message {
                Text(message)
                    .font(Theme.Fonts.label)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.Colors.onBrand)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.brand, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }
}

// MARK: - 기록 행 (달력·현장·정산 공용)

struct EntryRow: View {
    let entry: WorkEntry
    var showsDate: Bool = true
    var showsSite: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: 6) {
                    if showsDate {
                        Text(Format.shortDay.string(from: entry.date))
                            .font(Theme.Fonts.headline)
                            .monospacedDigit()
                    }
                    if showsSite {
                        SiteLabel(site: entry.site, font: showsDate ? Theme.Fonts.label : Theme.Fonts.headline)
                    }
                    Text(entry.weatherCondition.emoji)
                        .font(Theme.Fonts.caption)
                }
                HStack(spacing: 6) {
                    if let tag = entry.workTag {
                        TagChip(text: tag.rawValue)
                    }
                    if !entry.memo.isEmpty {
                        Text(entry.memo)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                ManUnitBadge(value: entry.manUnit)
                MoneyText(value: entry.netAmount, style: .plain, font: Theme.Fonts.caption)
                PaidBadge(isPaid: entry.isPaid)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}
