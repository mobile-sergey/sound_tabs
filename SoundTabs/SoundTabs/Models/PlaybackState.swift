//
//  PlaybackState.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// Модель для управления воспроизведением табулатуры.
@MainActor
class PlaybackState: ObservableObject {
    @Published var currentPosition: PlaybackPosition
    @Published var isPlaying: Bool = false
    
    var tempo: Int = 120 // BPM
    var timeSignatureTop: Int = 4
    var timeSignatureBottom: Int = 4
    
    private var timer: Timer?
    
    init(tabLineIndex: Int = 0, position: Double = 0.0) {
        self.currentPosition = PlaybackPosition(tabLineIndex: tabLineIndex, position: position)
    }
    
    /// Вычисляет интервал между позициями на основе темпа и размера такта
    func calculateStepInterval() -> TimeInterval {
        // BPM = beats per minute (удары в минуту)
        // Размер такта (например, 4/4) определяет, сколько долей в такте
        // Для 4/4: 4 доли на такт
        // Для 8 позиций на табе, каждая позиция = 1/8 такта
        
        // 1 доля = 60 / BPM секунд
        let beatDuration = 60.0 / Double(tempo)
        
        // 1 такт = timeSignatureTop долей
        let measureDuration = beatDuration * Double(timeSignatureTop)
        
        // 8 позиций на табе, каждая позиция = 1/8 такта
        let positionsPerMeasure = 8.0
        let positionDuration = measureDuration / positionsPerMeasure
        
        return positionDuration
    }
    
    func startPlayback(totalTabLines: Int, lastNoteTabIndex: Int, lastNotePosition: Double, onPositionUpdate: @escaping (PlaybackPosition) -> Void, onComplete: @escaping () -> Void) {
        guard !isPlaying else { return }
        
        isPlaying = true
        let stepInterval = calculateStepInterval()
        let divisions = 8 // Количество позиций на табе
        
        timer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isPlaying else {
                    self?.timer?.invalidate()
                    return
                }
                
                // Увеличиваем позицию на один шаг (1/8 таба)
                let step = 1.0 / Double(divisions)
                let newPosition = self.currentPosition.position + step
                
                // Проверяем, достигли ли мы последней ноты
                if self.currentPosition.tabLineIndex == lastNoteTabIndex && newPosition >= lastNotePosition {
                    // Достигли последней ноты - останавливаемся
                    self.currentPosition.position = lastNotePosition
                    self.objectWillChange.send()
                    self.stopPlayback()
                    onComplete()
                    return
                }
                
                // Если достигли конца таба, переходим на следующий
                if newPosition >= 1.0 {
                    if self.currentPosition.tabLineIndex < totalTabLines - 1 {
                        // Переходим на следующий таб
                        // Устанавливаем позицию на первую позицию для нот (с учётом отступов)
                        // Используем ту же логику, что и при инициализации
                        let screenWidth: CGFloat = 375 // Примерная ширина экрана iPhone
                        let startThinBarXPosition: CGFloat = 30
                        let timeSignatureWidth: CGFloat = 96
                        let spacing: CGFloat = 5
                        let startOffset = startThinBarXPosition + timeSignatureWidth + spacing
                        let firstNotePosition = Double(startOffset / screenWidth)
                        
                        // Обновляем свойства напрямую, чтобы сохранить id и триггернуть обновление
                        self.currentPosition.tabLineIndex = self.currentPosition.tabLineIndex + 1
                        self.currentPosition.position = firstNotePosition
                        // Триггерим обновление через objectWillChange
                        self.objectWillChange.send()
                    } else {
                        // Достигли последнего таба - останавливаемся на последней позиции
                        self.currentPosition.position = 1.0
                        self.objectWillChange.send()
                        self.stopPlayback()
                        onComplete()
                        return
                    }
                } else {
                    self.currentPosition.position = newPosition
                    // Триггерим обновление через objectWillChange
                    self.objectWillChange.send()
                }
                
                // onPositionUpdate вызывается для обратной совместимости, но позиция уже обновлена
                // и objectWillChange уже отправлен, так что UI обновится автоматически
                onPositionUpdate(self.currentPosition)
            }
        }
        
        // Добавляем таймер в RunLoop для правильной работы
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    func stopPlayback() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        // Останавливаем все звуки
        Task { @MainActor in
            GuitarSoundService.shared.stopAllNotes()
        }
    }
    
    func pausePlayback() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        // Останавливаем все звуки
        Task { @MainActor in
            GuitarSoundService.shared.stopAllNotes()
        }
    }
    
    func resumePlayback(totalTabLines: Int, lastNoteTabIndex: Int, lastNotePosition: Double, onPositionUpdate: @escaping (PlaybackPosition) -> Void, onComplete: @escaping () -> Void) {
        startPlayback(totalTabLines: totalTabLines, lastNoteTabIndex: lastNoteTabIndex, lastNotePosition: lastNotePosition, onPositionUpdate: onPositionUpdate, onComplete: onComplete)
    }
    
    func updateMetadata(tempo: Int, timeSignatureTop: Int, timeSignatureBottom: Int) {
        self.tempo = tempo
        self.timeSignatureTop = timeSignatureTop
        self.timeSignatureBottom = timeSignatureBottom
        
        // Если воспроизведение активно, перезапускаем с новыми параметрами
        if isPlaying {
            let wasPlaying = isPlaying
            let currentPos = currentPosition
            pausePlayback()
            if wasPlaying {
                // Сохраняем текущую позицию и возобновляем
                resumePlayback(totalTabLines: 100, lastNoteTabIndex: 100, lastNotePosition: 1.0, onPositionUpdate: { _ in }, onComplete: { })
                currentPosition = currentPos
            }
        }
    }
}

