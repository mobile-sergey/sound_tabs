//
//  TabLineContainerViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

/// ViewModel-контейнер для группы компонентов табулатуры: заголовка (темп, текст, аккорды) и самого таба.
/// Объединяет ViewModels для заголовка и таба в единый контейнер.
@MainActor
class TabLineContainerViewModel: ObservableObject {
    let isFirstTab: Bool
    let tabHeaderViewModel: TabHeaderViewModel
    let tabLineViewModel: TabLineViewModel
    
    init(
        tabLine: TabLine,
        index: Int,
        isFirstTab: Bool,
        metadata: TabMetadata,
        chords: [Chord],
        parentViewModel: ContentViewModel,
        tabWidth: CGFloat
    ) {
        self.isFirstTab = isFirstTab
        
        // ViewModel для заголовка таба (темп, текст, аккорды)
        self.tabHeaderViewModel = TabHeaderViewModel(
            tempo: isFirstTab ? metadata.tempo : nil,
            text: tabLine.textAbove,
            chords: chords.filter { $0.tabLineId == tabLine.id },
            isFirstTab: isFirstTab,
            tabWidth: tabWidth,
            onTempoChange: isFirstTab ? { newValue in
                parentViewModel.updateTempo(newValue)
            } : nil,
            onTextChange: { newText in
                if let lineIndex = parentViewModel.tabLines.firstIndex(where: { $0.id == tabLine.id }) {
                    parentViewModel.tabLines[lineIndex].textAbove = newText
                }
            },
            onFocusChange: {
                parentViewModel.deselectAllFrets()
            }
        )
        
        // ViewModel для таба
        self.tabLineViewModel = TabLineViewModel(
            tabLine: tabLine,
            tabLineIndex: index,
            parentViewModel: parentViewModel,
            metadata: metadata,
            isFirstTab: isFirstTab
        )
    }
}

