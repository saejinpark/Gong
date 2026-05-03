//
//  SettlementView.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import SwiftUI
import SwiftData

struct SettlementView: View {
    @Query private var entries: [WorkEntry]

    @State private var selectedMonth: Date = Calendar.current.startOfMonth(for: .now)

    private let calendar = Calendar.current

    private var monthEntries: [WorkEntry] {
        guard let interval = calendar.dateInterval(of: .month, for: selectedMonth) else { return [] }
        return entries
            .filter { interval.contains($0.date) }
            .sorted { $0.date < $1.date }
    }

    private var totalManUnit: Double   { monthEntries.reduce(0) { $0 + $1.manUnit } }
    private var totalTaxable: Int      { monthEntries.reduce(0) { $0 + $1.taxableAmount } }
    private var totalAllowance: Int    { monthEntries.reduce(0) { $0 + $1.allowanceTotal } }
    private var totalTax: Int          { monthEntries.reduce(0) { $0 + $1.tax } }
    private var totalNet: Int          { monthEntries.reduce(0) { $0 + $1.netAmount } }
    private var paidEntries: [WorkEntry]   { monthEntries.filter { $0.isPaid } }
    private var unpaidEntries: [WorkEntry] { monthEntries.filter { !$0.isPaid } }
    private var unpaidAmount: Int      { unpaidEntries.reduce(0) { $0 + $1.netAmount } }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 월 선택 (Wheel: 년 / 월)
                Section {
                    MonthYearWheelPicker(selectedMonth: $selectedMonth)
                        .frame(height: 120)
                }

                if monthEntries.isEmpty {
                    ContentUnavailableView(
                        "기록 없음",
                        systemImage: "wonsign.circle",
                        description: Text("선택한 달의 공수 기록이 없어요")
                    )
                } else {
                    // MARK: - 공수 요약
                    Section("공수 요약") {
                        LabeledContent("총 근무일수") {
                            Text("\(monthEntries.count)일")
                                .foregroundStyle(.secondary)
                        }
                        LabeledContent("총 공수") {
                            Text("\(formatManUnit(totalManUnit))공수")
                                .foregroundStyle(Color.accentColor)
                                .fontWeight(.semibold)
                        }
                    }

                    // MARK: - 금액 정산
                    Section("금액 정산") {
                        LabeledContent("총 일당") {
                            Text("\(totalTaxable.formatted())원")
                                .foregroundStyle(.secondary)
                        }
                        LabeledContent("수당 합계") {
                            Text("+\(totalAllowance.formatted())원")
                                .foregroundStyle(.secondary)
                        }
                        LabeledContent("근로소득세") {
                            Text("-\(totalTax.formatted())원")
                                .foregroundStyle(.red)
                        }
                        LabeledContent("실수령액") {
                            Text("\(totalNet.formatted())원")
                                .fontWeight(.bold)
                                .foregroundStyle(Color.accentColor)
                        }
                    }

                    // MARK: - 입금 현황
                    Section("입금 현황") {
                        LabeledContent("입금 완료") {
                            Text("\(paidEntries.count)건")
                                .foregroundStyle(.green)
                                .fontWeight(.medium)
                        }
                        LabeledContent("미입금") {
                            let color: Color = unpaidEntries.isEmpty ? .secondary : .red
                            let weight: Font.Weight = unpaidEntries.isEmpty ? .regular : .medium
                            Text("\(unpaidEntries.count)건")
                                .foregroundStyle(color)
                                .fontWeight(weight)
                        }
                        if !unpaidEntries.isEmpty {
                            LabeledContent("미입금 금액") {
                                Text("\(unpaidAmount.formatted())원")
                                    .foregroundStyle(.red)
                                    .fontWeight(.semibold)
                            }
                        }
                    }

                    // MARK: - 현장별 집계
                    Section("현장별 집계") {
                        ForEach(siteBreakdown, id: \.siteName) { breakdown in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(breakdown.siteName)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text("\(formatManUnit(breakdown.manUnit))공수")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.accentColor)
                                }
                                HStack {
                                    Text("\(breakdown.days)일")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(breakdown.netAmount.formatted())원")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
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
            }
            .navigationTitle("정산")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - 현장별 집계
    private struct SiteBreakdown {
        let siteName: String
        let days: Int
        let manUnit: Double
        let netAmount: Int
    }

    private var siteBreakdown: [SiteBreakdown] {
        let grouped = Dictionary(grouping: monthEntries) { $0.site?.name ?? "현장 미지정" }
        return grouped.map { name, entries in
            SiteBreakdown(
                siteName: name,
                days: entries.count,
                manUnit: entries.reduce(0) { $0 + $1.manUnit },
                netAmount: entries.reduce(0) { $0 + $1.netAmount }
            )
        }
        .sorted {
            if $0.manUnit != $1.manUnit { return $0.manUnit > $1.manUnit }
            return $0.siteName < $1.siteName
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

    private func formatManUnit(_ value: Double) -> String {
        String(format: "%g", value)
    }
}

// MARK: - 년/월 Wheel Picker (일 없음)
private struct MonthYearWheelPicker: View {
    @Binding var selectedMonth: Date

    private let calendar = Calendar.current
    private let currentYear = Calendar.current.component(.year, from: .now)
    private let currentMonth = Calendar.current.component(.month, from: .now)

    private var years: [Int] {
        Array((currentYear - 5)...currentYear)
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

    // 선택 가능한 최대 월 (미래 방지)
    private var maxMonth: Int {
        selectedYear == currentYear ? currentMonth : 12
    }

    var body: some View {
        HStack(spacing: 0) {
            // 년도 컬럼
            Picker("년도", selection: $selectedYear) {
                ForEach(years, id: \.self) { year in
                    Text("\(String(year))년").tag(year)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            // 월 컬럼
            Picker("월", selection: $selectedMonthInt) {
                ForEach(1...12, id: \.self) { month in
                    Text("\(month)월").tag(month)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .onChange(of: selectedYear) { _, newYear in
            // 미래 월 보정: 올해로 바꿨는데 월이 현재보다 미래면 현재 월로
            if newYear == currentYear && selectedMonthInt > currentMonth {
                selectedMonthInt = currentMonth
            }
            updateBinding()
        }
        .onChange(of: selectedMonthInt) { _, _ in
            updateBinding()
        }
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
