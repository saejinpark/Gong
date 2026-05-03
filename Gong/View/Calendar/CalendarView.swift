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
    @State private var isShowingSheet: Bool = false
    @State private var editingEntry: WorkEntry? = nil
    
    private let calendar = Calendar.current
    private let weekdaySymbols = ["월", "화", "수", "목", "금", "토", "일"]
    
    private struct CalendarDay {
        let date: Date
        let isCurrentMonth: Bool
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { screen in
                if isWeekMode, let date = selectedDate {
                    // MARK: - 주간 모드
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            weekdayHeader
                            Divider()
                            // ✅ 높이 고정 없음 — 셀 콘텐츠 크기에 맞게 자연스럽게 결정
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
                                        entryRow(entry)
                                            .onTapGesture {
                                                editingEntry = entry
                                                isShowingSheet = true
                                            }
                                    }
                                    .onDelete { offsets in
                                        deleteEntries(at: offsets, from: todayEntries)
                                    }
                                }
                                
                                Button {
                                    editingEntry = nil
                                    isShowingSheet = true
                                } label: {
                                    Label("공수 추가", systemImage: "plus")
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .foregroundStyle(Color.accentColor)
                                }
                            } header: {
                                Text(dateTitle(for: date))
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                    .transition(.opacity)
                } else {
                    // MARK: - 월간 모드 (safeArea 제외 전체를 달력으로)
                    ScrollView {
                        VStack(spacing: 0) {
                            VStack(spacing: 0) {
                                weekdayHeader
                                Divider()
                                let calendarHeight = screen.size.height - 40
                                monthGrid(height: calendarHeight)
                                    .frame(height: calendarHeight)
                            }
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Text("월간 요약")
                                        .font(.headline.bold())
                                    Spacer()
                                }
                                .padding()
                                
                                monthSummaryContent
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isWeekMode)
            .navigationTitle(monthTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)
                                .map { calendar.startOfMonth(for: $0) } ?? currentMonth
                            isWeekMode = false
                            selectedDate = nil
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)
                                .map { calendar.startOfMonth(for: $0) } ?? currentMonth
                            isWeekMode = false
                            selectedDate = nil
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
            .sheet(isPresented: $isShowingSheet) {
                WorkEntrySheetView(
                    date: selectedDate ?? .now,
                    sites: sites,
                    editingEntry: editingEntry
                )
            }
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
    
    // MARK: - 주간 그리드 (높이 자유)
    private var weekGrid: some View {
        let week = currentWeekDays
        return HStack(spacing: 0) {
            ForEach(week.indices, id: \.self) { idx in
                weekDayCellView(for: week[idx])
                if idx < week.count - 1 {
                    // ✅ Divider 대신 1pt 선 — Divider는 GeometryReader 높이를 상속해서 늘어남
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 0.5)
                }
            }
        }
        // ✅ HStack이 콘텐츠 높이에만 맞게 — GeometryReader 높이 무시
        .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - 주간 셀 (콘텐츠 크기에 맞게 높이 자동)
    private func weekDayCellView(for day: CalendarDay) -> some View {
        let date = day.date
        let mu = manUnit(for: date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let isToday = calendar.isDateInToday(date)
        let dayType = HolidayService.dayType(for: date)
        
        return VStack(alignment: .leading, spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 13, weight: isToday ? .bold : .regular))
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

            // ✅ 항상 렌더링 — 공수 없으면 투명으로 자리만 차지해서 모든 셀 높이/너비 통일
            let badgeText = mu > 0 ? formatManUnit(mu) : " "
            let badgeFg: Color = mu > 0 ? .white : .clear
            let badgeBg: Color = mu > 0 ? manUnitColor(mu) : .clear
            Text(badgeText)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(badgeFg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
                .background(badgeBg, in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            if isSelected {
                Color.accentColor.opacity(0.08)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard day.isCurrentMonth else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                if let current = selectedDate, calendar.isDate(current, inSameDayAs: date) {
                    selectedDate = nil
                    isWeekMode = false
                } else {
                    selectedDate = date
                    isWeekMode = true
                }
            }
        }
    }
    
    // MARK: - 월간 그리드 (Canvas 격자 + 높이 고정 분배)
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
    
    // MARK: - 월간 셀 (높이 고정 분배)
    private func monthDayCellView(for day: CalendarDay, height: CGFloat) -> some View {
        let date = day.date
        let mu = manUnit(for: date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let isToday = calendar.isDateInToday(date)
        let dayType = HolidayService.dayType(for: date)
        let memos = dayEntries(for: date).compactMap { $0.memo.isEmpty ? nil : $0.memo }
        
        return VStack(alignment: .leading, spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 13, weight: isToday ? .bold : .regular))
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
            
            if day.isCurrentMonth {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(memos, id: \.self) { memo in
                            Text(memo)
                                .font(.system(size: 7))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if mu > 0 {
                    Text(formatManUnit(mu))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                        .background(manUnitColor(mu), in: RoundedRectangle(cornerRadius: 4))
                }
            } else {
                Spacer()
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background {
            if isSelected {
                Color.accentColor.opacity(0.08)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard day.isCurrentMonth else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                if let current = selectedDate, calendar.isDate(current, inSameDayAs: date) {
                    selectedDate = nil
                    isWeekMode = false
                } else {
                    selectedDate = date
                    isWeekMode = true
                }
            }
        }
    }
    
    // MARK: - 이번 주 통계
    private var weekStatSection: some View {
        let weekEntries = currentWeekDays.map { dayEntries(for: $0.date) }.flatMap { $0 }
        let weekManUnit = weekEntries.reduce(0) { $0 + $1.manUnit }
        let weekNet = weekEntries.reduce(0) { $0 + $1.netAmount }
        
        return HStack {
            Text("이번 주")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(formatManUnit(weekManUnit))공수")
                    .font(.headline.bold())
                    .foregroundStyle(Color.accentColor)
                Text("\(weekNet.formatted())원")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - 기록 Row
    private func entryRow(_ entry: WorkEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.site?.name ?? "현장 미지정")
                        .font(.subheadline.bold())
                    Text(entry.weatherCondition.emoji)
                    if let tag = entry.workTag {
                        Text(tag.rawValue)
                            .font(.caption)
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
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(formatManUnit(entry.manUnit))공수")
                    .font(.subheadline.bold())
                    .foregroundStyle(manUnitColor(entry.manUnit))
                Text("\(entry.netAmount.formatted())원")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.isPaid ? "입금완료" : "미입금")
                    .font(.caption)
                    .foregroundStyle(entry.isPaid ? .green : .secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - 월간 통계
    private var monthSummaryContent: some View {
        let monthEntries = currentMonthEntries
        let totalManUnit = monthEntries.reduce(0.0) { $0 + $1.manUnit }
        let totalTaxable = monthEntries.reduce(0) { $0 + $1.taxableAmount }
        let totalTax = monthEntries.reduce(0) { $0 + $1.tax }
        let totalAllowance = monthEntries.reduce(0) { $0 + $1.allowanceTotal }
        let totalNet = monthEntries.reduce(0) { $0 + $1.netAmount }
        let paidCount = monthEntries.filter { $0.isPaid }.count
        let unpaidAmount = monthEntries.filter { !$0.isPaid }.reduce(0) { $0 + $1.netAmount }
        
        return VStack(spacing: 0) {
            summaryRow(label: "총 공수", value: "\(formatManUnit(totalManUnit))공수", valueColor: .accentColor, bold: true)
            Divider().padding(.leading)
            summaryRow(label: "총 일당", value: "\(totalTaxable.formatted())원")
            Divider().padding(.leading)
            summaryRow(label: "수당 합계", value: "+\(totalAllowance.formatted())원")
            Divider().padding(.leading)
            summaryRow(label: "근로소득세", value: "-\(totalTax.formatted())원", valueColor: .red)
            Divider().padding(.leading)
            summaryRow(label: "실수령액", value: "\(totalNet.formatted())원", valueColor: .accentColor, bold: true)
            Divider().padding(.leading)
            summaryRow(label: "입금 확인", value: "\(paidCount)/\(monthEntries.count)건")
            if unpaidAmount > 0 {
                Divider().padding(.leading)
                summaryRow(label: "미입금 금액", value: "\(unpaidAmount.formatted())원", valueColor: .red, bold: true)
            }
        }
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
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
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
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
        while days.count < 42 {
            if let last = days.last?.date,
               let next = calendar.date(byAdding: .day, value: 1, to: last) {
                days.append(CalendarDay(date: next, isCurrentMonth: false))
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
        let weekday = (calendar.component(.weekday, from: base) - 2 + 7) % 7
        guard let monday = calendar.date(byAdding: .day, value: -weekday, to: base) else { return [] }
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
        entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func manUnit(for date: Date) -> Double {
        dayEntries(for: date).reduce(0) { $0 + $1.manUnit }
    }
    
    private func manUnitColor(_ value: Double) -> Color {
        switch value {
        case 0..<0.1: return .gray
        case 0.1..<1: return .gray.opacity(0.7)
        case 1..<1.5: return .green
        case 1.5..<2: return .blue
        default:      return .red
        }
    }
    
    private func formatManUnit(_ value: Double) -> String {
        String(format: "%g", value)
    }
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: currentMonth)
    }
    
    private func dateTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
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
