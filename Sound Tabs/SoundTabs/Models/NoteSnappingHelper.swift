//
//  NoteSnappingHelper.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

// Привязка нот к делениям
func snapToDivision(_ position: Double, divisions: Int = 16) -> Double {
    let step = 1.0 / Double(divisions)
    let snapped = round(position / step) * step
    return max(0, min(1, snapped))
}

// Проверка, находится ли позиция после скрипичного ключа
func isPositionAfterClef(_ position: Double, clefWidth: Double = 0.15) -> Bool {
    position > clefWidth
}

// Ограничение ноты только линиями стана (не промежутками) с поддержкой всех октав
func snapToStaffLine(yOffset: CGFloat, currentNote: Note) -> Note {
    let staffLineSpacing: CGFloat = 20
    let baseOffset = getStaffPosition(for: currentNote).yOffset
    
    // Вычисляем смещение относительно текущей позиции
    let deltaY = yOffset - baseOffset
    let stepCount = Int(round(deltaY / (staffLineSpacing / 2))) // Полушаги для промежутков
    
    // Определяем новую позицию на стане
    let currentPosition = getStaffPosition(for: currentNote)
    let newPositionRaw = currentPosition.rawValue - stepCount
    
    // Ограничиваем диапазон
    let clampedPositionRaw = max(StaffPosition.above5.rawValue, min(StaffPosition.below1.rawValue, newPositionRaw))
    
    guard let newPosition = StaffPosition(rawValue: clampedPositionRaw) else {
        return currentNote
    }
    
    // Преобразуем позицию стана в ноту и октаву с учетом всех октав
    let (newNoteName, newOctave, isSharp, isFlat) = getNoteFromStaffPositionExtended(newPosition, currentNote: currentNote)
    
    return Note(
        name: newNoteName,
        octave: newOctave,
        duration: currentNote.duration,
        position: currentNote.position,
        isSharp: isSharp,
        isFlat: isFlat
    )
}

// Расширенная функция для определения ноты с поддержкой всех октав
func getNoteFromStaffPositionExtended(_ position: StaffPosition, currentNote: Note) -> (NoteName, Octave, Bool, Bool) {
    // Используем новую систему с цифрами
    let number = NoteNumberHelper.staffPositionToNumber(position)
    let (noteName, octave, isSharp, isFlat) = NoteNumberHelper.numberToNote(number)
    
    return (noteName, octave, isSharp, isFlat)
}

