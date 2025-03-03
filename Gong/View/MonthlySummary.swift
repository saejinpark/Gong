//
//  MonthlySummary.swift
//  Gong
//
//  Created by 박세진 on 3/3/25.
//

import SwiftUI

struct MonthlySummary: View {
    let monthlyWork: MonthlyWork
    
    var body: some View {
        GroupBox {
            LabeledContent {
                Text("\(monthlyWork.totalHours, specifier: "%.1f")")
            } label: {
                Text("공수")
            }

            LabeledContent {
                Text("\(monthlyWork.totalIncome) 원")
            } label: {
                Text("수입")
            }

            LabeledContent {
                Text("\(monthlyWork.totalAccommodationCost) 원")
            } label: {
                Text("숙박비")
            }
            
            Spacer()
            
            LabeledContent {
                Text("\(monthlyWork.netIncome) 원")
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
    MonthlySummary(monthlyWork: MonthlyWork.sampleData())
}
