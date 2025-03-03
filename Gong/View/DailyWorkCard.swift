//
//  DailyWorkCard.swift
//  Gong
//
//  Created by 박세진 on 3/1/25.
//

import SwiftUI

struct DailyWorkCard: View {
    
    let dailyWork: DailyWork
    
    var body: some View {
        let isToday = Calendar.current.isDate(dailyWork.workDate, inSameDayAs: Date()) // ✅ 오늘인지 확인

        LabeledContent {
            // 📅 날짜
            Text(dailyWork.isDummy ?  "--" : formattedDate(dailyWork.workDate))
                .foregroundColor(dailyWork.isDummy ? .secondary : dailyWork.isSelected ? .white : .primary)

        } label: {
            // ⏳ 공수 (Label + Circle + 숫자)
            Label {
                Text("\(Int(dailyWork.hours))") // 숫자만 보이도록 설정
                    
            } icon: {
                if dailyWork.isDummy {
                    Image(systemName: "rectangle.dashed")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                } else {
                    Image(systemName: "rectangle.fill") // 아이콘으로 원형 사용
                        .foregroundColor(workHourColor(dailyWork.hours)) // 색상 변경
                        .font(.largeTitle)
                        .overlay {
                            Text(String(format: "%.1f", dailyWork.hours))
                                .foregroundColor(.white)
                        }
                }
            }
            .labelStyle(.iconOnly) // 아이콘만 표시
        }
        .labeledContentStyle(LockUpLabeledContentStyle())
        .background(
            dailyWork.isSelected ? Color.gray : Color.white
        )
        .cornerRadius(8)
        .disabled(dailyWork.isDummy)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    dailyWork.isDummy ? Color(UIColor.systemGray5) :
                        dailyWork.isSelected ? Color.gray : (isToday ? Color.accentColor : Color(UIColor.systemGray5)), // ✅
                    lineWidth: 3
                )
        )
    }
    
    /// 날짜 포맷 함수
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    /// 공수에 따른 원 색상 변경 함수
    private func workHourColor(_ hours: Double) -> Color {
        switch hours {
        case 0:
            return Color(UIColor.systemGray3)
        case 0.1..<1:
            return .green
        case 1..<2:
            return .orange
        default:
            return .red
        }
    }
}

struct LockUpLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 12) {
            configuration.content // 날짜
            configuration.label  // 공수 원형
        }
    }
}

#Preview {
    DailyWorkCard(dailyWork: DailyWork.sampleData())
//    DailyWorkCard(dailyWork: DailyWork.sampleDummyData())
}
