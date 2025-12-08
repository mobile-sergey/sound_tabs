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
    @Published var selectedMeasureBar: MeasureBar?
    @Published var isPlaying: Bool = false
    
    var onDeleteFret: (() -> Void)?
    var onUpdateFret: ((Int) -> Void)?
    var onUpdateMeasureDuration: ((MeasureDuration) -> Void)?
    var onTogglePlayPause: (() -> Void)?
    var onSave: (() -> Void)?
    var onLoad: (() -> Void)?
    
    init(selectedFret: TabFret, selectedMeasureBar: MeasureBar? = nil) {
        self.selectedFret = selectedFret
        self.selectedMeasureBar = selectedMeasureBar
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
    
    func updateMeasureDuration(_ duration: MeasureDuration) {
        onUpdateMeasureDuration?(duration)
    }
    
    func isFretNumberSelected(_ fretNumber: Int) -> Bool {
        selectedFret.fretNumber == fretNumber
    }
    
    func isMeasureDurationSelected(_ duration: MeasureDuration) -> Bool {
        selectedMeasureBar?.measureDuration == duration
    }
    
    var deleteButtonColor: Color {
        (selectedFret.isSelected || selectedMeasureBar != nil) ? .red : .gray
    }
    
    var isDeleteButtonDisabled: Bool {
        !selectedFret.isSelected && selectedMeasureBar == nil
    }
    
    var shouldShowFretSelector: Bool {
        selectedFret.isSelected && selectedMeasureBar == nil
    }
    
    var shouldShowMeasureDurationSelector: Bool {
        selectedMeasureBar != nil
    }
}

