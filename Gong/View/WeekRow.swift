//
//  WeekRow.swift
//  Gong
//
//  Created by 박세진 on 3/1/25.
//

import SwiftUI

struct WeekRow: View {
    
    let weeklyWork: WeeklyWork
    @Binding var selectedDailyWork: DailyWork? // ✅ 바인딩 추가
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var sortedDailyWorks: [DailyWork] {
        weeklyWork.dailyWorks.sorted { $0.dayNumber < $1.dayNumber }
    }
    
    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(sortedDailyWorks, id: \.id) { dailyWork in
                Button {
                    if let selectedDailyWork {
                        selectedDailyWork.isSelected = false
                    }
                    selectedDailyWork = dailyWork
                    dailyWork.isSelected = true
                } label: {
                    DailyWorkCard(dailyWork: dailyWork)
                }.disabled(dailyWork.isDummy ? true : false)
            }
        }
    }
}

#Preview {
    @State @Previewable var selectedDailyWork: DailyWork? = nil
    
    WeekRow(weeklyWork: WeeklyWork.sampleData(weekNumber: 1), selectedDailyWork: $selectedDailyWork)
        .background(Color.gray)
}
