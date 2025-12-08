//
//  TabStringViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

/// ViewModel для одной струны табулатуры, управляющая отображением ладов и вычислением их позиций.
/// Вычисляет позиции нот на струне, определяет выделенные ноты и создает ViewModels для отдельных ладов.
@MainActor
class TabStringViewModel: ObservableObject {
    @Published var string: TabString
    var stringIndex: Int
    var parentViewModel: TabLineViewModel?
    var tabSize: CGSize = .zero
    
    init(string: TabString, stringIndex: Int, parentViewModel: TabLineViewModel? = nil) {
        self.string = string
        self.stringIndex = stringIndex
        self.parentViewModel = parentViewModel
    }
    
    // Получаем актуальный fret из tabLine
    func getFret(by id: UUID) -> TabFret? {
        guard let parentVM = parentViewModel,
              stringIndex >= 0 && stringIndex < parentVM.tabLine.strings.count else {
            return nil
        }
        return parentVM.tabLine.strings[stringIndex].frets.first(where: { $0.id == id })
    }
    
    // Получаем актуальные frets из tabLine
    func getCurrentFrets() -> [TabFret] {
        guard let parentVM = parentViewModel,
              stringIndex >= 0 && stringIndex < parentVM.tabLine.strings.count else {
            return string.frets
        }
        return parentVM.tabLine.strings[stringIndex].frets
    }
    
    func calculateFretXPosition(for fret: TabFret, stringSize: CGSize) -> CGFloat {
        guard tabSize.width > 0 else { return 0 }
        
        let nameWidth: CGFloat = 25
        // Используем ту же логику, что и для маркеров, чтобы выровнять ноты по центру пересечения
        // fret.position уже сохранена как позиция относительно всего таба (0.0 - 1.0)
        // Вычисляем абсолютную позицию относительно всего таба
        let absoluteX = fret.position * tabSize.width
        
        // Позиция относительно stringSize (stringSize начинается после названия струны шириной nameWidth)
        // stringSize.width = tabSize.width - nameWidth
        // Позиция в stringSize = абсолютная позиция - nameWidth
        let fretX = absoluteX - nameWidth
        return max(0, min(stringSize.width, fretX))
    }
    
    func getNoteName(for fret: TabFret) -> String {
        GuitarNoteHelper.getNoteName(
            stringNoteName: string.noteName,
            fretNumber: fret.fretNumber
        )
    }
    
    func isFretSelected(_ fret: TabFret) -> Bool {
        let currentSelectedFret = parentViewModel?.parentViewModel?.selectedFret ?? TabFret(isSelected: false)
        return currentSelectedFret.isSelected && currentSelectedFret.id == fret.id
    }
    
    func stringLineYPosition(in stringGeometry: GeometryProxy) -> CGFloat {
        stringGeometry.size.height / 2
    }
    
    func handleFretTap(fret: TabFret) {
        // Передаем нажатие в parentViewModel для выделения
        parentViewModel?.parentViewModel?.selectFret(fret)
    }
    
    func createTabFretViewModel(for fret: TabFret, stringSize: CGSize) -> TabFretViewModel {
        let vm = TabFretViewModel(fretId: fret.id, parentViewModel: self)
        vm.stringSize = stringSize
        return vm
    }
}

