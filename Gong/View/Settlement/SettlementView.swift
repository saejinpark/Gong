//
//  SettlementView.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import SwiftUI
import SwiftData

struct SettlementView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [WorkEntry]
    @Query private var sites: [Site]

    @State private var selectedMonth: Date = Calendar.current.startOfMonth(for: .now)
    @State private var shareFile: ShareFile? = nil
    @State private var editingEntry: WorkEntry? = nil
    @State private var errorMessage: String? = nil

    private let calendar = Calendar.current

    private var monthEntries: [WorkEntry] {
        guard let interval = calendar.dateInterval(of: .month, for: selectedMonth) else { return [] }
        return entries
            .filter { interval.contains($0.date) }
            .sorted { ($0.date, $0.createdAt) < ($1.date, $1.createdAt) }
    }

    private var summary: MonthlySummary { MonthlySummary(month: selectedMonth, entries: monthEntries) }
    private var paidCount: Int { summary.entries.count - summary.unpaid.count }
    private var unpaidText: String {
        summary.unpaid.isEmpty ? "없음" : "\(summary.unpaid.count)건 · \(Format.won(summary.unpaidAmount))"
    }
    private var hasUnpaidThisMonth: Bool { !summary.unpaid.isEmpty }
    private var allUnpaidAmount: Int { allUnpaid.reduce(0) { $0 + $1.netAmount } }
    private var yearSummary: MonthlySummary { MonthlySummary(month: selectedMonth, entries: yearEntries) }
    private var yearTitle: String { "\(String(calendar.component(.year, from: selectedMonth)))년 전체" }

    private var yearEntries: [WorkEntry] {
        guard let interval = calendar.dateInterval(of: .year, for: selectedMonth) else { return [] }
        return entries.filter { interval.contains($0.date) }
    }

    private var allUnpaid: [WorkEntry] {
        entries.filter { !$0.isPaid }.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 월 선택
                Section {
                    MonthYearWheelPicker(selectedMonth: $selectedMonth)
                        .frame(height: 120)
                }

                // MARK: - 전체 미입금 (달과 무관)
                if !allUnpaid.isEmpty {
                    Section {
                        NavigationLink {
                            UnpaidListView()
                        } label: {
                            HStack {
                                Label("못 받은 돈 모아보기", systemImage: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(Format.won(allUnpaidAmount))
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.red)
                                        .monospacedDigit()
                                    Text("\(allUnpaid.count)건")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if monthEntries.isEmpty {
                    ContentUnavailableView(
                        "기록 없음",
                        systemImage: "wonsign.circle",
                        description: Text("선택한 달의 공수 기록이 없어요")
                    )
                } else {
                    // MARK: - 실수령 히어로
                    Section {
                        HeroCard(
                            title: "\(calendar.component(.month, from: selectedMonth))월 실수령액",
                            amount: summary.net,
                            caption: "\(Format.manUnit(summary.manUnit))공수 · \(summary.workDays)일 근무 · 하루 평균 \(Format.won(summary.workDays > 0 ? summary.net / summary.workDays : 0))"
                        ) {
                            HStack(spacing: Theme.Spacing.sm) {
                                TagChip(text: "일당 \(summary.taxable.formatted())원", tint: .white.opacity(0.25))
                                if summary.allowance > 0 {
                                    TagChip(text: "수당 +\(summary.allowance.formatted())원", tint: .white.opacity(0.25))
                                }
                                if summary.tax > 0 {
                                    TagChip(text: "세금 -\(summary.tax.formatted())원", tint: .white.opacity(0.25))
                                }
                            }
                            .padding(.top, Theme.Spacing.xs)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    // MARK: - 금액 정산
                    Section("금액 정산") {
                        LabeledContent("일당 합계") {
                            MoneyText(value: summary.taxable)
                        }
                        if summary.allowance > 0 {
                            LabeledContent("수당 합계") {
                                MoneyText(value: summary.allowance, style: .positive)
                            }
                        }
                        LabeledContent("세금") {
                            MoneyText(value: summary.tax, style: .negative)
                        }
                        LabeledContent("실수령액") {
                            MoneyText(value: summary.net, style: .emphasis, font: Theme.Fonts.amount)
                        }
                    }

                    // MARK: - 입금 현황
                    Section("입금 현황") {
                        LabeledContent("입금 완료") {
                            Text("\(paidCount)건")
                                .foregroundStyle(.green)
                                .fontWeight(.medium)
                        }
                        LabeledContent("미입금") {
                            Text(unpaidText)
                                .foregroundStyle(hasUnpaidThisMonth ? Color.red : Color.secondary)
                                .fontWeight(hasUnpaidThisMonth ? .semibold : .regular)
                                .monospacedDigit()
                        }
                        if !summary.unpaid.isEmpty {
                            Button {
                                markAllPaid(summary.unpaid)
                            } label: {
                                Label("이 달 전부 입금 완료로 표시", systemImage: "checkmark.circle")
                            }
                        }
                    }

                    // MARK: - 현장별 집계
                    Section("현장별 집계") {
                        ForEach(summary.siteLines, id: \.name) { line in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(line.name)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text("\(Format.manUnit(line.manUnit))공수")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.accentColor)
                                }
                                HStack {
                                    Text("\(line.days)일")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    if line.unpaid > 0 {
                                        Text("미입금 \(Format.won(line.unpaid))")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                    Text(Format.won(line.net))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    // MARK: - 일별 기록
                    Section("일별 기록") {
                        ForEach(monthEntries) { entry in
                            EntryRow(entry: entry)
                                .contentShape(Rectangle())
                                .onTapGesture { editingEntry = entry }
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
                    }

                    // MARK: - 날씨별 집계
                    Section("날씨별 근무") {
                        ForEach(weatherBreakdown, id: \.condition) { item in
                            LabeledContent("\(item.condition.emoji) \(item.condition.rawValue)") {
                                Text("\(item.days)일")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // MARK: - 연간 요약
                if !yearEntries.isEmpty {
                    let y = yearSummary
                    Section {
                        LabeledContent("총 공수") {
                            Text("\(Format.manUnit(y.manUnit))공수 · \(y.workDays)일")
                                .foregroundStyle(.secondary)
                        }
                        LabeledContent("일당 합계") {
                            Text(Format.won(y.taxable))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        LabeledContent("세금 합계") {
                            Text("-\(Format.won(y.tax))")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        LabeledContent("실수령 합계") {
                            Text(Format.won(y.net))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.accentColor)
                                .monospacedDigit()
                        }
                    } header: {
                        Text(yearTitle)
                    } footer: {
                        Text("일용근로소득은 원천징수로 과세가 끝나 보통 종합소득세 신고가 필요 없어요. 지급명세서 확인이나 소득 증빙이 필요할 때 참고하세요.")
                    }
                }
            }
            .navigationTitle("정산")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !monthEntries.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ShareLink(item: SettlementExporter.text(for: summary)) {
                                Label("정산 내용 공유 (카톡 등)", systemImage: "text.bubble")
                            }
                            ShareLink(item: SettlementExporter.text(for: summary, includeDaily: false)) {
                                Label("요약만 공유", systemImage: "text.alignleft")
                            }
                            Button {
                                exportCSV()
                            } label: {
                                Label("엑셀(CSV) 파일로 내보내기", systemImage: "tablecells")
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("공유")
                    }
                }
            }
            .sheet(item: $shareFile) { file in
                ActivityView(items: [file.url])
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $editingEntry) { entry in
                WorkEntrySheetView(date: entry.date, sites: sites, editingEntry: entry)
            }
            .alert("문제가 생겼어요", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("확인") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - 동작
    private func markAllPaid(_ list: [WorkEntry]) {
        list.forEach { $0.isPaid = true }
        try? context.save()
    }

    private func exportCSV() {
        do {
            let url = try SettlementExporter.writeCSVFile(entries: monthEntries, month: selectedMonth)
            shareFile = ShareFile(url: url)
        } catch {
            errorMessage = "파일을 만들지 못했어요. \(error.localizedDescription)"
        }
    }

    // MARK: - 날씨별 집계
    private struct WeatherBreakdown {
        let condition: WeatherCondition
        let days: Int
    }

    private var weatherBreakdown: [WeatherBreakdown] {
        let grouped = Dictionary(grouping: monthEntries) { $0.weatherCondition }
        return WeatherCondition.allCases.compactMap { condition in
            guard let entries = grouped[condition], !entries.isEmpty else { return nil }
            return WeatherBreakdown(condition: condition, days: entries.count)
        }
    }
}

// MARK: - 전체 미입금 목록
struct UnpaidListView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<WorkEntry> { !$0.isPaid }, sort: \WorkEntry.date) private var unpaid: [WorkEntry]
    @Query private var sites: [Site]

    @State private var editingEntry: WorkEntry? = nil

    private var total: Int { unpaid.reduce(0) { $0 + $1.netAmount } }

    private var bySite: [(name: String, entries: [WorkEntry])] {
        Dictionary(grouping: unpaid) { $0.site?.name ?? "현장 미지정" }
            .map { (name: $0.key, entries: $0.value) }
            .sorted { $0.entries.reduce(0) { $0 + $1.netAmount } > $1.entries.reduce(0) { $0 + $1.netAmount } }
    }

    var body: some View {
        List {
            if unpaid.isEmpty {
                ContentUnavailableView("미입금 없음", systemImage: "checkmark.seal", description: Text("모두 입금 확인됐어요"))
            } else {
                Section {
                    LabeledContent("전체 미입금") {
                        Text("\(unpaid.count)건 · \(Format.won(total))")
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                } footer: {
                    Text("기록을 오른쪽으로 밀면 입금 완료로 바꿀 수 있어요. 눌러서 수정할 수도 있어요.")
                }

                ForEach(bySite, id: \.name) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            EntryRow(entry: entry, showsSite: false)
                                .contentShape(Rectangle())
                                .onTapGesture { editingEntry = entry }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        entry.isPaid = true
                                        try? context.save()
                                    } label: {
                                        Label("입금 완료", systemImage: "checkmark.circle")
                                    }
                                    .tint(.green)
                                }
                        }
                        Button {
                            group.entries.forEach { $0.isPaid = true }
                            try? context.save()
                        } label: {
                            Label("\(group.name) 전부 입금 완료", systemImage: "checkmark.circle")
                                .font(.subheadline)
                        }
                    } header: {
                        HStack {
                            Text(group.name)
                            Spacer()
                            Text(Format.won(group.entries.reduce(0) { $0 + $1.netAmount }))
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .navigationTitle("못 받은 돈")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingEntry) { entry in
            WorkEntrySheetView(date: entry.date, sites: sites, editingEntry: entry)
        }
    }
}

// MARK: - 년/월 Wheel Picker
private struct MonthYearWheelPicker: View {
    @Binding var selectedMonth: Date

    private let calendar = Calendar.current
    private let currentYear = Calendar.current.component(.year, from: .now)

    private var years: [Int] {
        Array((currentYear - 5)...(currentYear + 1))
    }

    @State private var selectedYear: Int
    @State private var selectedMonthInt: Int

    init(selectedMonth: Binding<Date>) {
        self._selectedMonth = selectedMonth
        let cal = Calendar.current
        let y = cal.component(.year, from: selectedMonth.wrappedValue)
        let m = cal.component(.month, from: selectedMonth.wrappedValue)
        self._selectedYear = State(initialValue: y)
        self._selectedMonthInt = State(initialValue: m)
    }

    var body: some View {
        HStack(spacing: 0) {
            Picker("년도", selection: $selectedYear) {
                ForEach(years, id: \.self) { year in
                    Text("\(String(year))년").tag(year)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Picker("월", selection: $selectedMonthInt) {
                ForEach(1...12, id: \.self) { month in
                    Text("\(month)월").tag(month)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .onChange(of: selectedYear) { _, _ in updateBinding() }
        .onChange(of: selectedMonthInt) { _, _ in updateBinding() }
    }

    private func updateBinding() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonthInt
        components.day = 1
        if let date = calendar.date(from: components) {
            selectedMonth = date
        }
    }
}

#Preview {
    SettlementView()
        .modelContainer(for: [Site.self, WorkEntry.self], inMemory: true)
}
