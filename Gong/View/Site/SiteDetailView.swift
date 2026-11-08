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
    @State private var editingEntry: WorkEntry? = nil

    @Query private var allSites: [Site]

    private let calendar = Calendar.current

    private var sortedEntries: [WorkEntry] {
        site.entries.sorted { ($0.date, $0.createdAt) > ($1.date, $1.createdAt) }
    }

    private var thisMonthEntries: [WorkEntry] {
        site.entries.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .month) }
    }

    private var totalManUnit: Double { site.entries.reduce(0) { $0 + $1.manUnit } }
    private var totalNetAmount: Int { site.entries.reduce(0) { $0 + $1.netAmount } }
    private var unpaid: [WorkEntry] { site.entries.filter { !$0.isPaid } }
    private var unpaidAmount: Int { unpaid.reduce(0) { $0 + $1.netAmount } }

    /// 월별로 묶은 기록 (최근 달 먼저)
    private var entriesByMonth: [(month: Date, entries: [WorkEntry])] {
        Dictionary(grouping: sortedEntries) { calendar.startOfMonth(for: $0.date) }
            .map { (month: $0.key, entries: $0.value) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        List {
            // MARK: - 요약 카드
            Section {
                HeroCard(
                    title: "누적 실수령액",
                    amount: totalNetAmount,
                    caption: "\(Format.manUnit(totalManUnit))공수 · \(site.entries.count)일 · 이번 달 \(Format.manUnit(thisMonthEntries.reduce(0) { $0 + $1.manUnit }))공수",
                    tint: Theme.Colors.site(site.colorIndex)
                ) {
                    if !unpaid.isEmpty {
                        TagChip(text: "미입금 \(unpaidAmount.formatted())원 · \(unpaid.count)건", tint: .white.opacity(0.25))
                            .padding(.top, Theme.Spacing.xs)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // MARK: - 현장 정보
            Section("현장 정보") {
                LabeledContent("기본 단가") {
                    Text(Format.won(site.defaultWage))
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.semibold)
                }
                LabeledContent("세금 방식") {
                    Text(site.taxMode.title)
                        .foregroundStyle(.secondary)
                }
                if site.defaultMealAllowance > 0 {
                    LabeledContent("기본 식대") {
                        Text(Format.won(site.defaultMealAllowance))
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent("시작일") {
                    Text(Format.fullDate.string(from: site.startDate))
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

            // MARK: - 공수 기록
            if sortedEntries.isEmpty {
                Section("공수 기록") {
                    ContentUnavailableView(
                        "기록 없음",
                        systemImage: "doc.text",
                        description: Text("이 현장의 공수 기록이 없어요")
                    )
                }
            } else {
                ForEach(entriesByMonth, id: \.month) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            EntryRow(entry: entry, showsSite: false)
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
                        .onDelete { offsets in
                            offsets.map { group.entries[$0] }.forEach { context.delete($0) }
                            try? context.save()
                        }
                    } header: {
                        HStack {
                            Text(Format.monthTitle.string(from: group.month))
                            Spacer()
                            Text("\(Format.manUnit(group.entries.reduce(0) { $0 + $1.manUnit }))공수 · \(Format.won(group.entries.reduce(0) { $0 + $1.netAmount }))")
                                .monospacedDigit()
                        }
                    }
                }
            }

            // MARK: - 삭제
            if site.entries.isEmpty {
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
        .sheet(item: $editingEntry) { entry in
            WorkEntrySheetView(
                date: entry.date,
                sites: allSites,
                editingEntry: entry
            )
        }
        .alert("현장을 삭제할까요?", isPresented: $isShowingDeleteAlert) {
            Button("삭제", role: .destructive) { deleteSite() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("삭제된 현장은 복구할 수 없어요")
        }
    }

    private func deleteSite() {
        context.delete(site)
        try? context.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SiteDetailView(site: Site(name: "평택 1공구", defaultWage: 180000))
    }
    .modelContainer(for: [Site.self, WorkEntry.self], inMemory: true)
}
