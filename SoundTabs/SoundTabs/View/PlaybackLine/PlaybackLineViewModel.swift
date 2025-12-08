//
//  PlaybackLineViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel для управления зелёной линией воспроизведения/выделения.
/// Определяет, где и когда должна отображаться зелёная линия.
@MainActor
class PlaybackLineViewModel: ObservableObject {
    var playbackState: PlaybackState?
    var parentViewModel: ContentViewModel?
    var tabLineIndex: Int
    
    init(playbackState: PlaybackState?, parentViewModel: ContentViewModel?, tabLineIndex: Int) {
        self.playbackState = playbackState
        self.parentViewModel = parentViewModel
        self.tabLineIndex = tabLineIndex
        
        // Подписываемся на изменения
        if let playback = playbackState {
            // Подписываемся на objectWillChange самого PlaybackState, чтобы ловить все изменения
            playback.objectWillChange
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
            
            playback.$isPlaying
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
        
        if let parentVM = parentViewModel {
            parentVM.$selectedFret
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Определяет, должна ли зелёная линия отображаться на этом табе
    /// Зелёная линия всегда показывает playbackState.currentPosition - это единственный источник истины
    func shouldShowLine() -> Bool {
        // Показываем линию только если это текущий таб в playbackState.currentPosition
        if let playback = playbackState,
           playback.currentPosition.tabLineIndex == tabLineIndex {
            return true
        }
        return false
    }
    
    /// Получает позицию зелёной линии для отображения
    /// Всегда возвращает позицию из playbackState.currentPosition
    func getLinePosition() -> Double {
        if let playback = playbackState,
           playback.currentPosition.tabLineIndex == tabLineIndex {
            return playback.currentPosition.position
        }
        return 0.0
    }
    
    /// Вычисляет X-позицию для зелёной линии
    func calculateXPosition(for position: Double, in geometry: GeometryProxy) -> CGFloat {
        // Позиция ноты хранится как позиция относительно всего таба (0.0 - 1.0)
        // Вычисляем абсолютную позицию относительно всего таба
        return position * geometry.size.width
    }
}

