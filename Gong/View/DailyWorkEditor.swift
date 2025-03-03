//
//  DailyWorkEditor.swift
//  Gong
//
//  Created by 박세진 on 3/2/25.
//

import SwiftUI

struct dailyWorkEditor: View {
    @Bindable var dailyWork: DailyWork
    @Environment(\.dismiss) var dismiss
    
    @State var memoText = ""
    
    @State var isPresented = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("기본 정보")) {
                    // 📅 날짜 (수정 불가능)
                    HStack {
                        Text("날짜")
                        Spacer()
                        Text(formattedDate(dailyWork.workDate))
                            .foregroundColor(.gray)
                    }
                }
                Section(header: Text("근무 정보")) {
                    // ⏳ 공수 Stepper
                    Stepper(value: $dailyWork.hours, in: 0...24, step: 0.5) {
                        LabeledContent {
                            Text("\(String(format: "%.1f", dailyWork.hours))")
                        } label: {
                            Text("공수")
                        }
                    }
                    
                    // 💰 일급 Stepper
                    Stepper(value: $dailyWork.dailyWage, in: 50000...500000, step: 5000) {
                        LabeledContent {
                            Text("\(Int(dailyWork.dailyWage)) 원")
                        } label: {
                            Text("일급")
                        }
                    }
                    
                    // 💵 세율 Stepper
                    Stepper(value: $dailyWork.taxPercentage, in: 0...50, step: 0.1) {
                        LabeledContent {
                            Text("\(String(format: "%.1f", dailyWork.taxPercentage)) %")
                        } label: {
                            Text("세율")
                        }
                    }
                    
                    Stepper(value: $dailyWork.mealCost, in: 0...200000, step: 1000) {
                        LabeledContent {
                            Text("\(Int(dailyWork.mealCost)) 원")
                        } label: {
                            Text("식대")
                        }
                    }
                    
                    // 🏠 숙박비 Stepper
                    Stepper(value: $dailyWork.accommodationCost, in: 0...200000, step: 1000) {
                        LabeledContent {
                            Text("\(Int(dailyWork.accommodationCost)) 원")
                        } label: {
                            Text("숙박비")
                        }
                    }
                    
                    LabeledContent {
                        Text("\(dailyWork.calculateNetIncome()) 원")
                    } label: {
                        Text("총")
                    }
                    
                }
                Section("메모") {
                    NavigationLink {
                        MemoEditor(dailyWork: dailyWork ,memoText: $memoText)
                    } label: {
                        Text(dailyWork.memo)
                    }
                }
                
                
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    @State @Previewable var dailyWork: DailyWork = DailyWork.sampleData()
    dailyWorkEditor(dailyWork: dailyWork)
}
