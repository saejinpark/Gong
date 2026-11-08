//
//  WorkEntrySheetView.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import SwiftUI
import SwiftData

struct WorkEntrySheetView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppDefaults.defaultTaxModeKey) private var defaultTaxModeRaw: String = TaxMode.withholding.rawValue
    @AppStorage(AppDefaults.defaultWageKey) private var appDefaultWage: Int = 0
    @AppStorage(AppDefaults.defaultMealKey) private var appDefaultMeal: Int = 0

    let date: Date
    let sites: [Site]
    let editingEntry: WorkEntry?
    /// 최근에 기록한 현장 — 새 기록일 때 자동 선택
    var suggestedSite: Site? = nil

    @State private var selectedSite: Site? = nil
    @State private var manUnit: Double = 1
    @State private var wage: Int = 0
    @State private var mealAllowance: Int = 0
    @State private var lodgingAllowance: Int = 0
    @State private var transportAllowance: Int = 0
    @State private var dayType: DayType = .weekday
    @State private var taxMode: TaxMode = .withholding
    @State private var weatherCondition: WeatherCondition = .sunny
    @State private var workTag: WorkTag? = nil
    @State private var memo: String = ""
    @State private var isPaid: Bool = false
    @State private var isShowingSiteForm: Bool = false
    @State private var isShowingDeleteAlert: Bool = false
    @State private var isMultiDay: Bool = false
    @State private var multiDates: Set<DateComponents> = []
    @State private var showAllowances: Bool = false
    @State private var didLoad = false

    @FocusState private var focusedField: Field?
    enum Field { case wage, meal, lodging, transport, memo }

    private let calendar = Calendar.current

    private var activeSites: [Site] { sites.filter { $0.isActive } }
    private var taxableAmount: Int { PayCalculator.taxable(manUnit: manUnit, wage: wage) }
    private var allowanceTotal: Int { mealAllowance + lodgingAllowance + transportAllowance }
    private var taxBreakdown: TaxBreakdown { PayCalculator.tax(taxable: taxableAmount, mode: taxMode) }
    private var netAmount: Int { PayCalculator.net(taxable: taxableAmount, tax: taxBreakdown, allowances: allowanceTotal) }
    private var isValid: Bool {
        guard wage > 0 || manUnit == 0 else { return false }
        return !isMultiDay || !multiDates.isEmpty
    }
    private var isEditing: Bool { editingEntry != nil }
    private var autoDayType: DayType { HolidayService.dayType(for: date) }
    private var holidayName: String? { HolidayService.holidayName(for: date) }

    var body: some View {
        NavigationStack {
            Form {
                dateSection
                siteSection
                manUnitSection
                wageSection
                summarySection
                allowanceSection
                detailSection
                paidSection
                if isEditing { deleteSection }
            }
            .navigationTitle(isEditing ? "공수 수정" : "공수 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isMultiDay ? "\(multiDates.count)일 저장" : "저장") { save() }
                        .fontWeight(.semibold)
                        .tint(Color.accentColor)
                        .disabled(!isValid)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("완료") { focusedField = nil }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .onAppear { loadInitialValues() }
            .onChange(of: selectedSite) { _, newSite in
                guard didLoad, !isEditing else { return }
                applySiteDefaults(newSite)
            }
            .sheet(isPresented: $isShowingSiteForm) {
                SiteFormView { newSite in
                    selectedSite = newSite
                    applySiteDefaults(newSite)
                }
            }
            .alert("기록을 삭제할까요?", isPresented: $isShowingDeleteAlert) {
                Button("삭제", role: .destructive) { delete() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("삭제된 기록은 복구할 수 없어요")
            }
        }
    }

    // MARK: - 날짜
    private var dateSection: some View {
        Section {
            if isEditing || !isMultiDay {
                LabeledContent("날짜") {
                    HStack(spacing: 6) {
                        Text(Format.dayTitle.string(from: date))
                        if let holidayName {
                            Text(holidayName)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            if !isEditing {
                Toggle("여러 날 한 번에 기록", isOn: $isMultiDay.animation())
                    .tint(.accentColor)
                if isMultiDay {
                    MultiDatePicker("날짜 선택", selection: $multiDates)
                        .environment(\.locale, Locale(identifier: "ko_KR"))
                }
            }
            Picker("구분", selection: $dayType) {
                ForEach(DayType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
        } footer: {
            if isMultiDay {
                Text("선택한 날짜마다 아래 내용으로 기록이 하나씩 만들어져요. 평일·토요일·공휴일 구분은 날짜마다 자동으로 정해져요.")
            } else if dayType != autoDayType {
                Text("달력 기준은 \(autoDayType.rawValue)이지만 직접 바꿨어요.")
            }
        }
    }

    // MARK: - 현장
    private var siteSection: some View {
        Section("현장") {
            if activeSites.isEmpty {
                Button {
                    isShowingSiteForm = true
                } label: {
                    Label("현장 빠른 등록", systemImage: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            } else {
                Picker("현장 선택", selection: $selectedSite) {
                    Text("선택 안 함").tag(Optional<Site>.none)
                    ForEach(activeSites) { site in
                        Text(site.name).tag(Optional(site))
                    }
                }
                Button {
                    isShowingSiteForm = true
                } label: {
                    Label("현장 추가", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    // MARK: - 공수
    private var manUnitSection: some View {
        Section {
            presetGrid
            Stepper(value: $manUnit, in: 0...10, step: 0.5) {
                HStack {
                    Text("공수")
                    Spacer()
                    Text(Format.manUnit(manUnit))
                        .foregroundStyle(Color.manUnit(manUnit))
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
            }
        } header: {
            Text("공수")
        } footer: {
            Text("0.5 단위로 조절돼요. 잔업·야간은 현장에서 정한 공수로 넣어 주세요.")
        }
    }

    // MARK: - 단가
    private var wageSection: some View {
        Section {
            HStack {
                Text("1공수 단가")
                Spacer()
                TextField("0", value: $wage, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .wage)
                Text("원").foregroundStyle(.secondary)
            }
            Picker("세금 방식", selection: $taxMode) {
                ForEach(TaxMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
        } header: {
            Text("단가·세금")
        }
    }

    // MARK: - 예상 실수령액
    private var summarySection: some View {
        Section("예상 실수령액") {
            LabeledContent("일당 (\(Format.manUnit(manUnit))공수)") {
                Text(Format.won(taxableAmount))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            if allowanceTotal > 0 {
                LabeledContent("수당") {
                    Text("+\(Format.won(allowanceTotal))")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            LabeledContent("세금") {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("-\(Format.won(taxBreakdown.total))")
                        .foregroundStyle(taxBreakdown.total > 0 ? .red : .secondary)
                        .monospacedDigit()
                    if taxBreakdown.total > 0 {
                        Text("소득세 \(taxBreakdown.incomeTax.formatted()) + 지방세 \(taxBreakdown.localTax.formatted())")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            LabeledContent("실수령액") {
                Text(Format.won(netAmount))
                    .font(.title3.bold())
                    .foregroundStyle(Color.accentColor)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - 수당
    private var allowanceSection: some View {
        Section {
            DisclosureGroup(isExpanded: $showAllowances) {
                allowanceField("식대", value: $mealAllowance, field: .meal)
                allowanceField("숙박비", value: $lodgingAllowance, field: .lodging)
                allowanceField("교통비", value: $transportAllowance, field: .transport)
            } label: {
                HStack {
                    Text("수당 (비과세)")
                    Spacer()
                    if allowanceTotal > 0 {
                        Text("+\(Format.won(allowanceTotal))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func allowanceField(_ title: String, value: Binding<Int>, field: Field) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: field)
            Text("원").foregroundStyle(.secondary)
        }
    }

    // MARK: - 날씨 · 태그 · 메모
    private var detailSection: some View {
        Section("날씨 · 특이사항") {
            Picker("날씨", selection: $weatherCondition) {
                ForEach(WeatherCondition.allCases, id: \.self) { condition in
                    Text(condition.emoji).tag(condition)
                }
            }
            .pickerStyle(.segmented)

            Picker("태그", selection: $workTag) {
                Text("없음").tag(Optional<WorkTag>.none)
                ForEach(WorkTag.allCases, id: \.self) { tag in
                    Text(tag.rawValue).tag(Optional(tag))
                }
            }

            TextField("메모 (예: 거푸집 해체, 2시 조퇴)", text: $memo, axis: .vertical)
                .lineLimit(1...3)
                .focused($focusedField, equals: .memo)
        }
    }

    // MARK: - 입금 확인
    private var paidSection: some View {
        Section {
            Toggle("입금 확인", isOn: $isPaid)
                .tint(Color.accentColor)
        } footer: {
            Text("돈이 들어오면 체크해 두세요. 정산 탭에서 미입금만 모아볼 수 있어요.")
        }
    }

    // MARK: - 삭제
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                isShowingDeleteAlert = true
            } label: {
                Text("기록 삭제")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - 프리셋 그리드
    private var presetGrid: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 8) {
            ForEach(manUnitPresets, id: \.value) { preset in
                presetButton(preset: preset)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func presetButton(preset: (label: String, value: Double)) -> some View {
        let isSelected = abs(manUnit - preset.value) < 0.001
        let bg = isSelected ? Color.manUnit(preset.value) : Color(.systemGray6)
        let fg: Color = isSelected ? .white : .primary

        Button {
            manUnit = preset.value
            focusedField = nil
        } label: {
            VStack(spacing: 2) {
                Text(Format.manUnit(preset.value))
                    .font(.subheadline.bold())
                Text(preset.label)
                    .font(.caption2)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(bg, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.label) \(Format.manUnit(preset.value))공수")
    }

    private var manUnitPresets: [(label: String, value: Double)] {[
        ("결근", 0.0),
        ("반공수", 0.5),
        ("정상", 1.0),
        ("잔업", 1.5),
        ("특근", 2.0),
    ]}

    // MARK: - 초기값 로드
    private func loadInitialValues() {
        defer { didLoad = true }
        if let entry = editingEntry {
            selectedSite = entry.site
            manUnit = entry.manUnit
            wage = entry.wage
            mealAllowance = entry.mealAllowance
            lodgingAllowance = entry.lodgingAllowance
            transportAllowance = entry.transportAllowance
            dayType = entry.dayType
            taxMode = entry.taxMode
            weatherCondition = entry.weatherCondition
            workTag = entry.workTag
            memo = entry.memo
            isPaid = entry.isPaid
            showAllowances = entry.allowanceTotal > 0
        } else {
            dayType = autoDayType
            let site = suggestedSite.flatMap { $0.isActive ? $0 : nil } ?? activeSites.first
            selectedSite = site
            applySiteDefaults(site)
            multiDates = [calendar.dateComponents([.calendar, .era, .year, .month, .day], from: date)]
        }
    }

    private func applySiteDefaults(_ site: Site?) {
        if let site {
            wage = site.defaultWage
            mealAllowance = site.defaultMealAllowance
            taxMode = site.taxMode
        } else {
            wage = appDefaultWage
            mealAllowance = appDefaultMeal
            taxMode = TaxMode(rawValue: defaultTaxModeRaw) ?? .withholding
        }
        showAllowances = showAllowances || mealAllowance > 0
    }

    // MARK: - 저장
    private func save() {
        if let entry = editingEntry {
            entry.site = selectedSite
            entry.manUnit = manUnit
            entry.wage = wage
            entry.mealAllowance = mealAllowance
            entry.lodgingAllowance = lodgingAllowance
            entry.transportAllowance = transportAllowance
            entry.dayType = dayType
            entry.taxMode = taxMode
            entry.weatherCondition = weatherCondition
            entry.workTag = workTag
            entry.memo = memo
            entry.isPaid = isPaid
        } else {
            let dates: [Date]
            if isMultiDay {
                dates = multiDates.compactMap { calendar.date(from: $0) }.sorted()
            } else {
                dates = [date]
            }
            for day in dates {
                let normalized = calendar.startOfDay(for: day)
                let entry = WorkEntry(
                    date: normalized,
                    manUnit: manUnit,
                    wage: wage,
                    mealAllowance: mealAllowance,
                    lodgingAllowance: lodgingAllowance,
                    transportAllowance: transportAllowance,
                    dayType: isMultiDay ? HolidayService.dayType(for: normalized) : dayType,
                    weatherCondition: weatherCondition,
                    workTag: workTag,
                    memo: memo,
                    isPaid: isPaid,
                    site: selectedSite,
                    taxMode: taxMode
                )
                context.insert(entry)
            }
        }
        try? context.save()
        dismiss()
    }

    // MARK: - 삭제
    private func delete() {
        if let entry = editingEntry {
            context.delete(entry)
            try? context.save()
        }
        dismiss()
    }
}

#Preview {
    WorkEntrySheetView(date: .now, sites: [], editingEntry: nil)
        .modelContainer(for: [Site.self, WorkEntry.self], inMemory: true)
}
