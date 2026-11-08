//
//  SiteListView.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import SwiftUI
import SwiftData

struct SiteListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Site.startDate, order: .reverse) private var sites: [Site]
    
    @State private var isShowingForm: Bool = false
    @State private var searchText: String = ""
    
    private var activeSites: [Site] {
        sites.filter { $0.isActive && matchesSearch($0) }
    }
    private var inactiveSites: [Site] {
        sites.filter { !$0.isActive && matchesSearch($0) }
    }
    
    private func matchesSearch(_ site: Site) -> Bool {
        searchText.isEmpty ||
        site.name.localizedCaseInsensitiveContains(searchText) ||
        site.location.localizedCaseInsensitiveContains(searchText)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if sites.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .navigationTitle("현장")
            .searchable(text: $searchText, prompt: "현장명, 위치 검색")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(.accentColor)
                }
            }
            .sheet(isPresented: $isShowingForm) {
                SiteFormView()
            }
        }
    }
    
    // MARK: - 리스트
    private var listView: some View {
        List {
            if !activeSites.isEmpty {
                Section("진행중") {
                    ForEach(activeSites) { site in
                        NavigationLink {
                            SiteDetailView(site: site)
                        } label: {
                            SiteRow(site: site)
                        }
                    }
                }
            }
            
            if !inactiveSites.isEmpty {
                Section("종료") {
                    ForEach(inactiveSites) { site in
                        NavigationLink {
                            SiteDetailView(site: site)
                        } label: {
                            SiteRow(site: site)
                        }
                    }
                }
            }
            
            // 검색 결과 없음
            if !searchText.isEmpty && activeSites.isEmpty && inactiveSites.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }
    
    // MARK: - 빈 화면
    private var emptyView: some View {
        ContentUnavailableView {
            Label("등록된 현장이 없어요", systemImage: "building.2")
        } description: {
            Text("현장을 추가하면 공수 기록을 관리할 수 있어요")
        } actions: {
            Button {
                isShowingForm = true
            } label: {
                Text("현장 추가하기")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor, in: Capsule())
            }
        }
    }
}

// MARK: - SiteRow
struct SiteRow: View {
    let site: Site

    private var thisMonthManUnit: Double {
        site.entries
            .filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
            .reduce(0) { $0 + $1.manUnit }
    }

    private var unpaidAmount: Int {
        site.entries.filter { !$0.isPaid }.reduce(0) { $0 + $1.netAmount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(site.name)
                    .font(.headline)
                if !site.isActive {
                    Text("종료")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary, in: Capsule())
                }
                Spacer()
                if site.isActive && thisMonthManUnit > 0 {
                    Text("이번 달 \(Format.manUnit(thisMonthManUnit))공수")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                Text(Format.fullDate.string(from: site.startDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !site.location.isEmpty {
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(site.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            HStack {
                Text(Format.won(site.defaultWage))
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                    .fontWeight(.semibold)
                Text(site.taxMode.shortTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5), in: Capsule())
                Spacer()
                if unpaidAmount > 0 {
                    Text("미입금 \(Format.won(unpaidAmount))")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SiteListView()
        .modelContainer(for: [Site.self, WorkEntry.self], inMemory: true)
}
