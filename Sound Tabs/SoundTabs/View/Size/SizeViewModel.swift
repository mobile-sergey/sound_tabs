//
//  SizeViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

/// ViewModel для размера такта (две цифры вертикально), управляющая их редактированием и позиционированием.
/// Вычисляет позиции полей ввода, обрабатывает изменения размера такта (например, 4/4).
@MainActor
class SizeViewModel: ObservableObject {
    @Published var sizeTop: Int
    @Published var sizeBottom: Int
    let nameWidth: CGFloat
    let tabHeight: CGFloat
    let startThinBarXPosition: CGFloat
    var onSizeChange: ((Int, Int) -> Void)?
    var onFocusChange: (() -> Void)?
    
    init(
        sizeTop: Int,
        sizeBottom: Int,
        nameWidth: CGFloat,
        tabHeight: CGFloat,
        startThinBarXPosition: CGFloat,
        onSizeChange: ((Int, Int) -> Void)? = nil,
        onFocusChange: (() -> Void)? = nil
    ) {
        self.sizeTop = sizeTop
        self.sizeBottom = sizeBottom
        self.nameWidth = nameWidth
        self.tabHeight = tabHeight
        self.startThinBarXPosition = startThinBarXPosition
        self.onSizeChange = onSizeChange
        self.onFocusChange = onFocusChange
    }
    
    func handleTopFocusChange(_ isFocused: Bool) {
        if isFocused {
            onFocusChange?()
        }
    }
    
    func handleBottomFocusChange(_ isFocused: Bool) {
        if isFocused {
            onFocusChange?()
        }
    }
    
    func handleTopChange(_ newValue: Int) {
        // Ограничение: максимум 2 цифры (0-99)
        let clampedValue = max(0, min(99, newValue))
        sizeTop = clampedValue
        onSizeChange?(clampedValue, sizeBottom)
    }
    
    func handleBottomChange(_ newValue: Int) {
        // Ограничение: максимум 2 цифры (0-99)
        let clampedValue = max(0, min(99, newValue))
        sizeBottom = clampedValue
        onSizeChange?(sizeTop, clampedValue)
    }
    
    var sizeXPosition: CGFloat {
        startThinBarXPosition + 8 + 40 // После точек (8) + центр ширины (40, т.к. ширина теперь 80)
    }
    
    var sizeYPosition: CGFloat {
        tabHeight / 2
    }
    
    var fontSize: CGFloat {
        tabHeight / 3.0
    }
    
    var fieldWidth: CGFloat {
        80
    }
    
    var fieldHeight: CGFloat {
        tabHeight / 2
    }
}

