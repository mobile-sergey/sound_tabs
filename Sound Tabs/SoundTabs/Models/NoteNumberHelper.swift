//
//  NoteNumberHelper.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

// Система соответствия между нотами/октавами и цифрами для гитары
// Используем 12 нот в октаве (C, C#, D, D#, E, F, F#, G, G#, A, A#, B)
// Октавы: малая (0), первая (1), вторая (2), третья (3)
// Цифры: 0-47 (12 нот * 4 октавы)

struct NoteNumberHelper {
    // Преобразование ноты и октавы в цифру
    static func noteToNumber(_ note: Note) -> Int {
        // Определяем номер ноты в октаве (0-11)
        let noteInOctave = noteNameToNumber(note.name, isSharp: note.isSharp, isFlat: note.isFlat)
        
        // Вычисляем общий номер: октава * 12 + номер ноты в октаве
        return note.octave.rawValue * 12 + noteInOctave
    }
    
    // Преобразование цифры в ноту и октаву
    static func numberToNote(_ number: Int) -> (NoteName, Octave, Bool, Bool) {
        let clampedNumber = max(0, min(47, number)) // Ограничиваем диапазон 0-47
        
        let octaveRaw = clampedNumber / 12
        let noteInOctave = clampedNumber % 12
        
        guard let octave = Octave(rawValue: octaveRaw) else {
            return (.C, .small, false, false)
        }
        
        let (noteName, isSharp, isFlat) = numberToNoteName(noteInOctave)
        
        return (noteName, octave, isSharp, isFlat)
    }
    
    // Преобразование названия ноты в номер (0-11)
    private static func noteNameToNumber(_ name: NoteName, isSharp: Bool, isFlat: Bool) -> Int {
        let baseNumber: Int
        switch name {
        case .C: baseNumber = 0
        case .D: baseNumber = 2
        case .E: baseNumber = 4
        case .F: baseNumber = 5
        case .G: baseNumber = 7
        case .A: baseNumber = 9
        case .B: baseNumber = 11
        }
        
        if isSharp {
            return baseNumber + 1
        } else if isFlat {
            return baseNumber - 1
        }
        return baseNumber
    }
    
    // Преобразование номера (0-11) в название ноты
    private static func numberToNoteName(_ number: Int) -> (NoteName, Bool, Bool) {
        switch number {
        case 0: return (.C, false, false)
        case 1: return (.C, true, false)  // C#
        case 2: return (.D, false, false)
        case 3: return (.D, true, false)  // D#
        case 4: return (.E, false, false)
        case 5: return (.F, false, false)
        case 6: return (.F, true, false)   // F#
        case 7: return (.G, false, false)
        case 8: return (.G, true, false)  // G#
        case 9: return (.A, false, false)
        case 10: return (.A, true, false)  // A#
        case 11: return (.B, false, false)
        default: return (.C, false, false)
        }
    }
    
    // Получение цифры для позиции на стане
    static func staffPositionToNumber(_ position: StaffPosition) -> Int {
        // Маппинг позиций стана на цифры
        // Начинаем с малой октавы внизу и идём вверх
        switch position {
        case .below1: return 0   // C малая
        case .line1: return 2    // D малая
        case .space1: return 4    // E малая
        case .line2: return 5     // F малая
        case .space2: return 7    // G малая
        case .line3: return 9     // A малая
        case .space3: return 11   // B малая
        case .line4: return 12   // C первая
        case .space4: return 14   // D первая
        case .line5: return 16   // E первая
        case .above5: return 17   // F первая
        }
    }
    
}

