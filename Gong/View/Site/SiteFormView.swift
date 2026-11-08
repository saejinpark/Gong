//
//  SiteFormView.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import SwiftUI
import SwiftData

struct SiteFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppDefaults.defaultTaxModeKey) private var defaultTaxModeRaw: String = TaxMode.withholding.rawValue
    @AppStorage(AppDefaults.defaultWageKey) private var appDefaultWage: Int = 0
    @AppStorage(AppDefaults.defaultMealKey) private var appDefaultMeal: Int = 0

    @Query private var allSites: [Site]

    var editingSite: Site? = nil
    /// 저장 직후 호출 — 공수 입력 시트에서 "현장 빠른 등록" 후 바로 선택되게
    var onSave: ((Site) -> Void)? = nil

    @State private var name: String = ""
    @State private var defaultWage: Int = 0
    @State private var defaultMeal: Int = 0
    @State private var taxMode: TaxMode = .withholding
    @State private var colorIndex: Int = 0
    @State private var startDate: Date = .now
    @State private var location: String = ""
    @State private var memo: String = ""
    @State private var isActive: Bool = true

    @FocusState private var focusedField: Field?

    enum Field { case name, wage, meal, location, memo }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && defaultWage > 0
    }

    private var monthlyEstimate: (gross: Int, net: Int) {
        let days = 22
        let dailyTax = PayCalculator.tax(taxable: defaultWage, mode: taxMode).total
        return (defaultWage * days, (defaultWage - dailyTax + defaultMeal) * days)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 기본 정보
                Section("현장 정보") {
                    LabeledContent("현장명") {
                        TextField("평택 1공구", text: $name)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .wage }
                    }

                    colorPicker

                    DatePicker(
                        "시작일",
                        selection: $startDate,
                        displayedComponents: .date
                    )

                    LabeledContent("위치") {
                        TextField("경기도 평택시", text: $location)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .location)
                    }
                }

                // MARK: - 단가
                Section {
                    LabeledContent("1공수 단가") {
                        HStack {
                            TextField("0", value: $defaultWage, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .wage)
                            Text("원")
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    LabeledContent("기본 식대") {
                        HStack {
                            TextField("0", value: $defaultMeal, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .meal)
                            Text("원")
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    Picker("세금 방식", selection: $taxMode) {
                        ForEach(TaxMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                } header: {
                    Text("단가·세금")
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(taxMode.detail)
                        if defaultWage > 0 {
                            Text("22일 기준 월 \(Format.won(monthlyEstimate.gross)) → 실수령 약 \(Format.won(monthlyEstimate.net))")
                                .foregroundStyle(Theme.Colors.brand)
                        }
                    }
                }

                // MARK: - 메모
                Section("메모") {
                    TextField("공종, 반장 연락처, 참고사항 등", text: $memo, axis: .vertical)
                        .lineLimit(3)
                        .focused($focusedField, equals: .memo)
                }

                // MARK: - 상태
                if editingSite != nil {
                    Section {
                        Toggle("진행중", isOn: $isActive)
                            .tint(Theme.Colors.brand)
                    } footer: {
                        Text("끝난 현장은 꺼 두면 공수 입력 목록에서 사라져요. 기록은 그대로 남아요.")
                    }
                }
            }
            .navigationTitle(editingSite == nil ? "현장 추가" : "현장 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(editingSite == nil ? "추가" : "저장") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .tint(Theme.Colors.brand)
                    .disabled(!isValid)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("완료") { focusedField = nil }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .onAppear { loadInitialValues() }
        }
    }

    // MARK: - 색 선택
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("구분 색")
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(Theme.Colors.sitePalette.indices, id: \.self) { index in
                    Button {
                        colorIndex = index
                    } label: {
                        Circle()
                            .fill(Theme.Colors.site(index))
                            .frame(width: 30, height: 30)
                            .overlay {
                                if colorIndex == index {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("색 \(index + 1)")
                    .accessibilityAddTraits(colorIndex == index ? .isSelected : [])
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - 초기값 로드
    private func loadInitialValues() {
        if let site = editingSite {
            name = site.name
            defaultWage = site.defaultWage
            defaultMeal = site.defaultMealAllowance
            taxMode = site.taxMode
            colorIndex = site.colorIndex
            startDate = site.startDate
            location = site.location
            memo = site.memo
            isActive = site.isActive
        } else {
            taxMode = TaxMode(rawValue: defaultTaxModeRaw) ?? .withholding
            defaultWage = appDefaultWage
            defaultMeal = appDefaultMeal
            // 아직 안 쓰인 색을 먼저 제안
            let used = Set(allSites.map { $0.colorIndex })
            colorIndex = Theme.Colors.sitePalette.indices.first { !used.contains($0) } ?? (allSites.count % Theme.Colors.sitePalette.count)
            if name.isEmpty {
                focusedField = .name
            }
        }
    }

    // MARK: - 저장
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let savedSite: Site
        if let site = editingSite {
            site.name = trimmedName
            site.defaultWage = defaultWage
            site.defaultMealAllowance = defaultMeal
            site.taxMode = taxMode
            site.colorIndex = colorIndex
            site.startDate = startDate
            site.location = location
            site.memo = memo
            site.isActive = isActive
            savedSite = site
        } else {
            let site = Site(
                name: trimmedName,
                defaultWage: defaultWage,
                startDate: startDate,
                location: location,
                memo: memo,
                taxMode: taxMode,
                defaultMealAllowance: defaultMeal,
                colorIndex: colorIndex
            )
            context.insert(site)
            savedSite = site
        }
        try? context.save()
        onSave?(savedSite)
        dismiss()
    }
}

#Preview {
    SiteFormView()
        .modelContainer(for: [Site.self, WorkEntry.self], inMemory: true)
}
