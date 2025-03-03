//
//  MonthlyWork'.swift
//  Gong
//
//  Created by 박세진 on 3/1/25.
//

import Foundation

extension MonthlyWork {
    static func sampleData() -> MonthlyWork {
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)

        let monthlyWork = MonthlyWork(year: year, month: month)

        monthlyWork.generateWeeklyWork()


        return monthlyWork
    }
}
