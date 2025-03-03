//
//  ContentView.swift
//  Gong
//
//  Created by 박세진 on 2/27/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        WorkCalculator()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            MonthlyWork.self,
            WeeklyWork.self,
            DailyWork.self
            
        ], inMemory: true)
}
