//
//  DemoData.swift
//  Gong
//
//  스크린샷·테스트용 샘플 데이터. `-seedDemo` 실행 인자가 있을 때만 쓰임.
//

import Foundation
import SwiftData

enum DemoData {

    static func seedIfEmpty(into context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<WorkEntry>())) ?? 0
        guard existing == 0 else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let monthStart = calendar.dateInterval(of: .month, for: today)?.start else { return }

        let siteA = Site(name: "평택 1공구", defaultWage: 200_000, startDate: calendar.date(byAdding: .month, value: -2, to: today) ?? today,
                         location: "경기 평택시", memo: "형틀목공 · 김반장", taxMode: .withholding, defaultMealAllowance: 10_000, colorIndex: 0)
        let siteB = Site(name: "동탄 오피스텔", defaultWage: 180_000, startDate: calendar.date(byAdding: .month, value: -1, to: today) ?? today,
                         location: "경기 화성시", taxMode: .business, colorIndex: 1)
        let siteC = Site(name: "안성 물류센터", defaultWage: 170_000, startDate: calendar.date(byAdding: .month, value: -5, to: today) ?? today,
                         location: "경기 안성시", isActive: false, taxMode: .none, colorIndex: 5)
        [siteA, siteB, siteC].forEach { context.insert($0) }

        let weathers: [WeatherCondition] = [.sunny, .sunny, .cloudy, .sunny, .rainy, .sunny, .cloudy]
        var dayOffset = 0
        var index = 0
        while let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart), date <= today {
            defer { dayOffset += 1 }
            let dayType = HolidayService.dayType(for: date)
            // 일요일·공휴일은 대부분 쉼
            if dayType == .holiday && index % 3 != 0 { continue }

            let site = (index % 5 == 4) ? siteB : siteA
            var manUnit: Double = 1.0
            var tag: WorkTag? = nil
            var memo = ""
            switch index % 9 {
            case 2: manUnit = 1.5; memo = "잔업 2시간"
            case 5: manUnit = 0.5; tag = .rainStop; memo = "오후 비로 철수"
            case 7: manUnit = 2.0; memo = "특근"
            default: break
            }
            let weather = (index % 9 == 5) ? .rainy : weathers[index % weathers.count]
            let isPaid = dayOffset < 15

            let entry = WorkEntry(
                date: date,
                manUnit: manUnit,
                wage: site.defaultWage,
                mealAllowance: site.defaultMealAllowance,
                dayType: dayType,
                weatherCondition: weather,
                workTag: tag,
                memo: memo,
                isPaid: isPaid,
                site: site,
                taxMode: site.taxMode
            )
            context.insert(entry)
            index += 1
        }

        // 지난달 기록 몇 건 (연간 요약·미입금 확인용)
        if let lastMonth = calendar.date(byAdding: .month, value: -1, to: monthStart) {
            for d in [2, 3, 4, 7, 8, 9, 10, 14, 15, 16, 17, 21, 22, 23, 24, 28] {
                guard let date = calendar.date(byAdding: .day, value: d, to: lastMonth), date < monthStart else { continue }
                let entry = WorkEntry(
                    date: date,
                    manUnit: d % 7 == 0 ? 1.5 : 1.0,
                    wage: siteA.defaultWage,
                    mealAllowance: siteA.defaultMealAllowance,
                    dayType: HolidayService.dayType(for: date),
                    weatherCondition: .sunny,
                    isPaid: d != 28,
                    site: siteA,
                    taxMode: siteA.taxMode
                )
                context.insert(entry)
            }
        }

        try? context.save()
    }
}
