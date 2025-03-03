//
//  MonthlyCalendar.swift
//  Gong
//
//  Created by 박세진 on 3/1/25.
//

import SwiftUI

struct MonthlyCalendar: View {
    let monthlyWork: MonthlyWork
    
    @Binding var selectedDailyWork: DailyWork?
    
    var body: some View {
        CalendarHeader()
        CalendarBody(monthlyWork: monthlyWork, selectedDailyWork: $selectedDailyWork)
    }
}

#Preview {
    @State @Previewable var selectedDailyWork: DailyWork? = nil
    
    MonthlyCalendar(monthlyWork: MonthlyWork.sampleData(), selectedDailyWork: $selectedDailyWork)
}
