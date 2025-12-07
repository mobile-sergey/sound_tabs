//
//  SingleStaffLineViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

class SingleStaffLineViewModel: ObservableObject {
    @Published var staffLine: StaffLine
    @Published var selectedNote: Note?
    @Published var selectionRange: SelectionRange
    @Published var isSelecting: Bool
    var repeatMark: RepeatMark?
    var isRepeatMode: Bool
    var selectedRepeatLine: RepeatLineType?
    
    let staffLineSpacing: CGFloat = 20
    let staffHeight: CGFloat = 100
    
    init(
        staffLine: StaffLine,
        selectedNote: Note? = nil,
        selectionRange: SelectionRange = SelectionRange(),
        isSelecting: Bool = false,
        repeatMark: RepeatMark? = nil,
        isRepeatMode: Bool = false,
        selectedRepeatLine: RepeatLineType? = nil
    ) {
        self.staffLine = staffLine
        self.selectedNote = selectedNote
        self.selectionRange = selectionRange
        self.isSelecting = isSelecting
        self.repeatMark = repeatMark
        self.isRepeatMode = isRepeatMode
        self.selectedRepeatLine = selectedRepeatLine
    }
    
    var shouldShowSelection: Bool {
        selectionRange.isActive && selectionRange.staffLineId == staffLine.id
    }
    
    func handleNoteDrag(translation: CGSize, location: CGPoint, note: Note, geometry: GeometryProxy) -> Note? {
        let normalizedX = max(0, min(1, location.x / geometry.size.width))
        let snappedX = snapToDivision(normalizedX, divisions: 16)
        
        guard isPositionAfterClef(snappedX) else { return nil }
        
        let staffCenterY = geometry.size.height / 2
        let relativeY = location.y - staffCenterY
        let newNote = snapToStaffLineByY(relativeY: relativeY, currentNote: note)
        
        let noteWithNewPosition = Note(
            name: newNote.name,
            octave: newNote.octave,
            duration: newNote.duration,
            position: snappedX,
            isSharp: newNote.isSharp,
            isFlat: newNote.isFlat
        )
        
        if let index = staffLine.notes.firstIndex(where: { $0.id == note.id }) {
            staffLine.notes[index] = noteWithNewPosition
            selectedNote = noteWithNewPosition
            return noteWithNewPosition
        }
        return nil
    }
    
    func snapToStaffLineByY(relativeY: CGFloat, currentNote: Note) -> Note {
        let staffLineSpacing: CGFloat = 20
        let stepCount = Int(round(relativeY / (staffLineSpacing / 2)))
        
        let currentPosition = getStaffPosition(for: currentNote)
        let newPositionRaw = currentPosition.rawValue - stepCount
        
        let clampedPositionRaw = max(StaffPosition.above5.rawValue, min(StaffPosition.below1.rawValue, newPositionRaw))
        
        guard let newPosition = StaffPosition(rawValue: clampedPositionRaw) else {
            return currentNote
        }
        
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
    
    func isWithinStaffBounds(_ location: CGPoint, in geometry: GeometryProxy) -> Bool {
        let clefWidth: CGFloat = 50
        let staffStartX = clefWidth
        let staffEndX = geometry.size.width - 40
        
        let isWithinHorizontalBounds = location.x >= staffStartX && location.x <= staffEndX
        
        let staffCenterY = geometry.size.height / 2
        let staffTop = staffCenterY - staffHeight / 2
        let staffBottom = staffCenterY + staffHeight / 2
        let isWithinVerticalBounds = location.y >= staffTop && location.y <= staffBottom
        
        return isWithinHorizontalBounds && isWithinVerticalBounds
    }
    
    func findNoteAt(location: CGPoint, in geometry: GeometryProxy) -> Note? {
        let tapRadius: CGFloat = 30
        
        for note in staffLine.notes {
            let x = geometry.size.width * note.position
            let yOffset = getStaffPosition(for: note).yOffset
            let y = geometry.size.height / 2 + yOffset
            
            let distance = sqrt(pow(location.x - x, 2) + pow(location.y - y, 2))
            if distance < tapRadius {
                return note
            }
        }
        return nil
    }
}

