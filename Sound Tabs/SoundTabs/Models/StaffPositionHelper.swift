//
//  StaffPositionHelper.swift
//  Sound Tabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

// Вспомогательная функция для определения позиции ноты на стане
func getStaffPosition(for note: Note) -> StaffPosition {
    let noteValue = note.name.rawValue
    let octave = note.octave.rawValue
    
    // Упрощенная логика: для октавы 4-5 определяем позицию
    if octave == 4 {
        switch noteValue {
        case "C": return .space1
        case "D": return .line1
        case "E": return .space2
        case "F": return .line2
        case "G": return .space3
        case "A": return .line3
        case "B": return .space4
        default: return .line3
        }
    } else if octave == 5 {
        switch noteValue {
        case "C": return .space4
        case "D": return .line4
        case "E": return .space3
        case "F": return .line3
        case "G": return .space2
        case "A": return .line2
        case "B": return .space1
        default: return .line3
        }
    } else if octave == 3 {
        switch noteValue {
        case "C": return .below1
        case "D": return .line1
        case "E": return .space1
        case "F": return .line2
        case "G": return .space2
        case "A": return .line3
        case "B": return .space3
        default: return .line3
        }
    }
    
    return .line3
}

