//
//  GuitarNoteHelper.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// Вспомогательный класс для вычисления названий нот на гитаре.
/// Преобразует комбинацию струны и номера лада в название ноты (например, "C", "C♯").
struct GuitarNoteHelper {
    // Маппинг струн на базовые ноты (открытая струна)
    static let stringNotes: [String: NoteName] = [
        "E": .E,  // 6-я струна (нижняя)
        "A": .A,  // 5-я струна
        "D": .D,  // 4-я струна
        "G": .G,  // 3-я струна
        "B": .B,  // 2-я струна
        "e": .E   // 1-я струна (верхняя)
    ]
    
    // Порядок нот в хроматической гамме (C, C#, D, D#, E, F, F#, G, G#, A, A#, B)
    static let chromaticScale: [(note: NoteName, isSharp: Bool)] = [
        (.C, false), (.C, true),   // C, C#
        (.D, false), (.D, true),   // D, D#
        (.E, false),                // E
        (.F, false), (.F, true),   // F, F#
        (.G, false), (.G, true),   // G, G#
        (.A, false), (.A, true),   // A, A#
        (.B, false)                // B
    ]
    
    // Индексы базовых нот в хроматической гамме
    static func getBaseNoteIndex(_ note: NoteName) -> Int {
        switch note {
        case .C: return 0
        case .D: return 2
        case .E: return 4
        case .F: return 5
        case .G: return 7
        case .A: return 9
        case .B: return 11
        }
    }
    
    // Вычисляет название ноты на основе струны и лада
    static func getNoteName(stringNoteName: String, fretNumber: Int) -> String {
        guard let baseNote = stringNotes[stringNoteName] else {
            return "?"
        }
        
        // Находим индекс базовой ноты в хроматической гамме
        let baseIndex = getBaseNoteIndex(baseNote)
        
        // Вычисляем индекс ноты с учетом лада
        let noteIndex = (baseIndex + fretNumber) % 12
        let (note, isSharp) = chromaticScale[noteIndex]
        
        var noteName = note.rawValue
        if isSharp {
            noteName += "♯"
        }
        
        return noteName
    }
}

