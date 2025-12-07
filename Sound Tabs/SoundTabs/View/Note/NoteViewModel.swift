//
//  NoteViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

class NoteViewModel: ObservableObject {
    @Published var note: Note {
        didSet {
            onNoteChanged?(note)
        }
    }
    @Published var isSelected: Bool
    @Published var showNoteName: Bool
    
    var onDrag: ((CGSize, CGPoint) -> Void)?
    var onDragEnd: (() -> Void)?
    var onNoteChanged: ((Note) -> Void)?
    
    init(
        note: Note,
        isSelected: Bool = false,
        showNoteName: Bool = false,
        onDrag: ((CGSize, CGPoint) -> Void)? = nil,
        onDragEnd: (() -> Void)? = nil,
        onNoteChanged: ((Note) -> Void)? = nil
    ) {
        self.note = note
        self.isSelected = isSelected
        self.showNoteName = showNoteName
        self.onDrag = onDrag
        self.onDragEnd = onDragEnd
        self.onNoteChanged = onNoteChanged
    }
    
    var noteName: String {
        var name = note.name.rawValue
        if note.isSharp {
            name += "♯"
        } else if note.isFlat {
            name += "♭"
        }
        name += "\(note.octave.rawValue)"
        return name
    }
    
    var noteNumber: Int {
        NoteNumberHelper.noteToNumber(note)
    }
    
    func handleDragChanged(translation: CGSize, location: CGPoint) {
        onDrag?(translation, location)
    }
    
    func handleDragEnded(translation: CGSize, location: CGPoint) {
        onDrag?(translation, location)
        onDragEnd?()
    }
}

