//
//  SiteDetailView.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import SwiftUI
import SwiftData

struct SiteDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let site: Site
    
    @State private var isShowingForm: Bool = false
    @State private var isShowingDeleteAlert: Bool = false
    @State private var isShowingSheet: Bool = false
    @State private var editingEntry: WorkEntry? = nil
    
    @Query private var allSites: [Site]
    
    private var sortedEntries: [WorkEntry] {
        site.entries.sorted { $0.date > $1.date }
    }
    
    private var totalManUnit: Double {
        site.entries.reduce(0) { $0 + $1.manUnit }
    }
    
    private var totalNetAmount: Int {
        site.entries.reduce(0) { $0 + $1.netAmount }
    }
    
    private var canDelete: Bool {
        site.entries.isEmpty
    }
    
    var body: some View {
        List {
            // MARK: - 현장 정보
            Section("현장 정보") {
                LabeledContent("기본 단가") {
                    Text("\(site.defaultWage.formatted())원")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.semibold)
                }
                LabeledContent("시작일") {
                    Text(site.startDate.formatted(date: .abbreviated, time: .omitted))
                        .foregroundStyle(.secondary)
                }
                if !site.location.isEmpty {
                    LabeledContent("위치") {
                        Text(site.location)
                            .foregroundStyle(.secondary)
                    }
                }
                if !site.memo.isEmpty {
                    LabeledContent("메모") {
                        Text(site.memo)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
                LabeledContent("상태") {
                    Text(site.isActive ? "진행중" : "종료")
                        .foregroundStyle(site.isActive ? .green : .secondary)
                        .fontWeight(.medium)
                }
            }
            
            // MARK: - 누적 집계
            Section("누적 집계") {
                LabeledContent("총 공수") {
                    Text("\(formatManUnit(totalManUnit))공수")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.semibold)
                }
                LabeledContent("총 실수령액") {
                    Text("\(totalNetAmount.formatted())원")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.semibold)
                }
                LabeledContent("근무일수") {
                    Text("\(site.entries.count)일")
                        .foregroundStyle(.secondary)
                }
            }
            
            // MARK: - 공수 기록
            Section("공수 기록") {
                if sortedEntries.isEmpty {
                    ContentUnavailableView(
                        "기록 없음",
                        systemImage: "doc.text",
                        description: Text("이 현장의 공수 기록이 없어요")
                    )
                } else {
                    ForEach(sortedEntries) { entry in
                        entryRow(entry)
                            .onTapGesture {
                                editingEntry = entry
                                isShowingSheet = true
                            }
                    }
                    .onDelete { offsets in
                        deleteEntries(at: offsets)
                    }
                }
            }
            
            // MARK: - 삭제
            if canDelete {
                Section {
                    Button(role: .destructive) {
                        isShowingDeleteAlert = true
                    } label: {
                        Text("현장 삭제")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .navigationTitle(site.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("수정") {
                    isShowingForm = true
                }
                .tint(.accentColor)
            }
        }
        .sheet(isPresented: $isShowingForm) {
            SiteFormView(editingSite: site)
        }
        .sheet(isPresented: $isShowingSheet) {
            if let entry = editingEntry {
                WorkEntrySheetView(
                    date: entry.date,
                    sites: allSites,
                    editingEntry: entry
                )
            }
        }
        .alert("현장을 삭제할까요?", isPresented: $isShowingDeleteAlert) {
            Button("삭제", role: .destructive) { deleteSite() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("삭제된 현장은 복구할 수 없어요")
        }
    }
    
    // MARK: - 기록 Row
    private func entryRow(_ entry: WorkEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
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
    
    // MARK: - 헬퍼
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
    
    // MARK: - 삭제
    private func deleteEntries(at offsets: IndexSet) {
        offsets.map { sortedEntries[$0] }.forEach { context.delete($0) }
        try? context.save()
    }
    
    private func deleteSite() {
        context.delete(site)
        try? context.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SiteDetailView(site: Site(name: "평택삼성 1공구", defaultWage: 180000))
    }
    .modelContainer(for: [Site.self, WorkEntry.self], inMemory: true)
}
