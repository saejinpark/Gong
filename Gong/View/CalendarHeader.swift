//
//  CalendarHeader.swift
//  Gong
//
//  Created by 박세진 on 3/2/25.
//

import SwiftUI

struct CalendarHeader: View {
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .font(.headline)
                    .foregroundColor(day == "일" ? .red : day == "토" ? .blue : .primary)
            }
        }
    }
}

#Preview {
    CalendarHeader()
}
