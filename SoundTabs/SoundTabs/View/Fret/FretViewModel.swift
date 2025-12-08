//
//  FretViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// ViewModel для визуального отображения номера лада с поддержкой выделения.
/// Управляет номером лада и состоянием выделения для отображения в FretView.
class FretViewModel: ObservableObject {
    @Published var fretNumber: Int
    @Published var isSelected: Bool
    
    init(fretNumber: Int, isSelected: Bool = false) {
        self.fretNumber = fretNumber
        self.isSelected = isSelected
    }
}

