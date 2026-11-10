//
//  Components.swift
//  Gong
//
//  공수장 공용 컴포넌트. 화면은 이 조각들을 조립해서 만든다.
//

import SwiftUI

// MARK: - 장식

/// 공사장 안전 띠 — 히어로 카드 윗선, 빈 화면 등에 쓰는 사선 줄무늬
struct HazardStripe: View {
    var height: CGFloat = 6
    var stripe: Color = Theme.Colors.brand
    var gap: Color = Theme.Colors.ink

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(gap))
            let w: CGFloat = size.height * 1.6
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                var p = Path()
                p.move(to: CGPoint(x: x, y: size.height))
                p.addLine(to: CGPoint(x: x + w, y: size.height))
                p.addLine(to: CGPoint(x: x + w + size.height, y: 0))
                p.addLine(to: CGPoint(x: x + size.height, y: 0))
                p.closeSubpath()
                ctx.fill(p, with: .color(stripe))
                x += w * 2
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - 카드

/// 바탕 위에 올라가는 기본 카드
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

/// 가장 먼저 봐야 할 숫자 하나를 잉크 바탕에 노랑으로 크게.
struct HeroCard<Footer: View>: View {
    enum Style {
        case ink
        case color(Color)
    }

    let title: String
    let amount: Int
    var caption: String? = nil
    var style: Style = .ink
    @ViewBuilder var footer: () -> Footer

    init(title: String, amount: Int, caption: String? = nil, style: Style = .ink,
         @ViewBuilder footer: @escaping () -> Footer) {
        self.title = title
        self.amount = amount
        self.caption = caption
        self.style = style
        self.footer = footer
    }

    private var background: Color {
        if case .color(let c) = style { return c }
        return Theme.Colors.ink
    }
    /// 밝은 현장 색(호박·노랑 등) 위에서는 잉크 글자, 어두운 색 위에서는 흰 글자
    private var isLightBackground: Bool {
        if case .color(let c) = style { return Theme.Colors.prefersDarkText(on: c) }
        return false
    }
    private var textColor: Color { isLightBackground ? Theme.Colors.onBrand : Theme.Colors.onInk }
    private var amountColor: Color {
        if case .color = style { return textColor }
        return Theme.Colors.onInkAccent
    }
    private var stripeColor: Color {
        isLightBackground ? Theme.Colors.onBrand.opacity(0.85) : Theme.Colors.brand
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HazardStripe(stripe: stripeColor, gap: background)
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Theme.Fonts.label.weight(.semibold))
                    .foregroundStyle(textColor.opacity(0.75))
                Text(Format.won(amount))
                    .font(Theme.Fonts.heroAmount)
                    .foregroundStyle(amountColor)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if let caption {
                    Text(caption)
                        .font(Theme.Fonts.label)
                        .foregroundStyle(textColor.opacity(0.9))
                }
                footer()
                    .environment(\.heroOnLight, isLightBackground)
            }
            .padding(Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

extension HeroCard where Footer == EmptyView {
    init(title: String, amount: Int, caption: String? = nil, style: Style = .ink) {
        self.init(title: title, amount: amount, caption: caption, style: style) { EmptyView() }
    }
}

/// 작은 통계 타일 (이번 주 / 이번 달 등)
struct StatTile: View {
    let title: LocalizedStringKey
    let value: String
    var detail: String? = nil
    var tint: Color = Theme.Colors.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Fonts.caption.weight(.semibold))
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
        case .emphasis: return Theme.Colors.textPrimary
        }
    }
}

/// "라벨 — 값" 한 줄
struct KeyValueRow: View {
    let label: LocalizedStringKey
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
                .font(bold ? Theme.Fonts.amount : Theme.Fonts.label)
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .accessibilityElement(children: .combine)
    }
}

/// 화면 상단의 큰 제목 (홈 "11월" 등)
struct ScreenHeader<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    init(title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.Fonts.screenTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.Fonts.title)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

