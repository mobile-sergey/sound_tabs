//
//  MeasureBar.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// Вертикальная линия такта на табулатуре.
/// Может быть одинарной или двойной (для обозначения конца такта).
struct MeasureBar: Identifiable, Codable {
    let id: UUID
    var position: Double // Позиция на строке (0.0 - начало, 1.0 - конец)
    var isDouble: Bool // Двойная линия (конец такта)
    
    init(id: UUID = UUID(), position: Double, isDouble: Bool = false) {
        self.id = id
        self.position = position
        self.isDouble = isDouble
    }
}

