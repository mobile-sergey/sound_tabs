//
//  ContentViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

/// Главная ViewModel приложения, управляющая всеми табулатурами, метаданными и выбранными нотами.
/// Отвечает за создание, удаление, выделение нот и обновление метаданных (темпа и размера такта).
@MainActor
class ContentViewModel: ObservableObject {
    @Published var tabLines: [TabLine] = [TabLine()]
    @Published var selectedFret: TabFret = TabFret(isSelected: false)
    @Published var metadata: TabMetadata = TabMetadata()
    @Published var chords: [Chord] = []
    
    init() {
        self.tabLines = [TabLine()]
    }
    
    func addTabLine() {
        let newLine = TabLine()
        tabLines.append(newLine)
    }
    
    func addFret(to lineId: UUID, stringIndex: Int, at position: Double, fretNumber: Int) {
        if let lineIndex = tabLines.firstIndex(where: { $0.id == lineId }),
           stringIndex >= 0 && stringIndex < tabLines[lineIndex].strings.count {
            // Позиция уже нормализована и привязана к делениям в TabLineViewModel
            // Просто сохраняем её как есть
            let newFret = TabFret(fretNumber: max(0, min(24, fretNumber)), position: position, isSelected: true)
            
            tabLines[lineIndex].strings[stringIndex].frets.append(newFret)
            selectedFret = newFret
        }
    }
    
    func deleteFret(_ fret: TabFret) {
        for lineIndex in tabLines.indices {
            for stringIndex in tabLines[lineIndex].strings.indices {
                if let fretIndex = tabLines[lineIndex].strings[stringIndex].frets.firstIndex(where: { $0.id == fret.id }) {
                    tabLines[lineIndex].strings[stringIndex].frets.remove(at: fretIndex)
                    if selectedFret.id == fret.id {
                        selectedFret = TabFret(isSelected: false)
                    }
                    return
                }
            }
        }
    }
    
    func updateFret(_ fret: TabFret) {
        for lineIndex in tabLines.indices {
            for stringIndex in tabLines[lineIndex].strings.indices {
                if let fretIndex = tabLines[lineIndex].strings[stringIndex].frets.firstIndex(where: { $0.id == fret.id }) {
                    var updatedFret = fret
                    updatedFret.isSelected = true
                    tabLines[lineIndex].strings[stringIndex].frets[fretIndex] = updatedFret
                    selectedFret = updatedFret
                    return
                }
            }
        }
    }
    
    func selectFret(_ fret: TabFret) {
        // Снимаем выделение со всех нот
        deselectAllFrets()
        
        // Выделяем новую ноту
        var updatedFret = fret
        updatedFret.isSelected = true
        selectedFret = updatedFret
        
        // Обновляем выделение в табах
        for lineIndex in tabLines.indices {
            for stringIndex in tabLines[lineIndex].strings.indices {
                for fretIndex in tabLines[lineIndex].strings[stringIndex].frets.indices {
                    if tabLines[lineIndex].strings[stringIndex].frets[fretIndex].id == fret.id {
                        tabLines[lineIndex].strings[stringIndex].frets[fretIndex].isSelected = true
                    }
                }
            }
        }
    }
    
    func deselectAllFrets() {
        // Снимаем выделение со всех нот
        for lineIndex in tabLines.indices {
            for stringIndex in tabLines[lineIndex].strings.indices {
                for fretIndex in tabLines[lineIndex].strings[stringIndex].frets.indices {
                    tabLines[lineIndex].strings[stringIndex].frets[fretIndex].isSelected = false
                }
            }
        }
        selectedFret = TabFret(isSelected: false)
    }
    
    func loadMoreIfNeeded(at index: Int) {
        // Пагинация: если прокрутили к последним 3 строкам, добавляем новые
        if index >= tabLines.count - 3 {
            addTabLine()
        }
    }
    
    func setupToolbarCallbacks(for toolbarViewModel: ToolbarViewModel) {
        toolbarViewModel.onDeleteFret = { [weak self] in
            guard let self = self else { return }
            if self.selectedFret.isSelected {
                self.deleteFret(self.selectedFret)
                toolbarViewModel.selectedFret = self.selectedFret
            }
        }
        
        toolbarViewModel.onUpdateFret = { [weak self] fretNumber in
            guard let self = self else { return }
            var fret = self.selectedFret
            fret.fretNumber = fretNumber
            self.updateFret(fret)
            toolbarViewModel.selectedFret = self.selectedFret
        }
    }
    
    func createTabLineContainerViewModel(
        for tabLine: TabLine,
        at index: Int,
        tabWidth: CGFloat
    ) -> TabLineContainerViewModel {
        return TabLineContainerViewModel(
            tabLine: tabLine,
            index: index,
            isFirstTab: index == 0,
            metadata: metadata,
            chords: chords,
            parentViewModel: self,
            tabWidth: tabWidth
        )
    }
    
    func updateTempo(_ newTempo: Int) {
        metadata.tempo = newTempo
    }
    
    func updateTimeSignature(top: Int, bottom: Int) {
        metadata.sizeTop = top
        metadata.sizeBottom = bottom
    }
}

