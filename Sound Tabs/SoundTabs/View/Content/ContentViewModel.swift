//
//  ContentViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI
import UIKit

/// Главная ViewModel приложения, управляющая всеми табулатурами, метаданными и выбранными нотами.
/// Отвечает за создание, удаление, выделение нот и обновление метаданных (темпа и размера такта).
@MainActor
class ContentViewModel: ObservableObject {
    @Published var tabLines: [TabLine] = [TabLine()]
    @Published var selectedFret: TabFret = TabFret(isSelected: false)
    @Published var metadata: TabMetadata = TabMetadata()
    @Published var chords: [Chord] = []
    @Published var playbackState: PlaybackState
    @Published var shouldShowMIDIPicker: Bool = false
    @Published var shouldShowTrackSelector: Bool = false
    @Published var availableTracks: [MIDITrackInfo] = []
    @Published var selectedTrackIndex: Int = 0
    
    init() {
        self.tabLines = [TabLine()]
        // Позиция воспроизведения должна соответствовать первой позиции, где могут быть ноты
        // Вычисляем нормализованную позицию с учётом отступов (как при создании ноты)
        // Используем те же константы, что и в TabLineViewModel:
        // startThinBarXPosition = 30
        // timeSignatureWidth = 96
        // spacing = 5
        // startOffset = 30 + 96 + 5 = 131
        // endOffset = 30
        // Для стандартной ширины экрана iPhone (~375): 
        // startOffset/width ≈ 131/375 ≈ 0.35
        // Первая позиция (snappedPosition = 0): position = startOffset/width
        // Используем примерное значение для стандартной ширины экрана
        let screenWidth: CGFloat = 375 // Примерная ширина экрана iPhone
        let startThinBarXPosition: CGFloat = 30
        let timeSignatureWidth: CGFloat = 96
        let spacing: CGFloat = 5
        let startOffset = startThinBarXPosition + timeSignatureWidth + spacing
        let initialPosition = Double(startOffset / screenWidth)
        self.playbackState = PlaybackState(tabLineIndex: 0, position: initialPosition)
        self.playbackState.tempo = metadata.tempo
        self.playbackState.timeSignatureTop = metadata.sizeTop
        self.playbackState.timeSignatureBottom = metadata.sizeBottom
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
            
            // Обновляем позицию воспроизведения на позицию новой ноты
            playbackState.currentPosition.tabLineIndex = lineIndex
            playbackState.currentPosition.position = position
            // Триггерим обновление UI явно
            playbackState.objectWillChange.send()
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
        
        // Обновляем позицию воспроизведения на позицию выделенной ноты
        // Находим таб, на котором находится выделенная нота
        for (lineIndex, tabLine) in tabLines.enumerated() {
            for string in tabLine.strings {
                if string.frets.contains(where: { $0.id == fret.id }) {
                    // Обновляем позицию воспроизведения на позицию выделенной ноты
                    // Это позволяет продолжить воспроизведение с новой позиции
                    // Обновляем напрямую свойства, чтобы сохранить тот же id и не сломать подписки
                    playbackState.currentPosition.tabLineIndex = lineIndex
                    playbackState.currentPosition.position = fret.position
                    // Триггерим обновление UI явно
                    playbackState.objectWillChange.send()
                    // НЕ останавливаем воспроизведение - оно должно продолжаться с новой позиции
                    // Если воспроизведение было на паузе, оно останется на паузе, но позиция обновится
                    return
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
        
        toolbarViewModel.onTogglePlayPause = { [weak self] in
            self?.togglePlayback()
        }
        
        toolbarViewModel.onSave = { [weak self] in
            self?.saveData()
        }
        
        toolbarViewModel.onLoad = { [weak self] in
            self?.loadData()
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
        playbackState.updateMetadata(tempo: newTempo, timeSignatureTop: metadata.sizeTop, timeSignatureBottom: metadata.sizeBottom)
    }
    
    func updateTimeSignature(top: Int, bottom: Int) {
        metadata.sizeTop = top
        metadata.sizeBottom = bottom
        playbackState.updateMetadata(tempo: metadata.tempo, timeSignatureTop: top, timeSignatureBottom: bottom)
    }
    
    /// Находит последнюю ноту во всех табах
    func findLastNotePosition() -> (tabLineIndex: Int, position: Double)? {
        var lastTabIndex = -1
        var lastPosition: Double = 0.0
        
        for (tabIndex, tabLine) in tabLines.enumerated() {
            for string in tabLine.strings {
                for fret in string.frets {
                    if tabIndex > lastTabIndex || (tabIndex == lastTabIndex && fret.position > lastPosition) {
                        lastTabIndex = tabIndex
                        lastPosition = fret.position
                    }
                }
            }
        }
        
        if lastTabIndex >= 0 {
            return (lastTabIndex, lastPosition)
        }
        
        return nil
    }
    
    func togglePlayback() {
        if playbackState.isPlaying {
            playbackState.pausePlayback()
        } else {
            // Если есть выделенная нота, начинаем воспроизведение с её позиции
            // Позиция уже обновлена в selectFret, но на всякий случай обновим здесь тоже
            if selectedFret.isSelected {
                // Находим таб, на котором находится выделенная нота
                var foundTabIndex = playbackState.currentPosition.tabLineIndex
                for (lineIndex, tabLine) in tabLines.enumerated() {
                    for string in tabLine.strings {
                        if string.frets.contains(where: { $0.id == selectedFret.id }) {
                            foundTabIndex = lineIndex
                            break
                        }
                    }
                }
                // Обновляем позицию воспроизведения на позицию выделенной ноты
                // Обновляем напрямую свойства, чтобы сохранить тот же id
                playbackState.currentPosition.tabLineIndex = foundTabIndex
                playbackState.currentPosition.position = selectedFret.position
                // Триггерим обновление UI
                playbackState.objectWillChange.send()
            }
            // Иначе используем текущую позицию воспроизведения (которая уже может быть обновлена)
            
            // Находим последнюю ноту
            let lastNote = findLastNotePosition()
            let lastTabIndex = lastNote?.tabLineIndex ?? (tabLines.count - 1)
            let lastPosition = lastNote?.position ?? 1.0
            
            playbackState.startPlayback(
                totalTabLines: tabLines.count,
                lastNoteTabIndex: lastTabIndex,
                lastNotePosition: lastPosition,
                onPositionUpdate: { _ in
                    // Позиция уже обновлена в таймере через objectWillChange
                    // Здесь просто синхронизируем, если нужно
                    // Но лучше не обновлять, так как это может создать конфликт
                },
                onComplete: { [weak self] in
                    self?.playbackState.isPlaying = false
                }
            )
        }
    }
    
    func saveData() {
        // Экспорт в MIDI файл
        // Создаём временный URL для сохранения
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "tablature_\(Date().timeIntervalSince1970).mid"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try MIDIService.exportMIDI(
                tabLines: tabLines,
                tempo: metadata.tempo,
                timeSignatureTop: metadata.sizeTop,
                timeSignatureBottom: metadata.sizeBottom,
                to: fileURL
            )
            
            // Показываем диалог для сохранения файла через UIActivityViewController
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = rootViewController.view
                        popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                    rootViewController.present(activityVC, animated: true)
                }
            }
        } catch {
            print("Ошибка экспорта MIDI: \(error)")
            // TODO: Показать ошибку пользователю
        }
    }
    
    func loadData() {
        // Импорт из MIDI файла
        // Показываем диалог выбора файла
        shouldShowMIDIPicker = true
    }
    
    /// Загружает MIDI файл и импортирует данные
    func importMIDIFile(from url: URL) {
        // Получаем доступ к файлу (security-scoped resource)
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            // Парсим MIDI файл
            let midiInfo = try MIDIParser.parseMIDIFile(from: url)
            
            // Если треков больше одного, показываем диалог выбора
            if midiInfo.tracks.count > 1 {
                availableTracks = midiInfo.tracks
                selectedTrackIndex = 0
                shouldShowTrackSelector = true
                // Сохраняем информацию о файле для последующего импорта
                pendingMIDIInfo = midiInfo
            } else if midiInfo.tracks.count == 1 {
                // Если трек один, загружаем его сразу
                importSelectedTrack(midiInfo: midiInfo, trackIndex: 0)
            }
            
        } catch {
            // TODO: Показать ошибку пользователю
        }
    }
    
