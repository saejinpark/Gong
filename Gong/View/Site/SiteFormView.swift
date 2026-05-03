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
    
    var editingSite: Site? = nil
    
    @State private var name: String = ""
    @State private var defaultWage: Int = 0
    @State private var startDate: Date = .now
    @State private var location: String = ""
    @State private var memo: String = ""
    @State private var isActive: Bool = true
    
    @FocusState private var focusedField: Field?
    
    enum Field { case name, wage, location, memo }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && defaultWage > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 기본 정보
                Section("현장 정보") {
                    LabeledContent("현장명") {
                        TextField("평택삼성 1공구", text: $name)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .name)
                    }
                    
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
                Section("기본 단가") {
                    LabeledContent("1공수 단가") {
                        HStack {
                            TextField("0", value: $defaultWage, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .wage)
                            Text("원")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if defaultWage > 0 {
                        LabeledContent("월 예상 수입 (22일)") {
                            Text("\((defaultWage * 22).formatted())원")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // MARK: - 메모
                Section("메모") {
                    TextField("공종, 참고사항 등", text: $memo, axis: .vertical)
                        .lineLimit(3)
                        .focused($focusedField, equals: .memo)
                }
                
                // MARK: - 상태
                if editingSite != nil {
                    Section {
                        Toggle("진행중", isOn: $isActive)
                            .tint(.accentColor)
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
                    .tint(.accentColor)
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
    
    // MARK: - 초기값 로드
    private func loadInitialValues() {
        guard let site = editingSite else { return }
        name = site.name
        defaultWage = site.defaultWage
        startDate = site.startDate
        location = site.location
        memo = site.memo
        isActive = site.isActive
    }
    
    // MARK: - 저장
    private func save() {
        if let site = editingSite {
            site.name = name
            site.defaultWage = defaultWage
            site.startDate = startDate
            site.location = location
            site.memo = memo
            site.isActive = isActive
        } else {
            let site = Site(
                name: name,
                defaultWage: defaultWage,
                startDate: startDate,
                location: location,
                memo: memo
            )
            context.insert(site)
        }
        try? context.save()
        dismiss()
    }
}

#Preview {
    SiteFormView()
        .modelContainer(for: [Site.self, WorkEntry.self], inMemory: true)
}
