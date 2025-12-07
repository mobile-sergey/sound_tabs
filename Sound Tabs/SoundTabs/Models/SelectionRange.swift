//
//  SelectionRange.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

// Выделенный интервал на нотном стане
struct SelectionRange: Codable {
    var staffLineId: UUID? // ID строки, на которой выделение
    var startPosition: Double // Начальная позиция (0.0 - 1.0)
    var endPosition: Double // Конечная позиция (0.0 - 1.0)
    var isActive: Bool // Активно ли выделение
    
    init(staffLineId: UUID? = nil, startPosition: Double = 0, endPosition: Double = 0, isActive: Bool = false) {
        self.staffLineId = staffLineId
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.isActive = isActive
    }
    
    var normalizedStart: Double {
        min(startPosition, endPosition)
    }
    
    var normalizedEnd: Double {
        max(startPosition, endPosition)
    }
    
    var width: Double {
        abs(endPosition - startPosition)
    }
}

