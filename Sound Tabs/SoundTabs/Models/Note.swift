//
//  Note.swift
//  Sound Tabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

// Модель ноты
struct Note: Identifiable, Codable {
    let id: UUID
    var name: NoteName
    var octave: Octave
    var duration: NoteDuration
    var position: Double // Позиция на стане (0.0 - начало, 1.0 - конец)
    var isSharp: Bool // Диез
    var isFlat: Bool // Бемоль
    
    init(id: UUID = UUID(), name: NoteName, octave: Octave, duration: NoteDuration = .quarter, position: Double, isSharp: Bool = false, isFlat: Bool = false) {
        self.id = id
        self.name = name
        self.octave = octave
        self.duration = duration
        self.position = position
        self.isSharp = isSharp
        self.isFlat = isFlat
    }
}

