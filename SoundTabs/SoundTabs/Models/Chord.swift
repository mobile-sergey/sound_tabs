//
//  Chord.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// Аккорд, отображаемый над табулатурой.
/// Содержит название аккорда (например, "Em", "C") и позицию на табе.
struct Chord: Identifiable, Codable {
    let id: UUID
    var name: String // Название аккорда (например, "Em", "C", "Am")
    var position: Double // Позиция на табе (0.0 - начало, 1.0 - конец)
    var tabLineId: UUID // ID таба, к которому относится аккорд
    
    init(id: UUID = UUID(), name: String, position: Double, tabLineId: UUID) {
        self.id = id
        self.name = name
        self.position = position
        self.tabLineId = tabLineId
    }
}

