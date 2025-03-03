//
//  WeeklyCalendar.swift
//  Gong
//
//  Created by 박세진 on 3/2/25.
//

import SwiftUI

struct WeeklyCalendar: View {
    let weeklyWork: WeeklyWork
    
    @Binding var selectedDailyWork: DailyWork?
    
    var body: some View {
        CalendarHeader()
        WeekRow(weeklyWork: weeklyWork, selectedDailyWork: $selectedDailyWork)
            .buttonStyle(.plain)
    }
}

#Preview {
    @State @Previewable var selectedDailyWork: DailyWork? = nil
    
    WeeklyCalendar(weeklyWork: WeeklyWork.sampleData(weekNumber: 1), selectedDailyWork: $selectedDailyWork)
}

