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

