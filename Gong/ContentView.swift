//
//  ContentView.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CalendarView()
                .tabItem {
                    Label("공수", systemImage: "calendar")
                }
            
            SiteListView()
                .tabItem {
                    Label("현장", systemImage: "building.2")
                }
            
            SettlementView()
                .tabItem {
                    Label("정산", systemImage: "wonsign")
                }
        }
        .tint(.accentColor)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Site.self, WorkEntry.self], inMemory: true)
}
