//
//  MeasureBar.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// Вертикальная линия такта на табулатуре.
/// Может быть одинарной или двойной (для обозначения конца такта).
struct MeasureBar: Identifiable, Codable, Equatable {
    let id: UUID
    var position: Double // Позиция на строке (0.0 - начало, 1.0 - конец)
    var isDouble: Bool // Двойная линия (конец такта)
    var measureDuration: MeasureDuration? // Длина такта (1, 1/2, 1/4, 1/8, 1/16, 1/32, 1/64)
    var isSelected: Bool // Выделен ли такт
    
    init(id: UUID = UUID(), position: Double, isDouble: Bool = false, measureDuration: MeasureDuration? = nil, isSelected: Bool = false) {
        self.id = id
        self.position = position
        self.isDouble = isDouble
        self.measureDuration = measureDuration
        self.isSelected = isSelected
    }
}

