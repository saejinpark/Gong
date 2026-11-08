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
                            .font(.subheadline)
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
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    weekdayHeader
                    Divider()
                    let rows = CGFloat(max(monthWeeks.count, 1))
                    let calendarHeight = min(max(height - 40, 280), rows * 96)
                    monthGrid(height: calendarHeight)
                        .frame(height: calendarHeight)
                }

                VStack(spacing: 0) {
                    HStack {
                        Text("월간 요약")
                            .font(.headline.bold())
                        Spacer()
                        if !currentMonthEntries.isEmpty {
                            ShareLink(item: SettlementExporter.text(for: MonthlySummary(month: currentMonth, entries: currentMonthEntries))) {
                                Label("공유", systemImage: "square.and.arrow.up")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()

                    monthSummaryContent
                }

                if sites.isEmpty && entries.isEmpty {
                    onboardingHint
                }
            }
        }
        .scrollIndicators(.hidden)
        .simultaneousGesture(monthSwipeGesture)
    }

    private var onboardingHint: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("처음이신가요?", systemImage: "hand.wave")
                .font(.headline)
            Text("날짜를 누르면 그날 공수를 적을 수 있어요. 현장을 먼저 등록해 두면 단가와 세금 방식이 자동으로 채워져요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("날짜를 길게 누르면 1공수를 바로 넣을 수 있어요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .padding([.horizontal, .bottom])
    }

    // MARK: - 주간 모드
    private func weekModeView(for date: Date) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                weekdayHeader
                Divider()
                weekGrid
            }

            Divider()

            List {
                Section {
                    weekStatSection
                }

                Section {
                    let todayEntries = dayEntries(for: date)

                    if todayEntries.isEmpty {
                        ContentUnavailableView(
                            "기록 없음",
                            systemImage: "doc.text",
                            description: Text("공수를 입력해보세요")
                        )
                    } else {
                        ForEach(todayEntries) { entry in
                            EntryRow(entry: entry, showsDate: false)
                                .contentShape(Rectangle())
                                .onTapGesture { sheet = .edit(entry) }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        entry.isPaid.toggle()
                                        try? context.save()
                                    } label: {
                                        Label(entry.isPaid ? "미입금으로" : "입금 완료", systemImage: entry.isPaid ? "arrow.uturn.backward" : "checkmark.circle")
                                    }
                                    .tint(entry.isPaid ? .gray : .green)
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
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(Color.accentColor)
                    }
                } header: {
                    HStack(spacing: 6) {
                        Text(Format.dayTitle.string(from: date))
                        if let name = HolidayService.holidayName(for: date) {
                            Text(name).foregroundStyle(.red)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - 요일 헤더
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.bold())
                    .foregroundStyle(
                        symbol == "일" ? .red :
                        symbol == "토" ? .blue : .secondary
                    )
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - 주간 그리드
    private var weekGrid: some View {
        let week = currentWeekDays
        return HStack(spacing: 0) {
            ForEach(week.indices, id: \.self) { idx in
                weekDayCellView(for: week[idx])
                if idx < week.count - 1 {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 0.5)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func weekDayCellView(for day: CalendarDay) -> some View {
        let date = day.date
        let mu = manUnit(for: date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false

        return VStack(alignment: .leading, spacing: 4) {
            dayNumber(for: day, isSelected: isSelected)

            Text(mu > 0 ? Format.manUnit(mu) : " ")
                .font(.caption2.bold())
                .foregroundStyle(mu > 0 ? .white : .clear)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
                .background(mu > 0 ? Color.manUnit(mu) : .clear, in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background { if isSelected { Color.accentColor.opacity(0.08) } }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                if !day.isCurrentMonth {
                    currentMonth = calendar.startOfMonth(for: date)
                }
                selectedDate = date
            }
        }
    }

    // MARK: - 월간 그리드
    private func monthGrid(height: CGFloat) -> some View {
        let weeks = monthWeeks
        let weekCount = weeks.count
        let rowHeight = weekCount == 0 ? 0 : height / CGFloat(weekCount)

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
                for i in 1...max(weekCount, 1) {
                    let y = rowH * CGFloat(i)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                ctx.stroke(path, with: .color(Color(.separator)), lineWidth: 0.5)
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
        let hasTag = dayItems.contains { $0.workTag != nil }

        return VStack(alignment: .leading, spacing: 2) {
            dayNumber(for: day, isSelected: isSelected)

            if day.isCurrentMonth {
                if let holidayName {
                    Text(holidayName)
                        .font(.system(size: 9))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 0)

                if !dayItems.isEmpty && (hasTag || hasUnpaid) {
                    HStack(spacing: 3) {
                        if hasTag {
                            Circle().fill(.orange).frame(width: 5, height: 5)
                        }
                        if hasUnpaid {
                            Circle().strokeBorder(.secondary, lineWidth: 1).frame(width: 5, height: 5)
                        }
                    }
                    .padding(.bottom, 1)
                }

                if !dayItems.isEmpty {
                    Text(Format.manUnit(mu))
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                        .background(Color.manUnit(mu), in: RoundedRectangle(cornerRadius: 4))
                }
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background { if isSelected { Color.accentColor.opacity(0.08) } }
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
            .font(.footnote.weight(isToday ? .bold : .regular))
            .foregroundStyle(
                !day.isCurrentMonth ? Color(.tertiaryLabel) :
                isSelected ? .white :
                dayType == .holiday ? .red :
                dayType == .saturday ? .blue : .primary
            )
            .frame(width: 24, height: 24)
            .background {
                if isSelected {
                    Circle().fill(Color.accentColor)
                } else if isToday {
                    Circle().strokeBorder(Color.accentColor, lineWidth: 1.5)
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

        return HStack {
            statColumn(title: "이번 주", manUnit: weekManUnit, net: weekNet)
            Divider()
            statColumn(title: "이번 달", manUnit: monthManUnit, net: monthNet)
        }
        .padding(.vertical, 4)
    }

    private func statColumn(title: String, manUnit: Double, net: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(Format.manUnit(manUnit))공수")
                .font(.headline.bold())
                .foregroundStyle(Color.accentColor)
            Text(Format.won(net))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 월간 통계
    private var monthSummaryContent: some View {
        let summary = MonthlySummary(month: currentMonth, entries: currentMonthEntries)
        let paidCount = summary.entries.count - summary.unpaid.count
        let totalCount = summary.entries.count
        let manUnitText = "\(Format.manUnit(summary.manUnit))공수 · \(summary.workDays)일"

        return VStack(spacing: 0) {
            summaryRow(label: "총 공수", value: manUnitText, valueColor: .accentColor, bold: true)
            Divider().padding(.leading)
            summaryRow(label: "일당 합계", value: Format.won(summary.taxable))
            if summary.allowance > 0 {
                Divider().padding(.leading)
                summaryRow(label: "수당 합계", value: "+\(Format.won(summary.allowance))")
            }
            Divider().padding(.leading)
            summaryRow(label: "세금", value: "-\(Format.won(summary.tax))", valueColor: summary.tax > 0 ? .red : .secondary)
            Divider().padding(.leading)
            summaryRow(label: "실수령액", value: Format.won(summary.net), valueColor: .accentColor, bold: true)
            Divider().padding(.leading)
            summaryRow(label: "입금 확인", value: "\(paidCount)/\(totalCount)건")
            if summary.unpaidAmount > 0 {
                Divider().padding(.leading)
                summaryRow(label: "미입금", value: Format.won(summary.unpaidAmount), valueColor: .red, bold: true)
            }
        }
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding([.horizontal, .bottom])
    }

    private func summaryRow(label: String, value: String, valueColor: Color = .secondary, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(bold ? .subheadline.bold() : .subheadline)
                .foregroundStyle(valueColor)
                .monospacedDigit()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
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

    private func manUnit(for date: Date) -> Double {
        dayEntries(for: date).reduce(0) { $0 + $1.manUnit }
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

// MARK: - 기록 행 (달력·현장·정산에서 공용)
struct EntryRow: View {
    let entry: WorkEntry
    var showsDate: Bool = true
    var showsSite: Bool = true

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if showsDate {
                        Text(Format.shortDay.string(from: entry.date))
                            .font(.subheadline.bold())
                    }
                    if showsSite {
                        Text(entry.site?.name ?? "현장 미지정")
                            .font(showsDate ? .subheadline : .subheadline.bold())
                            .lineLimit(1)
                    }
                    Text(entry.weatherCondition.emoji)
                        .font(.caption)
                    if let tag = entry.workTag {
                        Text(tag.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange, in: Capsule())
                    }
                }
                if !entry.memo.isEmpty {
                    Text(entry.memo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Format.manUnit(entry.manUnit))공수")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.manUnit(entry.manUnit))
                Text(Format.won(entry.netAmount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Text(entry.isPaid ? "입금완료" : "미입금")
                    .font(.caption2)
                    .foregroundStyle(entry.isPaid ? .green : .orange)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Site.self, WorkEntry.self], inMemory: true)
}
