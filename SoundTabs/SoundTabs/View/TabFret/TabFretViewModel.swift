//
//  TabFretViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

/// ViewModel для одного лада на струне, управляющая его отображением и взаимодействием.
/// Вычисляет позицию лада, определяет его выделение и название ноты, обрабатывает тапы.
@MainActor
class TabFretViewModel: ObservableObject {
    let fretId: UUID
    var parentViewModel: TabStringViewModel?
    var stringSize: CGSize = .zero
    
    init(fretId: UUID, parentViewModel: TabStringViewModel? = nil) {
        self.fretId = fretId
        self.parentViewModel = parentViewModel
    }
    
    // Получаем актуальный fret из данных
    var fret: TabFret? {
        return parentViewModel?.getFret(by: fretId)
    }
    
    var isSelected: Bool {
        guard let fret = fret else { return false }
        return parentViewModel?.isFretSelected(fret) ?? false
    }
    
    var noteName: String {
        guard let fret = fret else { return "" }
        return parentViewModel?.getNoteName(for: fret) ?? ""
    }
    
    var fretXPosition: CGFloat {
        guard let parentViewModel = parentViewModel, let fret = fret else {
            return 0
        }
        // Всегда получаем актуальную позицию из данных
        return parentViewModel.calculateFretXPosition(for: fret, stringSize: stringSize)
    }
    
    var fretYPosition: CGFloat {
        stringSize.height / 2
    }
    
    func handleTap() {
        guard let fret = fret else { return }
        // Выделяем ноту при нажатии
        parentViewModel?.handleFretTap(fret: fret)
    }
    
    func createFretViewModel() -> FretViewModel {
        guard let fret = fret else {
            return FretViewModel(fretNumber: 0, isSelected: false)
        }
        return FretViewModel(
            fretNumber: fret.fretNumber,
            isSelected: isSelected
        )
    }
}

