//
//  TabFret.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// Лад на струне гитары, представляющий ноту на определенной позиции.
/// Содержит номер лада (0-24), позицию на струне и состояние выделения.
struct TabFret: Identifiable, Codable, Equatable {
    let id: UUID
    var fretNumber: Int // Номер лада (0 = открытая струна, 1-24)
    var position: Double // Позиция на струне (0.0 - начало, 1.0 - конец)
    var isSelected: Bool // Выделен ли лад
    
    init(id: UUID = UUID(), fretNumber: Int = 0, position: Double = 0.0, isSelected: Bool = false) {
        self.id = id
        self.fretNumber = max(0, min(24, fretNumber)) // Ограничиваем 0-24
        self.position = position
        self.isSelected = isSelected
    }
}

