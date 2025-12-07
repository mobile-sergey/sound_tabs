//
//  TabMetadata.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// Метаданные табулатуры: темп (BPM) и размер такта (например, 4/4).
/// Используется для хранения глобальных параметров музыкального произведения.
struct TabMetadata: Codable {
    var tempo: Int // Темп в BPM (beats per minute)
    var sizeTop: Int // Верхняя цифра размера (например, 4 в 4/4)
    var sizeBottom: Int // Нижняя цифра размера (например, 4 в 4/4)
    
    init(tempo: Int = 120, sizeTop: Int = 4, sizeBottom: Int = 4) {
        self.tempo = tempo
        self.sizeTop = sizeTop
        self.sizeBottom = sizeBottom
    }
}

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

