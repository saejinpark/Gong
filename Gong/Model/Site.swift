//
//  Site.swift
//  Gong
//
//  Created by 박세진 on 5/3/26.
//

import Foundation
import SwiftData

@Model
class Site {
    var name: String
    var defaultWage: Int
    var startDate: Date
    var location: String
    var memo: String
    var isActive: Bool
    @Relationship(deleteRule: .nullify) var entries: [WorkEntry] = []
    
    init(
        name: String,
        defaultWage: Int,
        startDate: Date = .now,
        location: String = "",
        memo: String = "",
        isActive: Bool = true
    ) {
        self.name = name
        self.defaultWage = defaultWage
        self.startDate = startDate
        self.location = location
        self.memo = memo
        self.isActive = isActive
    }
}