/// 둥근 아이콘 버튼 (헤더의 ‹ › 등)
struct RoundIconButton: View {
    let systemImage: String
    var accessibilityLabel: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(.body, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: Theme.minTapTarget, height: Theme.minTapTarget)
                .background(Theme.Colors.surface, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - 배지 · 칩

/// 공수 배지. compact는 달력 셀용 — 색 면 위에 잉크 숫자(도장 느낌).
struct ManUnitBadge: View {
    let value: Double
    var compact: Bool = false

    var body: some View {
        if compact {
            Text(Format.manUnit(value))
                .font(Theme.Fonts.badge)
                .foregroundStyle(.white)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 20)
                .background(Theme.Colors.manUnit(value), in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                .accessibilityLabel(Format.gongsu(value))
        } else {
            Text(Format.gongsu(value))
                .font(Theme.Fonts.amountSmall)
                .foregroundStyle(Theme.Colors.manUnit(value))
                .monospacedDigit()
                .lineLimit(1)
        }
    }
}

/// 입금 상태
struct PaidBadge: View {
    let isPaid: Bool

    var body: some View {
        Label(isPaid ? String(localized: "입금완료") : String(localized: "미입금"),
              systemImage: isPaid ? "checkmark.circle.fill" : "clock.fill")
            .font(Theme.Fonts.caption2.weight(.bold))
            .foregroundStyle(isPaid ? Theme.Colors.positive : Theme.Colors.warning)
            .labelStyle(.titleAndIcon)
    }
}

/// 태그·세금 방식 같은 짧은 라벨
struct TagChip: View {
    let text: String
    var tint: Color = Theme.Colors.warning
    var filled: Bool = true
    var foreground: Color? = nil

    var body: some View {
        Text(text)
            .font(Theme.Fonts.caption2.weight(.bold))
            .foregroundStyle(foreground ?? (filled ? .white : tint))
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 4)
            .background(filled ? tint : tint.opacity(0.15), in: Capsule())
            .lineLimit(1)
    }
}

/// 잉크 바탕(히어로) 위에 올리는 칩
struct InkChip: View {
    let text: String
    @Environment(\.heroOnLight) private var onLight

    var body: some View {
        Text(text)
            .font(Theme.Fonts.caption2.weight(.bold))
            .foregroundStyle(onLight ? Theme.Colors.onBrand : Theme.Colors.onInk)
            .monospacedDigit()
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 4)
            .background(onLight ? Theme.Colors.onBrand.opacity(0.12) : Color.white.opacity(0.14), in: Capsule())
            .lineLimit(1)
    }
}

private struct HeroOnLightKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// HeroCard 바탕이 밝은 색인지 — 안의 칩이 글자색을 맞춘다
    var heroOnLight: Bool {
        get { self[HeroOnLightKey.self] }
        set { self[HeroOnLightKey.self] = newValue }
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
            Text(site?.name ?? Format.unassignedSite)
                .font(font)
                .lineLimit(1)
        }
    }
}

// MARK: - 버튼

/// 화면의 주요 행동 1개 — 형광 노랑 면에 잉크 글자
struct BigActionButton: View {
    let title: LocalizedStringKey
    var subtitle: String? = nil
    var systemImage: String = "plus.circle.fill"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Fonts.headline.weight(.heavy))
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Fonts.caption.weight(.semibold))
                            .opacity(0.8)
                    }
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.body.weight(.heavy))
            }
            .foregroundStyle(Theme.Colors.onBrand)
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Theme.Colors.brand, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// 카드 안의 선택 버튼 (프리셋)
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
            .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
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
    let text: LocalizedStringKey
    var trailing: AnyView? = nil

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    init<T: View>(_ text: LocalizedStringKey, @ViewBuilder trailing: () -> T) {
        self.text = text
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack {
            Text(text)
                .font(Theme.Fonts.title)
                .foregroundStyle(Theme.Colors.textPrimary)
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
    let title: LocalizedStringKey
    var message: LocalizedStringKey? = nil
    var actionTitle: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .bold))
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
                        .font(Theme.Fonts.headline.weight(.heavy))
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
            RoundedRectangle(cornerRadius: 2)
                .fill(entry.site.map { Theme.Colors.site($0.colorIndex) } ?? Theme.Colors.textTertiary)
                .frame(width: 4)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: 6) {
                    if showsDate {
                        Text(Format.shortDay.string(from: entry.date))
                            .font(Theme.Fonts.headline)
                            .monospacedDigit()
                    }
                    if showsSite {
                        Text(entry.site?.name ?? Format.unassignedSite)
                            .font(showsDate ? Theme.Fonts.label : Theme.Fonts.headline)
                            .lineLimit(1)
                    }
                    Text(entry.weatherCondition.emoji)
                        .font(Theme.Fonts.caption)
                }
                HStack(spacing: 6) {
                    if let tag = entry.workTag {
                        TagChip(text: tag.title)
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
                MoneyText(value: entry.netAmount, style: .emphasis, font: Theme.Fonts.amountSmall)
                PaidBadge(isPaid: entry.isPaid)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 리스트 스타일 보조

extension View {
    /// List/Form을 공수장 바탕색 위에 올린다
    func gongListBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background)
    }
}
