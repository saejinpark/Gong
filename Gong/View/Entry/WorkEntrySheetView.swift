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
    
    let date: Date
    let sites: [Site]
    let editingEntry: WorkEntry?
    
    @State private var selectedSite: Site? = nil
    @State private var manUnitText: String = "1"
    @State private var wage: Int = 0
    @State private var mealAllowance: Int = 0
    @State private var lodgingAllowance: Int = 0
    @State private var transportAllowance: Int = 0
    @State private var weatherCondition: WeatherCondition = .sunny
    @State private var workTag: WorkTag? = nil
    @State private var memo: String = ""
    @State private var isPaid: Bool = false
    @State private var isShowingSiteForm: Bool = false
    @State private var isShowingDeleteAlert: Bool = false
    
    @FocusState private var focusedField: Field?
    enum Field { case wage, meal, lodging, transport, memo }
    
    private var activeSites: [Site] { sites.filter { $0.isActive } }
    private var manUnit: Double { Double(manUnitText) ?? 0 }
    private var taxableAmount: Int { Int(manUnit * Double(wage)) }
    private var allowanceTotal: Int { mealAllowance + lodgingAllowance + transportAllowance }
    private var tax: Int {
        let base = taxableAmount - 150_000
        guard base > 0 else { return 0 }
        let incomeTax = Int(Double(base) * 0.06 * 0.45)
        let localTax = Int(Double(incomeTax) * 0.1)
        return incomeTax + localTax
    }
    private var netAmount: Int { taxableAmount - tax + allowanceTotal }
    private var isValid: Bool { manUnit > 0 && wage > 0 }
    private var isEditing: Bool { editingEntry != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 현장
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
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                
                // MARK: - 날씨 + 태그
                Section {
                    Picker("날씨", selection: $weatherCondition) {
                        ForEach(WeatherCondition.allCases, id: \.self) { condition in
                            Text("\(condition.emoji) \(condition.rawValue)").tag(condition)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("태그", selection: $workTag) {
                        Text("없음").tag(Optional<WorkTag>.none)
                        ForEach(WorkTag.allCases, id: \.self) { tag in
                            Text(tag.rawValue).tag(Optional(tag))
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // MARK: - 공수
                Section("공수") {
                    presetGrid
                    
                    Stepper(value: Binding(
                        get: { manUnit },
                        set: { manUnitText = formatManUnit($0) }
                    ), in: 0...8, step: 0.1) {
                        HStack {
                            Spacer()
                            Text(formatManUnit(manUnit))
                                .foregroundStyle(Color.accentColor)
                                .fontWeight(.semibold)
                            Text("공수")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // MARK: - 단가
                Section("단가") {
                    HStack {
                        TextField("0", value: $wage, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .wage)
                        Text("원")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // MARK: - 예상 실수령액
                Section("예상 실수령액") {
                    LabeledContent("일당") {
                        Text("\(taxableAmount.formatted())원")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("수당 합계") {
                        Text("+\(allowanceTotal.formatted())원")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("근로소득세") {
                        Text("-\(tax.formatted())원")
                            .foregroundStyle(.red)
                    }
                    LabeledContent("실수령액") {
                        Text("\(netAmount.formatted())원")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                
                // MARK: - 수당
                Section("수당 (비과세)") {
                    LabeledContent("식대") {
                        HStack {
                            TextField("0", value: $mealAllowance, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .meal)
                            Text("원")
                                .foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent("숙박비") {
                        HStack {
                            TextField("0", value: $lodgingAllowance, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .lodging)
                            Text("원")
                                .foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent("교통비") {
                        HStack {
                            TextField("0", value: $transportAllowance, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .transport)
                            Text("원")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // MARK: - 메모
                Section("메모") {
                    TextField("우천, 조기퇴근 등", text: $memo, axis: .vertical)
                        .lineLimit(3)
                        .focused($focusedField, equals: .memo)
                }
                
                // MARK: - 입금 확인
                Section {
                    Toggle("입금 확인", isOn: $isPaid)
                        .tint(Color.accentColor)
                }
                
                // MARK: - 삭제
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            isShowingDeleteAlert = true
                        } label: {
                            Text("기록 삭제")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "공수 수정" : "공수 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") { save() }
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
                if !isEditing {
                    wage = newSite?.defaultWage ?? 0
                }
            }
            .sheet(isPresented: $isShowingSiteForm) {
                SiteFormView()
            }
            .alert("기록을 삭제할까요?", isPresented: $isShowingDeleteAlert) {
                Button("삭제", role: .destructive) { delete() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("삭제된 기록은 복구할 수 없어요")
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
        let isSelected = isSelectedPreset(preset.value)
        let bg = isSelected ? manUnitColor(preset.value) : Color(.systemGray6)
        let fg: Color = isSelected ? .white : .primary
        let weight: Font.Weight = isSelected ? .bold : .regular
        
        Button {
            manUnitText = formatManUnit(preset.value)
            focusedField = nil
        } label: {
            Text(preset.label)
                .font(.system(size: 11, weight: weight))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(fg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(bg, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 공수 프리셋
    private var manUnitPresets: [(label: String, value: Double)] {[
        ("결근\n0", 0.0),
        ("반공수\n0.5", 0.5),
        ("정상\n1.0", 1.0),
        ("잔업\n1.5", 1.5),
        ("특근\n2.0", 2.0),
        ("공휴\n2.5", 2.5),
        ("공휴+\n3.0", 3.0),
        ("공휴야\n3.5", 3.5),
        ("심야\n4.0", 4.0),
        ("철야\n6.0", 6.0),
    ]}
    
    private func isSelectedPreset(_ value: Double) -> Bool {
        abs(manUnit - value) < 0.001
    }
    
    private func formatManUnit(_ value: Double) -> String {
        String(format: "%g", value)
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
    
    // MARK: - 초기값 로드
    private func loadInitialValues() {
        if let entry = editingEntry {
            selectedSite = entry.site
            manUnitText = formatManUnit(entry.manUnit)
            wage = entry.wage
            mealAllowance = entry.mealAllowance
            lodgingAllowance = entry.lodgingAllowance
            transportAllowance = entry.transportAllowance
            weatherCondition = entry.weatherCondition
            workTag = entry.workTag
            memo = entry.memo
            isPaid = entry.isPaid
        } else {
            selectedSite = activeSites.first
            wage = selectedSite?.defaultWage ?? 0
        }
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
            entry.dayType = HolidayService.dayType(for: date)
            entry.weatherCondition = weatherCondition
            entry.workTag = workTag
            entry.memo = memo
            entry.isPaid = isPaid
        } else {
            let entry = WorkEntry(
                date: date,
                manUnit: manUnit,
                wage: wage,
                mealAllowance: mealAllowance,
                lodgingAllowance: lodgingAllowance,
                transportAllowance: transportAllowance,
                dayType: HolidayService.dayType(for: date),
                weatherCondition: weatherCondition,
                workTag: workTag,
                memo: memo,
                isPaid: isPaid,
                site: selectedSite
            )
            context.insert(entry)
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
