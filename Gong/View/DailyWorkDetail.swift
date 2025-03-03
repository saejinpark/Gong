//
//  DailyWorkDetail.swift
//  Gong
//
//  Created by 박세진 on 3/2/25.
//
import SwiftUI

struct DailyWorkDetail: View {
    var dailyWork: DailyWork
    
    var body: some View {
        
        LabeledContent {
            Text("\(String(format: "%.1f", dailyWork.hours))")
        } label: {
            Text("공수")
        }
        
        LabeledContent {
            Text("\(Int(dailyWork.dailyWage)) 원")
        } label: {
            Text("일급")
        }
        
        LabeledContent {
            Text("\(dailyWork.taxPercentage, specifier: "%.1f") %")
        } label: {
            Text("세율")
        }
        
        LabeledContent {
            Text("\(Int(dailyWork.mealCost)) 원")
        } label: {
            Text("식대")
        }
        
        LabeledContent {
            Text("\(Int(dailyWork.accommodationCost)) 원")
        } label: {
            Text("숙박비")
        }
        
        Spacer()
        Divider()
        
        LabeledContent {
            Text("\(dailyWork.calculateNetIncome()) 원")
                .bold()
                .foregroundColor(.black)
        } label: {
            Text("총")
                .bold()
        }
        
    }
    
}

#Preview {
    let dailyWork: DailyWork = .sampleData()
    
    List {
        DailyWorkDetail(dailyWork: dailyWork)
    }
}
