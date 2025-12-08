//
//  PlaybackPosition.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// Состояние воспроизведения табулатуры.
/// Отслеживает текущую позицию воспроизведения, активный таб и состояние play/pause.
struct PlaybackPosition: Identifiable, Equatable {
    let id: UUID
    var tabLineIndex: Int // Индекс таба (0 - первый таб)
    var position: Double // Позиция на табе (0.0 - начало, 1.0 - конец)
    
    init(tabLineIndex: Int = 0, position: Double = 0.0) {
        self.id = UUID()
        self.tabLineIndex = tabLineIndex
        self.position = position
    }
}

