//
//  TabHeaderViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

/// ViewModel для заголовка таба, объединяющая темп (для первого таба), текст и аккорды.
/// Управляет редактированием темпа и текста, позиционированием аккордов.
@MainActor
class TabHeaderViewModel: ObservableObject {
    @Published var tempo: Int?
    @Published var text: String
    @Published var chords: [Chord]
    let isFirstTab: Bool
    let tabWidth: CGFloat
    var onTempoChange: ((Int) -> Void)?
    var onTextChange: ((String) -> Void)?
    var onFocusChange: (() -> Void)?
    
    init(
        tempo: Int? = nil,
        text: String,
        chords: [Chord],
        isFirstTab: Bool,
        tabWidth: CGFloat,
        onTempoChange: ((Int) -> Void)? = nil,
        onTextChange: ((String) -> Void)? = nil,
        onFocusChange: (() -> Void)? = nil
    ) {
        self.tempo = tempo
        self.text = text
        self.chords = chords
        self.isFirstTab = isFirstTab
        self.tabWidth = tabWidth
        self.onTempoChange = onTempoChange
        self.onTextChange = onTextChange
        self.onFocusChange = onFocusChange
    }
    
    func handleTempoFocusChange(_ isFocused: Bool) {
        if isFocused {
            onFocusChange?()
        }
    }
    
    func handleTextFocusChange(_ isFocused: Bool) {
        if isFocused {
            onFocusChange?()
        }
    }
    
    func handleTempoChange(_ newValue: Int) {
        let clampedValue = max(0, min(999, newValue))
        tempo = clampedValue
        onTempoChange?(clampedValue)
    }
    
    func handleTextChange(_ newValue: String) {
        text = newValue
        onTextChange?(newValue)
    }
    
    func chordXPosition(for chord: Chord, in geometry: GeometryProxy) -> CGFloat {
        let nameWidth: CGFloat = 25
        let availableWidth = tabWidth - nameWidth
        return nameWidth + availableWidth * CGFloat(chord.position)
    }
}

