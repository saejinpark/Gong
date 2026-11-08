//
//  GongApp.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import SwiftUI
import SwiftData

@main
struct GongApp: App {

    let container: ModelContainer = {
        let schema = Schema([Site.self, WorkEntry.self])
        let inMemory = CommandLine.arguments.contains("-inMemory")
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            if CommandLine.arguments.contains("-seedDemo") {
                DemoData.seedIfEmpty(into: container.mainContext)
            }
            return container
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 앱은 한국어 전용 — 시스템 언어와 무관하게 날짜·숫자를 한국식으로
                .environment(\.locale, Locale(identifier: "ko_KR"))
        }
        .modelContainer(container)
    }
}
