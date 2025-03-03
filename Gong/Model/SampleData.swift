//
//  SampleData.swift
//  Gong
//
//  Created by 박세진 on 3/1/25.
//

import Foundation
import SwiftData

@MainActor
class SampleData {
    static let shared = SampleData()
    
    let modelContainer: ModelContainer
    
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    private init() {
        let schema = Schema([
            MonthlyWork.self,
            WeeklyWork.self,
            DailyWork.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            insertSampleData()
        } catch {
            fatalError("Could not create ModelContainer")
        }
    }
    
    /// 샘플 데이터 삽입
    func insertSampleData() {
        let sampleMonthlyWork = MonthlyWork.sampleData()
        context.insert(sampleMonthlyWork)
        
        do {
            try context.save()
        } catch {
            print("Sample data context failed to save")
        }
    }
    
    /// 샘플 월간 데이터 가져오기
    var monthlyWork: MonthlyWork {
        MonthlyWork.sampleData()
    }
    
    /// 샘플 주간 데이터 가져오기
    var weeklyWork: WeeklyWork {
        WeeklyWork.sampleData(weekNumber: 1)
    }
    
    /// 샘플 하루 데이터 가져오기
    var dailyWork: DailyWork {
        DailyWork.sampleData()
    }
}
