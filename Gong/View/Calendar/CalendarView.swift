//
//  CalendarView.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [WorkEntry]
    @Query private var sites: [Site]

    @State private var currentMonth: Date = Calendar.current.startOfMonth(for: .now)
    @State private var selectedDate: Date? = nil
    @State private var isWeekMode: Bool = false
    @State private var sheet: EntrySheet? = nil

    /// 시트 대상 — `.sheet(item:)`로 띄워야 선택한 날짜·기록이 정확히 전달됨
    private enum EntrySheet: Identifiable {
        case new(Date)
        case edit(WorkEntry)

        var id: String {
            switch self {
            case .new(let date): return "new-\(date.timeIntervalSince1970)"
            case .edit(let entry): return "edit-\(entry.persistentModelID.hashValue)"
            }
        }
        var date: Date {
            switch self {
            case .new(let date): return date
            case .edit(let entry): return entry.date
            }
        }
        var entry: WorkEntry? {
            if case .edit(let entry) = self { return entry }
            return nil
        }
    }

    private let calendar = Calendar.current
    /// 월요일 시작 요일 이름 (언어별)
    private let weekdaySymbols = Format.weekdaySymbolsMondayFirst

    private struct CalendarDay {
        let date: Date
        let isCurrentMonth: Bool
    }

    private var activeSites: [Site] { sites.filter { $0.isActive } }

    /// 가장 최근에 기록한 현장 → 새 기록의 기본 현장
    private var recentSite: Site? {
        entries.max { ($0.date, $0.createdAt) < ($1.date, $1.createdAt) }?.site
    }

    private var isCurrentMonthShown: Bool {
        calendar.isDate(currentMonth, equalTo: .now, toGranularity: .month)
    }

    private var todayHasEntry: Bool {
        entries.contains { calendar.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                GeometryReader { screen in
                    if isWeekMode, let date = selectedDate {
                        weekModeView(for: date)
                            .transition(.opacity)
                    } else {
                        monthModeView(height: screen.size.height)
                            .transition(.opacity)
                    }
                }
            }
            .background(Theme.Colors.background)
            .animation(.easeInOut(duration: 0.3), value: isWeekMode)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $sheet) { target in
                WorkEntrySheetView(
                    date: target.date,
                    sites: sites,
                    editingEntry: target.entry,
                    suggestedSite: recentSite
                )
            }
        }
    }

    // MARK: - 헤더 (직접 그림: "11월" 크게, 연도 작게)
    private var header: some View {
        let year = calendar.component(.year, from: currentMonth)
        return ScreenHeader(title: Format.monthName.string(from: currentMonth).localizedCapitalized, subtitle: String(year)) {
            HStack(spacing: Theme.Spacing.sm) {
                if !isCurrentMonthShown {
                    Button("오늘") { goToToday() }
                        .font(Theme.Fonts.label.weight(.bold))
                        .foregroundStyle(Theme.Colors.onBrand)
                        .padding(.horizontal, Theme.Spacing.md)
                        .frame(height: Theme.minTapTarget)
                        .background(Theme.Colors.brand, in: Capsule())
                        .buttonStyle(.plain)
                }
                RoundIconButton(systemImage: "chevron.left", accessibilityLabel: "이전 달") { shiftMonth(-1) }
                RoundIconButton(systemImage: "chevron.right", accessibilityLabel: "다음 달") { shiftMonth(1) }
            }
        }
        .padding(.top, Theme.Spacing.sm)
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - 월간 모드
    private func monthModeView(height: CGFloat) -> some View {
        let summary = MonthlySummary(month: currentMonth, entries: currentMonthEntries)
        let rows = CGFloat(max(monthWeeks.count, 1))
        let rowHeight = min(max((height - 300) / rows, 60), 86)

        return ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                monthHero(summary)

                if isCurrentMonthShown && !todayHasEntry {
                    todayAction
                }

                VStack(spacing: 0) {
                    weekdayHeader
                    monthGrid(rowHeight: rowHeight)
                        .frame(height: rowHeight * rows)
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.bottom, Theme.Spacing.xs)
                }
                .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))

                if !summary.entries.isEmpty {
                    monthSummaryCard(summary)
                }

                if sites.isEmpty && entries.isEmpty {
                    onboardingHint
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .simultaneousGesture(monthSwipeGesture)
    }

    private func monthHero(_ summary: MonthlySummary) -> some View {
        let monthName = Format.monthName.string(from: currentMonth)
        let caption = summary.entries.isEmpty
            ? String(localized: "아직 기록이 없어요")
            : String(localized: "\(Format.gongsu(summary.manUnit)) · \(Format.days(summary.workDays)) 근무")
        return HeroCard(title: String(localized: "\(monthName) 실수령액"), amount: summary.net, caption: caption) {
            if summary.tax > 0 || summary.unpaidAmount > 0 {
                HStack(spacing: Theme.Spacing.sm) {
                    if summary.tax > 0 {
                        InkChip(text: String(localized: "세금 \(Format.signedWon(-summary.tax))"))
                    }
                    if summary.unpaidAmount > 0 {
                        InkChip(text: String(localized: "미입금 \(Format.won(summary.unpaidAmount)) · \(Format.count(summary.unpaid.count))"))
                    }
                }
                .padding(.top, Theme.Spacing.xs)
            }
        }
    }

    private var todayAction: some View {
        VStack(spacing: Theme.Spacing.xs) {
            if let site = recentSite.flatMap({ $0.isActive ? $0 : nil }) ?? activeSites.first {
                BigActionButton(
                    title: "오늘 1공수 찍기",
                    subtitle: "\(site.name) · \(Format.won(site.defaultWage))",
                    systemImage: "bolt.fill"
                ) {
                    quickAdd(site: site, manUnit: 1, date: .now)
                }
                Button {
                    sheet = .new(.now)
                } label: {
                    Text("다른 공수나 현장으로 기록하기")
                        .font(Theme.Fonts.label.weight(.semibold))
                        .foregroundStyle(Theme.Colors.accentText)
                        .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                }
                .buttonStyle(.plain)
            } else {
                BigActionButton(
                    title: "오늘 공수 기록하기",
                    subtitle: String(localized: "현장을 등록하면 다음부터 한 번에 찍혀요"),
                    systemImage: "square.and.pencil"
                ) {
                    sheet = .new(.now)
                }
            }
        }
    }

    private var onboardingHint: some View {
        GCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Label("처음이신가요?", systemImage: "hand.wave.fill")
                    .font(Theme.Fonts.headline)
                Text("현장 탭에서 현장을 먼저 등록해 두면 단가와 세금 방식이 자동으로 채워져요.")
                    .font(Theme.Fonts.label)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text("달력에서 날짜를 누르면 그날 기록을 보고, 길게 누르면 1공수를 바로 찍을 수 있어요.")
                    .font(Theme.Fonts.label)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: - 주간 모드
    private func weekModeView(for date: Date) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                weekdayHeader
                weekGrid
                    .padding(.horizontal, Theme.Spacing.xs)
                    .padding(.bottom, Theme.Spacing.xs)
            }
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            .padding(.horizontal, Theme.Spacing.lg)

            List {
                Section {
                    weekStatSection
                }

                Section {
                    let todayEntries = dayEntries(for: date)

                    if todayEntries.isEmpty {
                        EmptyStateView(systemImage: "doc.text", title: "기록 없음", message: "아래 버튼으로 공수를 입력해 보세요")
                    } else {
                        ForEach(todayEntries) { entry in
                            EntryRow(entry: entry, showsDate: false)
                                .contentShape(Rectangle())
                                .onTapGesture { sheet = .edit(entry) }
                                .swipeActions(edge: .leading) {
                                    paidToggle(entry)
                                }
                        }
                        .onDelete { offsets in
                            deleteEntries(at: offsets, from: todayEntries)
                        }
                    }

                    Button {
                        sheet = .new(date)
                    } label: {
                        Label("공수 추가", systemImage: "plus")
                            .font(Theme.Fonts.headline)
                            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget, alignment: .center)
                            .foregroundStyle(Theme.Colors.accentText)
                    }
                } header: {
                    HStack(spacing: 6) {
                        Text(Format.dayTitle.string(from: date))
                        if let name = HolidayService.holidayName(for: date) {
                            Text(name).foregroundStyle(Theme.Colors.holiday)
                        }
                    }
                    .font(Theme.Fonts.label.weight(.semibold))
                }
            }
            .listStyle(.insetGrouped)
            .gongListBackground()
        }
    }

    private func paidToggle(_ entry: WorkEntry) -> some View {
        Button {
            entry.isPaid.toggle()
            try? context.save()
        } label: {
            Label(entry.isPaid ? String(localized: "미입금으로") : String(localized: "입금 완료"),
                  systemImage: entry.isPaid ? "arrow.uturn.backward" : "checkmark.circle")
        }
        .tint(entry.isPaid ? Color(.systemGray) : Theme.Colors.positive)
    }

    // MARK: - 요일 헤더
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols.indices, id: \.self) { index in
                Text(weekdaySymbols[index])
                    .font(Theme.Fonts.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(
                        index == 6 ? Theme.Colors.holiday :
                        index == 5 ? Theme.Colors.saturday : Theme.Colors.textSecondary
                    )
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - 주간 그리드
    private var weekGrid: some View {
        let week = currentWeekDays
        return HStack(spacing: 2) {
            ForEach(week.indices, id: \.self) { idx in
                dayCell(for: week[idx], height: nil)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - 월간 그리드
    private func monthGrid(rowHeight: CGFloat) -> some View {
        let weeks = monthWeeks
        return VStack(spacing: 2) {
            ForEach(weeks.indices, id: \.self) { weekIndex in
                HStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        dayCell(for: weeks[weekIndex][dayIndex], height: rowHeight - 2)
                    }
                }
            }
        }
    }

    // MARK: - 날짜 셀 (도장 스타일: 일한 날은 현장 색 면)
    private func dayCell(for day: CalendarDay, height: CGFloat?) -> some View {
        let date = day.date
        let dayItems = dayEntries(for: date)
        let mu = dayItems.reduce(0) { $0 + $1.manUnit }
        let worked = !dayItems.isEmpty && day.isCurrentMonth
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let isToday = calendar.isDateInToday(date)
        let dayType = HolidayService.dayType(for: date)
        let holidayName = HolidayService.holidayName(for: date)
        let hasUnpaid = dayItems.contains { !$0.isPaid }
        let siteColor = dayItems.first?.site.map { Theme.Colors.site($0.colorIndex) } ?? Theme.Colors.textTertiary

        let numberColor: Color = {
            if !day.isCurrentMonth { return Theme.Colors.textTertiary }
            if isSelected { return Theme.Colors.onBrand }
            if dayType == .holiday { return Theme.Colors.holiday }
            if dayType == .saturday { return Theme.Colors.saturday }
            return Theme.Colors.textPrimary
        }()

        return VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top) {
                Text("\(calendar.component(.day, from: date))")
                    .font(Theme.Fonts.dayNumber.weight(isToday ? .heavy : .semibold))
                    .foregroundStyle(numberColor)
                    .padding(.horizontal, 4)
                    .frame(minWidth: 24, minHeight: 24)
                    .background {
                        if isSelected {
                            Capsule().fill(Theme.Colors.brand)
                        } else if isToday {
                            Capsule().strokeBorder(Theme.Colors.brand, lineWidth: 2)
                        }
                    }
                Spacer(minLength: 0)
                if worked && hasUnpaid {
                    Circle()
                        .fill(Theme.Colors.warning)
                        .frame(width: 7, height: 7)
                        .padding(.top, 4)
                        .padding(.trailing, 2)
                        .accessibilityHidden(true)
                }
            }

            if day.isCurrentMonth, let holidayName {
                Text(holidayName)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Colors.holiday)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)

            if worked {
                ManUnitBadge(value: mu, compact: true)
            } else if height == nil {
                // 주간 모드: 빈 날도 같은 높이
                Color.clear.frame(height: 20)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm + 2, style: .continuous)
                .fill(worked ? siteColor.opacity(0.14) : (isSelected ? Theme.Colors.brandSoft : .clear))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard day.isCurrentMonth || height == nil else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                if !day.isCurrentMonth {
                    currentMonth = calendar.startOfMonth(for: date)
                }
                selectedDate = date
                isWeekMode = true
            }
        }
        .contextMenu {
            if day.isCurrentMonth || height == nil {
                quickAddMenu(for: date)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(for: date, manUnit: mu, holiday: holidayName))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - 길게 눌러 빠른 기록
    @ViewBuilder
    private func quickAddMenu(for date: Date) -> some View {
        let ordered = activeSites.sorted { a, b in
            if a === recentSite { return true }
            if b === recentSite { return false }
            return a.startDate > b.startDate
        }
        if ordered.isEmpty {
            Button {
                sheet = .new(date)
            } label: {
                Label("공수 기록…", systemImage: "plus")
            }
        } else {
            ForEach(ordered.prefix(4)) { site in
                Button {
                    quickAdd(site: site, manUnit: 1, date: date)
                } label: {
                    Label(String(localized: "\(site.name) \(Format.gongsu(1))"), systemImage: "bolt.fill")
                }
            }
            Divider()
            Button {
                sheet = .new(date)
            } label: {
                Label("자세히 기록…", systemImage: "square.and.pencil")
            }
        }
    }

    private func quickAdd(site: Site, manUnit: Double, date: Date) {
        let entry = WorkEntry(
            date: calendar.startOfDay(for: date),
            manUnit: manUnit,
            wage: site.defaultWage,
            mealAllowance: site.defaultMealAllowance,
            dayType: HolidayService.dayType(for: date),
            site: site,
            taxMode: site.taxMode
        )
        context.insert(entry)
        try? context.save()
    }

    // MARK: - 이번 주 통계
    private var weekStatSection: some View {
        let weekEntries = currentWeekDays.map { dayEntries(for: $0.date) }.flatMap { $0 }
        let weekManUnit = weekEntries.reduce(0) { $0 + $1.manUnit }
        let weekNet = weekEntries.reduce(0) { $0 + $1.netAmount }
        let monthEntries = currentMonthEntries
        let monthManUnit = monthEntries.reduce(0) { $0 + $1.manUnit }
        let monthNet = monthEntries.reduce(0) { $0 + $1.netAmount }

        return HStack(spacing: Theme.Spacing.md) {
            StatTile(title: "이번 주", value: Format.gongsu(weekManUnit), detail: Format.won(weekNet))
            Divider()
            StatTile(title: "이번 달", value: Format.gongsu(monthManUnit), detail: Format.won(monthNet))
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - 월간 요약 카드
    private func monthSummaryCard(_ summary: MonthlySummary) -> some View {
        let paidCount = summary.entries.count - summary.unpaid.count
        let totalCount = summary.entries.count
        let manUnitText = "\(Format.gongsu(summary.manUnit)) · \(Format.days(summary.workDays))"
        let shareText = SettlementExporter.text(for: summary)

        return VStack(spacing: 0) {
            HStack {
                Text("월간 요약")
                    .font(Theme.Fonts.title)
                Spacer()
                ShareLink(item: shareText) {
                    Label("공유", systemImage: "square.and.arrow.up")
                        .font(Theme.Fonts.label.weight(.semibold))
                        .foregroundStyle(Theme.Colors.accentText)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)

            Divider().padding(.leading, Theme.Spacing.lg)
            KeyValueRow(label: "총 공수", value: manUnitText, valueColor: Theme.Colors.textPrimary, bold: true)
            Divider().padding(.leading, Theme.Spacing.lg)
            KeyValueRow(label: "일당 합계", value: Format.won(summary.taxable))
            if summary.allowance > 0 {
                Divider().padding(.leading, Theme.Spacing.lg)
                KeyValueRow(label: "수당 합계", value: Format.signedWon(summary.allowance), valueColor: Theme.Colors.positive)
            }
            Divider().padding(.leading, Theme.Spacing.lg)
            KeyValueRow(label: "세금", value: Format.signedWon(-summary.tax), valueColor: summary.tax > 0 ? Theme.Colors.danger : Theme.Colors.textSecondary)
            Divider().padding(.leading, Theme.Spacing.lg)
            KeyValueRow(label: "실수령액", value: Format.won(summary.net), valueColor: Theme.Colors.textPrimary, bold: true)
            Divider().padding(.leading, Theme.Spacing.lg)
            KeyValueRow(label: "입금 확인", value: "\(paidCount)/\(Format.count(totalCount))")
            if summary.unpaidAmount > 0 {
                Divider().padding(.leading, Theme.Spacing.lg)
                KeyValueRow(label: "미입금", value: Format.won(summary.unpaidAmount), valueColor: Theme.Colors.warning, bold: true)
            }
        }
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
    }

    // MARK: - 달 이동
    private var monthSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 40, coordinateSpace: .local)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy) * 1.5 else { return }
                shiftMonth(dx < 0 ? 1 : -1)
            }
    }

    private func shiftMonth(_ delta: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: delta, to: currentMonth)
                .map { calendar.startOfMonth(for: $0) } ?? currentMonth
            isWeekMode = false
            selectedDate = nil
        }
    }

    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.startOfMonth(for: .now)
            isWeekMode = false
            selectedDate = nil
        }
    }

    // MARK: - 달력 계산
    private var calendarDays: [CalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        let firstDay = monthInterval.start
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingEmpty = (weekday - 2 + 7) % 7

        var days: [CalendarDay] = []
        for i in (0..<leadingEmpty).reversed() {
            if let date = calendar.date(byAdding: .day, value: -(i + 1), to: firstDay) {
                days.append(CalendarDay(date: date, isCurrentMonth: false))
            }
        }
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDay) {
                days.append(CalendarDay(date: date, isCurrentMonth: true))
            }
        }
        while days.count % 7 != 0 {
            if let last = days.last?.date,
               let next = calendar.date(byAdding: .day, value: 1, to: last) {
                days.append(CalendarDay(date: next, isCurrentMonth: false))
            } else {
                break
            }
        }
        return days
    }

    private var monthWeeks: [[CalendarDay]] {
        let days = calendarDays
        guard !days.isEmpty else { return [] }
        return stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        }
    }

    private var currentWeekDays: [CalendarDay] {
        let base = selectedDate ?? .now
        let monday = calendar.startOfWeekMonday(for: base)
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: monday).map {
                CalendarDay(
                    date: $0,
                    isCurrentMonth: calendar.isDate($0, equalTo: currentMonth, toGranularity: .month)
                )
            }
        }
    }

    private var currentMonthEntries: [WorkEntry] {
        guard let interval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        return entries.filter { interval.contains($0.date) }
    }

    private func dayEntries(for date: Date) -> [WorkEntry] {
        entries
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private func accessibilityText(for date: Date, manUnit: Double, holiday: String?) -> String {
        var parts = [Format.dayTitle.string(from: date)]
        if let holiday { parts.append(holiday) }
        parts.append(manUnit > 0 ? Format.gongsu(manUnit) : String(localized: "기록 없음"))
        return parts.joined(separator: ", ")
    }

    private func deleteEntries(at offsets: IndexSet, from todayEntries: [WorkEntry]) {
        offsets.map { todayEntries[$0] }.forEach { context.delete($0) }
        try? context.save()
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Site.self, WorkEntry.self], inMemory: true)
}
