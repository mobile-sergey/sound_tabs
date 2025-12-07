//
//  NotePositionHelper.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

// Преобразует позицию стана в ноту и октаву
func getNoteFromStaffPosition(_ position: StaffPosition, currentOctave: Octave) -> (NoteName, Octave, Bool, Bool) {
    // Используем новую систему с цифрами через NoteNumberHelper
    let number = NoteNumberHelper.staffPositionToNumber(position)
    let (noteName, octave, isSharp, isFlat) = NoteNumberHelper.numberToNote(number)
    return (noteName, octave, isSharp, isFlat)
}

