//
//  Untitled.swift
//  Gong
//
//  Created by 박세진 on 3/2/25.
//

import SwiftUI
import SwiftData

enum DisplayType: Hashable {
    case summary
    case date
}

struct WorkCalculator: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var monthlyWorks: [MonthlyWork]
    
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDailyWork: DailyWork?
    @State private var editingDailyWork: DailyWork?
    @State private var displayType: DisplayType = .date
    
    init() {
        let today = Date()
        let calendar = Calendar.current
        _selectedYear = State(initialValue: calendar.component(.year, from: today))
        _selectedMonth = State(initialValue: calendar.component(.month, from: today))
    }
    
    @State var isMonth = false
    
    var body: some View {
        NavigationStack {
            List {
                // 📆 연도 변경 Stepper
                Section {
                    Stepper {
                        Text(String(format: "%d", selectedYear) + "년")
                            .font(.title3)
                    } onIncrement: {
                        changeYear(by: 1)
                    } onDecrement: {
                        changeYear(by: -1)
                    }

                    // 📆 월 변경 Stepper
                    Stepper {
                        Text("\(selectedMonth)월")
                            .font(.title)
                            .fontWeight(.bold)
                    } onIncrement: {
                        changeMonth(by: 1)
                    } onDecrement: {
                        changeMonth(by: -1)
                    }
                }
                
                if let selectedDailyWork = selectedDailyWork {
                    
                    Toggle(isOn: $isMonth) {
                        Text("단위: \(isMonth ? "월" : "주")")
                    }
                    .tint(.accentColor)
                    
                    if let weeklyWork = selectedDailyWork.belongingWeek, let monthlyWork = weeklyWork.belongingMonth {
                        
                        if isMonth {
                            MonthlyCalendar(monthlyWork: monthlyWork, selectedDailyWork: $selectedDailyWork)
                                .buttonStyle(.plain)
                        } else {
                            WeeklyCalendar(weeklyWork: weeklyWork, selectedDailyWork: $selectedDailyWork)
                                .buttonStyle(.plain)
                        }
                        
                    }
                } else {
                    if let monthlyWork = currentMonthlyWork() {
                        MonthlyCalendar(monthlyWork: monthlyWork, selectedDailyWork: $selectedDailyWork)
                            .buttonStyle(.plain)
                    }
                }
                
                if let selectedDailyWork = selectedDailyWork {
                    Spacer()
                    Section {
                        Picker("표시", selection: $displayType) {
                            Text("오늘").tag(DisplayType.date)
                            Text("요약").tag(DisplayType.summary)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    if displayType == .summary {
                        if let weeklyWork = selectedDailyWork.belongingWeek, let monthlyWork = weeklyWork.belongingMonth {
                            
                            if isMonth {
                                MonthlySummary(monthlyWork: monthlyWork)
                            } else {
                                WeeklySummary(weeklyWork: weeklyWork)
                            }
                            
                        }
                        
                    } else {
                        GroupBox {
                            DailyWorkDetail(dailyWork: selectedDailyWork)
                        } label: {
                            LabeledContent {
                                Button {
                                    editingDailyWork = selectedDailyWork
                                } label: {
                                    Label("수정", systemImage: "pencil.circle")
                                        .labelStyle(.iconOnly)
                                }
                            } label: {
                                Text("입력 & 수정")
                            }
                        }
                        
                        
                        // 📝 메모 (있을 경우만 표시)
                        if !selectedDailyWork.memo.isEmpty {
                            Section("메모") {
                                Text(selectedDailyWork.memo)
                            }
                        }
                    }
                }
        
            }
            .listStyle(.inset)
            .sheet(item: $editingDailyWork) { dailyWork in
                dailyWorkEditor(dailyWork: dailyWork)
            }
            
        }
    }
    
    
    /// 📅 현재 선택된 연/월에 맞는 MonthlyWork 찾기 (없으면 생성)
    private func currentMonthlyWork() -> MonthlyWork? {
        
        if let existingWork = monthlyWorks.first(where: { $0.year == selectedYear && $0.month == selectedMonth }) {
            return existingWork
        } else {
            return createAndFetchMonthlyWork(year: selectedYear, month: selectedMonth)
        }
    }
    
    private func changeYear(by value: Int) {
        if let selectedDailyWork = selectedDailyWork {
            selectedDailyWork.isSelected = false
        }
        
        selectedDailyWork = nil
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: selectedYear, month: selectedMonth)

        guard let currentDate = calendar.date(from: dateComponents),
              let newDate = calendar.date(byAdding: .year, value: value, to: currentDate) else { return }

        // ✅ 연도만 변경 (월은 그대로 유지)
        selectedYear = calendar.component(.year, from: newDate)
        selectedMonth = calendar.component(.month, from: newDate)
    }
    
    /// 📅 월 변경 처리
    private func changeMonth(by value: Int) {
        if let selectedDailyWork = selectedDailyWork {
            selectedDailyWork.isSelected = false
        }
        
        selectedDailyWork = nil
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: selectedYear, month: selectedMonth)
        guard let newDate = calendar.date(byAdding: .month, value: value, to: calendar.date(from: dateComponents)!) else { return }

        // ✅ 새로운 년/월 값 업데이트
        selectedYear = calendar.component(.year, from: newDate)
        selectedMonth = calendar.component(.month, from: newDate)
    }

    /// ✅ 새로운 MonthlyWork를 생성하고 SwiftData에 추가한 후 반환
    private func createAndFetchMonthlyWork(year: Int, month: Int) -> MonthlyWork {
        let newMonthlyWork = MonthlyWork(year: year, month: month)
        newMonthlyWork.generateWeeklyWork()
        modelContext.insert(newMonthlyWork) // SwiftData에 추가
        return newMonthlyWork
    }
    
}

#Preview {
    WorkCalculator()
        
}
