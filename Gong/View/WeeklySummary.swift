//
//  WeeklySummary.swift
//  Gong
//
//  Created by 박세진 on 3/3/25.
//

import SwiftUI

struct WeeklySummary: View {
    let weeklyWork: WeeklyWork
    
    var body: some View {
        GroupBox {
            LabeledContent {
                Text("\(weeklyWork.totalHours, specifier: "%.1f")")
            } label: {
                Text("공수")
            }

            LabeledContent {
                Text("\(weeklyWork.totalIncome) 원")
            } label: {
                Text("수입")
            }

            LabeledContent {
                Text("\(weeklyWork.totalAccommodationCost) 원")
            } label: {
                Text("숙박비")
            }
            
            Spacer()
            
            LabeledContent {
                Text("\(weeklyWork.netIncome) 원")
                    .foregroundColor(.primary)
                    .bold()
            } label: {
                Text("실수령액") // ✅ 최종 지급받는 금액
                    .bold()
            }
        }
    }
}

#Preview {
    WeeklySummary(weeklyWork: WeeklyWork.sampleData(weekNumber: 1))
}
