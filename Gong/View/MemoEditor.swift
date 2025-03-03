//
//  MemoEditor.swift
//  Gong
//
//  Created by 박세진 on 3/3/25.
//

import SwiftUI

struct MemoEditor: View {
    var dailyWork: DailyWork
    @Binding var memoText: String
    @FocusState private var isFocused: Bool
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Group {
            TextEditor(text: $memoText)
                .focused($isFocused)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing){
                Button {
                    dailyWork.memo = memoText
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Label("regist",systemImage: "pencil.and.list.clipboard")
                        .labelStyle(.iconOnly)
                }
            }
        }
        .onTapGesture {
            isFocused = false
        }
    }
}
