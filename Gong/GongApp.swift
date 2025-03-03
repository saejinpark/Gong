//
//  GongApp.swift
//  Gong
//
//  Created by 박세진 on 2/27/25.
//

import SwiftUI
import SwiftData

@main
struct GongApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MonthlyWork.self,
            WeeklyWork.self,
            DailyWork.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
