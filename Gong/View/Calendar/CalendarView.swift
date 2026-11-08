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
    private let weekdaySymbols = ["월", "화", "수", "목", "금", "토", "일"]

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
            GeometryReader { screen in
                if isWeekMode, let date = selectedDate {
                    weekModeView(for: date)
                        .transition(.opacity)
                } else {
                    monthModeView(height: screen.size.height)
                        .transition(.opacity)
                }
            }
            .background(Theme.Colors.background)
            .animation(.easeInOut(duration: 0.3), value: isWeekMode)
            .navigationTitle(Format.monthTitle.string(from: currentMonth))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { shiftMonth(-1) } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("이전 달")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !isCurrentMonthShown {
                        Button("오늘") { goToToday() }
                            .font(Theme.Fonts.label)
                    }
                    Button { shiftMonth(1) } label: {
                        Image(systemName: "chevron.right")
                    }
                    .accessibilityLabel("다음 달")
                }
            }
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

    // MARK: - 월간 모드
    private func monthModeView(height: CGFloat) -> some View {
        let summary = MonthlySummary(month: currentMonth, entries: currentMonthEntries)
        let rows = CGFloat(max(monthWeeks.count, 1))
        let rowHeight = min(max((height - 320) / rows, 58), 84)

        return ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                monthHero(summary)

                if isCurrentMonthShown && !todayHasEntry {
                    todayAction
                }

                VStack(spacing: 0) {
                    weekdayHeader
                    Divider()
                    monthGrid(rowHeight: rowHeight)
                        .frame(height: rowHeight * rows)
                }
                .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))

                if !summary.entries.isEmpty {
                    monthSummaryCard(summary)
                }

                if sites.isEmpty && entries.isEmpty {
                    onboardingHint
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .simultaneousGesture(monthSwipeGesture)
    }

    private func monthHero(_ summary: MonthlySummary) -> some View {
        let month = calendar.component(.month, from: currentMonth)
        let caption = summary.entries.isEmpty
            ? "아직 기록이 없어요"
            : "\(Format.manUnit(summary.manUnit))공수 · \(summary.workDays)일 근무"
        return HeroCard(title: "\(month)월 실수령액", amount: summary.net, caption: caption) {
            if summary.tax > 0 || summary.unpaidAmount > 0 {
                HStack(spacing: Theme.Spacing.sm) {
                    if summary.tax > 0 {
                        TagChip(text: "세금 -\(summary.tax.formatted())원", tint: .white.opacity(0.25))
                    }
                    if summary.unpaidAmount > 0 {
                        TagChip(text: "미입금 \(summary.unpaidAmount.formatted())원 · \(summary.unpaid.count)건", tint: .white.opacity(0.25))
                    }
                }
                .padding(.top, Theme.Spacing.xs)
            }
        }
    }

    private var todayAction: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if let site = recentSite.flatMap({ $0.isActive ? $0 : nil }) ?? activeSites.first {
                BigActionButton(
                    title: "오늘 1공수 기록",
                    subtitle: "\(site.name) · \(Format.won(site.defaultWage))",
                    systemImage: "bolt.fill"
                ) {
                    quickAdd(site: site, manUnit: 1, date: .now)
                }
                Button {
                    sheet = .new(.now)
                } label: {
                    Text("다른 공수나 현장으로 기록하기")
                        .font(Theme.Fonts.label)
                        .foregroundStyle(Theme.Colors.brand)
                        .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                }
                .buttonStyle(.plain)
            } else {
                BigActionButton(
                    title: "오늘 공수 기록하기",
                    subtitle: "현장을 등록하면 다음부터 한 번에 기록돼요",
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
                Label("처음이신가요?", systemImage: "hand.wave")
                    .font(Theme.Fonts.headline)
                Text("현장 탭에서 현장을 먼저 등록해 두면 단가와 세금 방식이 자동으로 채워져요.")
                    .font(Theme.Fonts.label)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text("달력에서 날짜를 누르면 그날 기록을 보고, 길게 누르면 1공수를 바로 넣을 수 있어요.")
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
                Divider()
                weekGrid
            }
            .background(Theme.Colors.surface)

            Divider()

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
                            .foregroundStyle(Theme.Colors.brand)
                    }
                } header: {
                    HStack(spacing: 6) {
                        Text(Format.dayTitle.string(from: date))
                        if let name = HolidayService.holidayName(for: date) {
                            Text(name).foregroundStyle(Theme.Colors.holiday)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background)
        }
    }

    private func paidToggle(_ entry: WorkEntry) -> some View {
        Button {
            entry.isPaid.toggle()
            try? context.save()
        } label: {
            Label(entry.isPaid ? "미입금으로" : "입금 완료", systemImage: entry.isPaid ? "arrow.uturn.backward" : "checkmark.circle")
        }
        .tint(entry.isPaid ? Color(.systemGray) : Theme.Colors.positive)
    }

    // MARK: - 요일 헤더
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(Theme.Fonts.caption.bold())
                    .foregroundStyle(
                        symbol == "일" ? Theme.Colors.holiday :
                        symbol == "토" ? Theme.Colors.saturday : Theme.Colors.textSecondary
                    )
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - 주간 그리드
    private var weekGrid: some View {
        let week = currentWeekDays
        return HStack(spacing: 0) {
            ForEach(week.indices, id: \.self) { idx in
                weekDayCellView(for: week[idx])
                if idx < week.count - 1 {
                    Rectangle()
                        .fill(Theme.Colors.separator)
                        .frame(width: 0.5)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func weekDayCellView(for day: CalendarDay) -> some View {
        let date = day.date
        let items = dayEntries(for: date)
        let mu = items.reduce(0) { $0 + $1.manUnit }
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false

        return VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: 3) {
                dayNumber(for: day, isSelected: isSelected)
                siteDots(for: items)
            }

            if items.isEmpty {
                Text(" ")
                    .font(Theme.Fonts.badge)
                    .padding(.vertical, 2)
            } else {
                ManUnitBadge(value: mu, compact: true)
            }
        }
        .padding(Theme.Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background { if isSelected { Theme.Colors.brandSoft } }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                if !day.isCurrentMonth {
                    currentMonth = calendar.startOfMonth(for: date)
                }
                selectedDate = date
            }
        }
        .contextMenu { quickAddMenu(for: date) }
    }

    // MARK: - 월간 그리드
    private func monthGrid(rowHeight: CGFloat) -> some View {
        let weeks = monthWeeks
        let weekCount = weeks.count

        return ZStack {
            Canvas { ctx, size in
                let colWidth = size.width / 7
                let rowH = weekCount == 0 ? 0 : size.height / CGFloat(weekCount)
                var path = Path()
                for i in 1..<7 {
                    let x = colWidth * CGFloat(i)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                for i in 1..<max(weekCount, 1) {
                    let y = rowH * CGFloat(i)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                ctx.stroke(path, with: .color(Theme.Colors.separator), lineWidth: 0.5)
            }

            VStack(spacing: 0) {
                ForEach(weeks.indices, id: \.self) { weekIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            monthDayCellView(for: weeks[weekIndex][dayIndex], height: rowHeight)
                        }
                    }
                }
            }
        }
    }

    private func monthDayCellView(for day: CalendarDay, height: CGFloat) -> some View {
        let date = day.date
        let dayItems = dayEntries(for: date)
        let mu = dayItems.reduce(0) { $0 + $1.manUnit }
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let holidayName = HolidayService.holidayName(for: date)
        let hasUnpaid = dayItems.contains { !$0.isPaid }

        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                dayNumber(for: day, isSelected: isSelected)
                if day.isCurrentMonth {
                    siteDots(for: dayItems)
                }
            }

            if day.isCurrentMonth {
                if let holidayName {
                    Text(holidayName)
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.Colors.holiday)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 0)

                if !dayItems.isEmpty {
                    ManUnitBadge(value: mu, compact: true)
                        .overlay(alignment: .topTrailing) {
                            if hasUnpaid {
                                Circle()
                                    .fill(Theme.Colors.warning)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 2, y: -2)
                            }
                        }
                }
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(Theme.Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background { if isSelected { Theme.Colors.brandSoft } }
        .contentShape(Rectangle())
        .onTapGesture {
            guard day.isCurrentMonth else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedDate = date
                isWeekMode = true
            }
        }
        .contextMenu {
            if day.isCurrentMonth {
                quickAddMenu(for: date)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(for: date, manUnit: mu, holiday: holidayName))
    }

    private func dayNumber(for day: CalendarDay, isSelected: Bool) -> some View {
        let date = day.date
        let isToday = calendar.isDateInToday(date)
        let dayType = HolidayService.dayType(for: date)
        return Text("\(calendar.component(.day, from: date))")
            .font(Theme.Fonts.dayNumber.weight(isToday ? .bold : .regular))
            .foregroundStyle(
                !day.isCurrentMonth ? Theme.Colors.textTertiary :
                isSelected ? Theme.Colors.onBrand :
                dayType == .holiday ? Theme.Colors.holiday :
                dayType == .saturday ? Theme.Colors.saturday : Theme.Colors.textPrimary
            )
            .frame(width: 24, height: 24)
            .background {
                if isSelected {
                    Circle().fill(Theme.Colors.brand)
                } else if isToday {
                    Circle().strokeBorder(Theme.Colors.brand, lineWidth: 1.5)
                }
            }
    }

    /// 그날 일한 현장 색 점 (최대 3개)
    @ViewBuilder
    private func siteDots(for items: [WorkEntry]) -> some View {
        let indices = Array(Set(items.compactMap { $0.site?.colorIndex })).sorted().prefix(3)
        if !indices.isEmpty {
            HStack(spacing: 2) {
                ForEach(Array(indices), id: \.self) { index in
                    SiteDot(colorIndex: index, size: 5)
                }
            }
        }
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
                    Label("\(site.name) 1공수", systemImage: "bolt.fill")
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
            StatTile(title: "이번 주", value: "\(Format.manUnit(weekManUnit))공수", detail: Format.won(weekNet))
            Divider()
            StatTile(title: "이번 달", value: "\(Format.manUnit(monthManUnit))공수", detail: Format.won(monthNet))
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - 월간 요약 카드
    private func monthSummaryCard(_ summary: MonthlySummary) -> some View {
        let paidCount = summary.entries.count - summary.unpaid.count
        let totalCount = summary.entries.count
        let manUnitText = "\(Format.manUnit(summary.manUnit))공수 · \(summary.workDays)일"
        let shareText = SettlementExporter.text(for: summary)

        return VStack(spacing: 0) {
            HStack {
                Text("월간 요약")
                    .font(Theme.Fonts.headline)
                Spacer()
                ShareLink(item: shareText) {
                    Label("공유", systemImage: "square.and.arrow.up")
                        .font(Theme.Fonts.label)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)

            Divider().padding(.leading, Theme.Spacing.lg)
            KeyValueRow(label: "총 공수", value: manUnitText, valueColor: Theme.Colors.brand, bold: true)
            Divider().padding(.leading, Theme.Spacing.lg)
            KeyValueRow(label: "일당 합계", value: Format.won(summary.taxable))
            if summary.allowance > 0 {
                Divider().padding(.leading, Theme.Spacing.lg)
                KeyValueRow(label: "수당 합계", value: "+\(Format.won(summary.allowance))")
            }
            Divider().padding(.leading, Theme.Spacing.lg)
            KeyValueRow(label: "세금", value: "-\(Format.won(summary.tax))", valueColor: summary.tax > 0 ? Theme.Colors.danger : Theme.Colors.textSecondary)
            Divider().padding(.leading, Theme.Spacing.lg)
            KeyValueRow(label: "실수령액", value: Format.won(summary.net), valueColor: Theme.Colors.brand, bold: true)
            Divider().padding(.leading, Theme.Spacing.lg)
            KeyValueRow(label: "입금 확인", value: "\(paidCount)/\(totalCount)건")
            if summary.unpaidAmount > 0 {
                Divider().padding(.leading, Theme.Spacing.lg)
                KeyValueRow(label: "미입금", value: Format.won(summary.unpaidAmount), valueColor: Theme.Colors.danger, bold: true)
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
        parts.append(manUnit > 0 ? "\(Format.manUnit(manUnit))공수" : "기록 없음")
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
