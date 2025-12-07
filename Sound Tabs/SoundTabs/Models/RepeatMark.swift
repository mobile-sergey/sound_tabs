//
//  RepeatMark.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

// Маркер повтора (зелёные вертикальные линии)
struct RepeatMark: Identifiable, Codable {
    let id: UUID
    var startPosition: Double // Позиция начала (0.0 - 1.0)
    var endPosition: Double // Позиция конца (0.0 - 1.0)
    var tablatureId: UUID // ID табулатуры, к которой относится
    
    init(id: UUID = UUID(), startPosition: Double = 0.0, endPosition: Double = 1.0, tablatureId: UUID) {
        self.id = id
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.tablatureId = tablatureId
    }
}