    private var pendingMIDIInfo: MIDIFileInfo?
    
    /// Импортирует выбранный трек
    func importSelectedTrack(midiInfo: MIDIFileInfo, trackIndex: Int) {
        do {
            let (importedTabLines, tempo, timeSignatureTop, timeSignatureBottom) = try MIDIService.importMIDIFromTrack(
                midiInfo: midiInfo,
                trackIndex: trackIndex
            )
            
            // Обновляем данные
            tabLines = importedTabLines
            metadata.tempo = tempo
            metadata.sizeTop = timeSignatureTop
            metadata.sizeBottom = timeSignatureBottom
            
            // Обновляем playbackState
            playbackState.tempo = tempo
            playbackState.timeSignatureTop = timeSignatureTop
            playbackState.timeSignatureBottom = timeSignatureBottom
            
            // Вычисляем начальную позицию с учётом отступов
            let screenWidth: CGFloat = 375
            let startThinBarXPosition: CGFloat = 30
            let timeSignatureWidth: CGFloat = 96
            let spacing: CGFloat = 5
            let startOffset = startThinBarXPosition + timeSignatureWidth + spacing
            let initialPosition = Double(startOffset / screenWidth)
            playbackState.currentPosition = PlaybackPosition(tabLineIndex: 0, position: initialPosition)
            
        } catch {
            // TODO: Показать ошибку пользователю
        }
    }
    
    /// Подтверждает выбор трека и импортирует его
    func confirmTrackSelection() {
        guard let midiInfo = pendingMIDIInfo else { return }
        importSelectedTrack(midiInfo: midiInfo, trackIndex: selectedTrackIndex)
        shouldShowTrackSelector = false
        pendingMIDIInfo = nil
    }
}

