//
//  CalendarBody.swift
//  Gong
//
//  Created by 박세진 on 3/2/25.
//

import SwiftUI

struct CalendarBody: View {
    
    let monthlyWork: MonthlyWork
    @Binding var selectedDailyWork: DailyWork?
    
    var sortedWeeklyWorks: [WeeklyWork] {
        monthlyWork.weeklyWorks.sorted { $0.weekNumber < $1.weekNumber }
    }
    
    var body: some View {
        ForEach(sortedWeeklyWorks, id: \.id) { weeklyWork in
            WeekRow(weeklyWork: weeklyWork, selectedDailyWork: $selectedDailyWork)
        }
    }
}

#Preview {
    @State @Previewable var selectedDailyWork:DailyWork? = nil
    
    CalendarBody(monthlyWork: MonthlyWork.sampleData(), selectedDailyWork: $selectedDailyWork)
}
