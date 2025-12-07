//
//  ToolbarViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

/// ViewModel для панели инструментов, управляющая удалением нот и выбором номера лада.
/// Отслеживает выбранную ноту и предоставляет интерфейс для изменения номера лада и удаления ноты.
@MainActor
class ToolbarViewModel: ObservableObject {
    @Published var selectedFret: TabFret
    @Published var isPlaying: Bool = false
    
    var onDeleteFret: (() -> Void)?
    var onUpdateFret: ((Int) -> Void)?
    var onTogglePlayPause: (() -> Void)?
    var onSave: (() -> Void)?
    var onLoad: (() -> Void)?
    
    init(selectedFret: TabFret) {
        self.selectedFret = selectedFret
    }
    
    func togglePlayPause() {
        isPlaying.toggle()
        onTogglePlayPause?()
    }
    
    func save() {
        onSave?()
    }
    
    func load() {
        onLoad?()
    }
    
    func deleteFret() {
        onDeleteFret?()
    }
    
    func updateFretNumber(_ fretNumber: Int) {
        onUpdateFret?(fretNumber)
    }
    
    func isFretNumberSelected(_ fretNumber: Int) -> Bool {
        selectedFret.fretNumber == fretNumber
    }
    
    var deleteButtonColor: Color {
        selectedFret.isSelected ? .red : .gray
    }
    
    var isDeleteButtonDisabled: Bool {
        !selectedFret.isSelected
    }
    
    var shouldShowFretSelector: Bool {
        selectedFret.isSelected
    }
}

