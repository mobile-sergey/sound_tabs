//
//  ContentViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI
import UIKit
import Combine

/// Главная ViewModel приложения, управляющая всеми табулатурами, метаданными и выбранными нотами.
/// Отвечает за создание, удаление, выделение нот и обновление метаданных (темпа и размера такта).
@MainActor
class ContentViewModel: ObservableObject {
    @Published var tabLines: [TabLine] = [TabLine()]
    @Published var selectedFret: TabFret = TabFret(isSelected: false)
    @Published var selectedMeasureBar: MeasureBar? = nil
    @Published var metadata: TabMetadata = TabMetadata()
    @Published var chords: [Chord] = []
    @Published var playbackState: PlaybackState
    @Published var shouldShowMIDIPicker: Bool = false
    @Published var shouldShowTrackSelector: Bool = false
    @Published var trackSelectorViewModel: TrackSelectorViewModel?
    @Published var toolbarViewModel: ToolbarViewModel
    @Published var selectedRepeat: TabRepeat = TabRepeat(startTab: UUID(), startPosition: 0.0, endTab: UUID(), endPosition: 1.0)
    @Published var isRepeatEnabled: Bool = false
    @Published var selectedRepeatType: RepeatType? = nil // nil, .start, .end
    
    enum RepeatType {
        case start
        case end
    }
    
    private var availableTracks: [MIDITrackInfo] = []
    private var selectedTrackIndex: Int = 0
    
    init() {
        let lines = [TabLine()]
        self.tabLines = lines
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
        
        // Создаем ToolbarViewModel после инициализации всех stored properties
        // Используем значения по умолчанию напрямую, без обращения к self
        let defaultFret = TabFret(isSelected: false)
        let defaultMeasureBar: MeasureBar? = nil
        let firstTabId = lines.first?.id ?? UUID()
        let startRepeat = TabRepeat(startTab: firstTabId, startPosition: 0.0, endTab: firstTabId, endPosition: 1.0)
        self.selectedRepeat = startRepeat
        self.toolbarViewModel = ToolbarViewModel(selectedFret: defaultFret, selectedMeasureBar: defaultMeasureBar, selectedRepeat: startRepeat)
        self.toolbarViewModel.isRepeatEnabled = false
        
        // Теперь можем использовать все свойства для настройки
        self.playbackState.tempo = metadata.tempo
        self.playbackState.timeSignatureTop = metadata.sizeTop
        self.playbackState.timeSignatureBottom = metadata.sizeBottom
        
        // Настраиваем callbacks для ToolbarViewModel
        setupToolbarCallbacks(for: toolbarViewModel)
        
        // Подписываемся на изменения для синхронизации с ToolbarViewModel
        $selectedFret
            .sink { [weak self] fret in
                self?.toolbarViewModel.selectedFret = fret
            }
            .store(in: &cancellables)
        
        $selectedMeasureBar
            .sink { [weak self] measureBar in
                self?.toolbarViewModel.selectedMeasureBar = measureBar
            }
            .store(in: &cancellables)
        
        playbackState.$isPlaying
            .sink { [weak self] isPlaying in
                self?.toolbarViewModel.isPlaying = isPlaying
            }
            .store(in: &cancellables)
        
        $isRepeatEnabled
            .sink { [weak self] isEnabled in
                self?.toolbarViewModel.isRepeatEnabled = isEnabled
            }
            .store(in: &cancellables)

    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func addTabLine() {
        let newLine = TabLine()
        tabLines.append(newLine)
    }
    
    func addFret(to lineId: UUID, stringIndex: Int, at position: Double, fretNumber: Int) {
        if let lineIndex = tabLines.firstIndex(where: { $0.id == lineId }),
           stringIndex >= 0 && stringIndex < tabLines[lineIndex].strings.count {
            // Снимаем выделение со всех нот и тактов перед созданием новой ноты
            deselectAllFrets()
            deselectAllMeasureBars()
            
            // Позиция уже нормализована и привязана к делениям в TabLineViewModel
            // Просто сохраняем её как есть
            let newFret = TabFret(fretNumber: max(0, min(24, fretNumber)), position: position, isSelected: true)
            
            tabLines[lineIndex].strings[stringIndex].frets.append(newFret)
            selectedFret = newFret
            
            // Обновляем выделение в табах
            for lineIdx in tabLines.indices {
                for strIdx in tabLines[lineIdx].strings.indices {
                    for fretIdx in tabLines[lineIdx].strings[strIdx].frets.indices {
                        if tabLines[lineIdx].strings[strIdx].frets[fretIdx].id == newFret.id {
                            tabLines[lineIdx].strings[strIdx].frets[fretIdx].isSelected = true
                        }
                    }
                }
            }
            
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
        // Снимаем выделение со всех нот и тактов
        deselectAllFrets()
        deselectAllMeasureBars()
        
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
    
    func selectMeasureBar(_ measureBar: MeasureBar, in tabLineId: UUID) {
        // Снимаем выделение со всех нот и тактов
        deselectAllFrets()
        deselectAllMeasureBars()
        
        // Выделяем новый такт
        selectedMeasureBar = measureBar
        
        // Обновляем выделение в табах
        if let lineIndex = tabLines.firstIndex(where: { $0.id == tabLineId }) {
            for stringIndex in tabLines[lineIndex].strings.indices {
                if let barIndex = tabLines[lineIndex].strings[stringIndex].measureBars.firstIndex(where: { $0.id == measureBar.id }) {
                    tabLines[lineIndex].strings[stringIndex].measureBars[barIndex].isSelected = true
                }
            }
        }
    }
    
    func deselectAllMeasureBars() {
        // Снимаем выделение со всех тактов
        for lineIndex in tabLines.indices {
            for stringIndex in tabLines[lineIndex].strings.indices {
                for barIndex in tabLines[lineIndex].strings[stringIndex].measureBars.indices {
                    tabLines[lineIndex].strings[stringIndex].measureBars[barIndex].isSelected = false
                }
            }
        }
        selectedMeasureBar = nil
    }
    
    func selectRepeat(_ type: RepeatType) {
        // Снимаем выделение со всех нот и тактов
        deselectAllFrets()
        deselectAllMeasureBars()
        selectedRepeatType = type
    }
    
    func deselectRepeat() {
        selectedRepeatType = nil
    }
    
    func updateRepeatPosition(type: RepeatType, tabLineId: UUID, position: Double) {
        // Обновляем позицию Repeat с привязкой к делениям
        let divisions = 8
        let snappedPosition = NoteSnappingHelper.snapToDivision(position, divisions: divisions)
        
        var updatedRepeat = selectedRepeat
        if type == .start {
            updatedRepeat.startTab = tabLineId
            updatedRepeat.startPosition = snappedPosition
        } else {
            updatedRepeat.endTab = tabLineId
            updatedRepeat.endPosition = snappedPosition
        }
        selectedRepeat = updatedRepeat
    }
    
    func findTabLineAt(yPosition: CGFloat, tabLineHeight: CGFloat) -> UUID? {
        // Находим таб по вертикальной позиции
        let tabIndex = Int(yPosition / tabLineHeight)
        if tabIndex >= 0 && tabIndex < tabLines.count {
            return tabLines[tabIndex].id
        }
        return nil
    }
    
    func updateMeasureBarDuration(_ measureBar: MeasureBar, duration: MeasureDuration, in tabLineId: UUID) {
        // Обновляем длину такта
        if let lineIndex = tabLines.firstIndex(where: { $0.id == tabLineId }) {
            for stringIndex in tabLines[lineIndex].strings.indices {
                if let barIndex = tabLines[lineIndex].strings[stringIndex].measureBars.firstIndex(where: { $0.id == measureBar.id }) {
                    tabLines[lineIndex].strings[stringIndex].measureBars[barIndex].measureDuration = duration
                    // Обновляем selectedMeasureBar
                    if selectedMeasureBar?.id == measureBar.id {
                        var updatedBar = tabLines[lineIndex].strings[stringIndex].measureBars[barIndex]
                        updatedBar.isSelected = true
                        selectedMeasureBar = updatedBar
                    }
                }
            }
        }
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
            } else if self.selectedMeasureBar != nil {
                // Удаление такта - снимаем выделение
                self.deselectAllMeasureBars()
                toolbarViewModel.selectedMeasureBar = nil
            }
        }
        
        toolbarViewModel.onUpdateFret = { [weak self] fretNumber in
            guard let self = self else { return }
            var fret = self.selectedFret
            fret.fretNumber = fretNumber
            self.updateFret(fret)
            toolbarViewModel.selectedFret = self.selectedFret
        }
        
        toolbarViewModel.onUpdateMeasureDuration = { [weak self] duration in
            guard let self = self else { return }
            if let measureBar = self.selectedMeasureBar,
               let tabLine = self.tabLines.first(where: { line in
                   line.strings.contains { string in
                       string.measureBars.contains { $0.id == measureBar.id }
                   }
               }) {
                self.updateMeasureBarDuration(measureBar, duration: duration, in: tabLine.id)
                toolbarViewModel.selectedMeasureBar = self.selectedMeasureBar
            }
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
        
        toolbarViewModel.onRepeat = { [weak self] in
            guard let self = self else { return }
            // Если после загрузки MIDI id не найдены, ставим repeat на первый таб
            if self.tabLines.first(where: { $0.id == self.selectedRepeat.startTab }) == nil ||
                self.tabLines.first(where: { $0.id == self.selectedRepeat.endTab }) == nil {
                if let firstId = self.tabLines.first?.id {
                    let newRepeat = TabRepeat(startTab: firstId, startPosition: 0.0, endTab: firstId, endPosition: 1.0)
                    self.selectedRepeat = newRepeat
                    self.toolbarViewModel.selectedRepeat = newRepeat
                }
            }
            // Синхронизируем состояние из ToolbarViewModel в ContentViewModel
            self.isRepeatEnabled = self.toolbarViewModel.isRepeatEnabled
        }
        
//        // Также подписываемся на изменения isRepeatEnabled в ToolbarViewModel для двусторонней синхронизации
//        toolbarViewModel.$isRepeatEnabled
//            .sink { [weak self] isEnabled in
//                self?.isRepeatEnabled = isEnabled
//            }
//            .store(in: &cancellables)
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
    
    private var lastPlayedPosition: (tabLineIndex: Int, position: Double)? = nil
    private var playedNoteIds: Set<UUID> = [] // Отслеживаем уже проигранные ноты
    
    /// Проигрывает ноты на указанной позиции
    private func playNotesAtPosition(_ position: PlaybackPosition) {
        guard position.tabLineIndex >= 0 && position.tabLineIndex < tabLines.count else {
            return
        }
        
        let tabLine = tabLines[position.tabLineIndex]
        // Увеличиваем tolerance для более надежного поиска нот
        // Учитываем, что зеленая линия движется с шагом 1/8 таба
        let stepSize = 1.0 / 8.0
        let tolerance: Double = stepSize * 0.6 // 60% от шага - достаточно для надежного поиска
        
        // Находим все ноты в окрестности текущей позиции
        var notesToPlay: [(stringIndex: Int, fret: TabFret)] = []
        
        for (stringIndex, string) in tabLine.strings.enumerated() {
            for fret in string.frets {
                // Проверяем, находится ли нота в окрестности текущей позиции
                let distance = abs(fret.position - position.position)
                if distance < tolerance {
                    // Проверяем, не проигрывали ли мы уже эту ноту недавно
                    // Разрешаем проиграть снова, если прошло достаточно времени
                    if !playedNoteIds.contains(fret.id) {
                        notesToPlay.append((stringIndex, fret))
                    }
                }
            }
        }
        
        // Если нашли ноты, проигрываем их
        if !notesToPlay.isEmpty {
            print("Найдено нот для проигрывания: \(notesToPlay.count) на позиции \(position.position)")
            
            // Находим measureDuration для текущей позиции
            let measureDuration = getMeasureDurationAtPosition(position)
            
            // Вычисляем длительность звучания в секундах
            let noteDuration = calculateNoteDuration(measureDuration: measureDuration)
            
            // Проигрываем все найденные ноты одновременно (полифония)
            for (stringIndex, fret) in notesToPlay {
                let midiNote = MIDIService.fretToMIDINote(stringIndex: stringIndex, fretNumber: fret.fretNumber)
                print("Проигрывание ноты: string=\(stringIndex), fret=\(fret.fretNumber), MIDI=\(midiNote), position=\(fret.position)")
                GuitarSoundService.shared.playNote(midiNote: midiNote, duration: noteDuration, velocity: 100)
                
                // Отмечаем, что эта нота была проиграна
                playedNoteIds.insert(fret.id)
                
                // Удаляем из множества через некоторое время (после завершения звука)
                // Это позволит проиграть ноту снова, если зеленая линия вернется к ней
                DispatchQueue.main.asyncAfter(deadline: .now() + noteDuration + 0.1) { [weak self] in
                    self?.playedNoteIds.remove(fret.id)
                }
            }
        }
        
        // Обновляем последнюю позицию только после обработки всех нот
        lastPlayedPosition = (position.tabLineIndex, position.position)
    }
    
    /// Получает measureDuration для указанной позиции
    private func getMeasureDurationAtPosition(_ position: PlaybackPosition) -> MeasureDuration {
        guard position.tabLineIndex >= 0 && position.tabLineIndex < tabLines.count else {
            return MeasureDuration.fromTimeSignatureBottom(metadata.sizeBottom)
        }
        
        let tabLine = tabLines[position.tabLineIndex]
        
        // Ищем ближайший measureBar к текущей позиции
        var closestBar: MeasureBar?
        var minDistance: Double = Double.infinity
        
        for string in tabLine.strings {
            for bar in string.measureBars {
                let distance = abs(bar.position - position.position)
                if distance < minDistance {
                    minDistance = distance
                    closestBar = bar
                }
            }
        }
        
        // Если нашли measureBar с measureDuration, используем его
        if let bar = closestBar, let duration = bar.measureDuration {
            return duration
        }
        
        // Иначе используем длительность по умолчанию
        return MeasureDuration.fromTimeSignatureBottom(metadata.sizeBottom)
    }
    
    /// Вычисляет длительность звучания ноты в секундах на основе measureDuration
    private func calculateNoteDuration(measureDuration: MeasureDuration) -> TimeInterval {
        // BPM = beats per minute
        // 1 доля = 60 / BPM секунд
        let beatDuration = 60.0 / Double(playbackState.tempo)
        
        // measureDuration указывает, какая доля такта используется
        // Например, 1/4 означает четверть такта
        // Для размера 4/4: 1 такт = 4 четверти
        // Для размера 3/8: 1 такт = 3 восьмых
        
        // Вычисляем длительность в долях такта
        let durationInBeats: Double
        switch measureDuration {
        case .whole:
            durationInBeats = Double(playbackState.timeSignatureTop) // Целая нота = весь такт
        case .half:
            durationInBeats = Double(playbackState.timeSignatureTop) / 2.0
        case .quarter:
            durationInBeats = Double(playbackState.timeSignatureTop) / 4.0
        case .eighth:
            durationInBeats = Double(playbackState.timeSignatureTop) / 8.0
        case .sixteenth:
            durationInBeats = Double(playbackState.timeSignatureTop) / 16.0
        case .thirtySecond:
            durationInBeats = Double(playbackState.timeSignatureTop) / 32.0
        case .sixtyFourth:
            durationInBeats = Double(playbackState.timeSignatureTop) / 64.0
        }
        
        // Длительность в секундах
        return beatDuration * durationInBeats
    }
    
    private func currentRepeatBounds() -> (startTab: Int, startPos: Double, endTab: Int, endPos: Double)? {
        guard isRepeatEnabled,
              let startIdx = tabLines.firstIndex(where: { $0.id == selectedRepeat.startTab }),
              let endIdx = tabLines.firstIndex(where: { $0.id == selectedRepeat.endTab }) else {
            return nil
        }
        return (startIdx, selectedRepeat.startPosition, endIdx, selectedRepeat.endPosition)
    }
    
    func togglePlayback() {
        if playbackState.isPlaying {
            playbackState.pausePlayback()
            GuitarSoundService.shared.stopAllNotes()
            lastPlayedPosition = nil // Сбрасываем последнюю позицию при паузе
            playedNoteIds.removeAll() // Сбрасываем множество проигранных нот
        } else {
            // Сбрасываем все перед стартом
            lastPlayedPosition = nil
            playedNoteIds.removeAll()
            
            // Определяем начальную позицию для воспроизведения
            var startTabIndex = 0
            var startPosition: Double = 0.0
            var endTabIndex = tabLines.count - 1
            var endPosition: Double = 1.0
            
            if isRepeatEnabled {
                // Если включен repeat — стартуем с выбранного стартового repeat
                if let sIdx = tabLines.firstIndex(where: { $0.id == selectedRepeat.startTab }) {
                    startTabIndex = sIdx
                    startPosition = selectedRepeat.startPosition
                }
                if let eIdx = tabLines.firstIndex(where: { $0.id == selectedRepeat.endTab }) {
                    endTabIndex = eIdx
                    endPosition = selectedRepeat.endPosition
                }
            } else if selectedFret.isSelected {
                // Если есть выделенная нота, начинаем воспроизведение с её позиции
                for (lineIndex, tabLine) in tabLines.enumerated() {
                    for string in tabLine.strings {
                        if string.frets.contains(where: { $0.id == selectedFret.id }) {
                            startTabIndex = lineIndex
                            startPosition = selectedFret.position
                            break
                        }
                    }
                }
                // Конец — последняя нота
                let lastNote = findLastNotePosition()
                endTabIndex = lastNote?.tabLineIndex ?? (tabLines.count - 1)
                endPosition = lastNote?.position ?? 1.0
            } else {
                // Если нет выделенной ноты, начинаем с начала первого таба
                if !tabLines.isEmpty {
                    var firstNotePosition: Double? = nil
                    for string in tabLines[0].strings {
                        for fret in string.frets {
                            if firstNotePosition == nil || fret.position < firstNotePosition! {
                                firstNotePosition = fret.position
                            }
                        }
                    }
                    startPosition = firstNotePosition ?? 0.0
                }
                // Конец — последняя нота
                let lastNote = findLastNotePosition()
                endTabIndex = lastNote?.tabLineIndex ?? (tabLines.count - 1)
                endPosition = lastNote?.position ?? 1.0
            }
            
            // ВСЕГДА сбрасываем позицию воспроизведения на начальную
            playbackState.currentPosition.tabLineIndex = startTabIndex
            playbackState.currentPosition.position = startPosition
            playbackState.objectWillChange.send()
            
            print("Старт воспроизведения: tabIndex=\(startTabIndex), position=\(startPosition)")
            
            // Сразу проигрываем ноты на начальной позиции
            let initialPosition = PlaybackPosition(tabLineIndex: startTabIndex, position: startPosition)
            playNotesAtPosition(initialPosition)
            
            func startLoop() {
                // Свежие границы для повтора при старте цикла
                let loopBounds = currentRepeatBounds()
                let loopEndTab = loopBounds?.endTab ?? endTabIndex
                let loopEndPos = loopBounds?.endPos ?? endPosition
                let loopStartTab = loopBounds?.startTab ?? startTabIndex
                let loopStartPos = loopBounds?.startPos ?? startPosition
                
                playbackState.startPlayback(
                    totalTabLines: tabLines.count,
                    lastNoteTabIndex: loopEndTab,
                    lastNotePosition: loopEndPos,
                    onPositionUpdate: { [weak self] position in
                        guard let self else { return }
                        
                        // Динамическая проверка актуальных границ повтора
                        if let bounds = self.currentRepeatBounds() {
                            if position.tabLineIndex > bounds.endTab ||
                                (position.tabLineIndex == bounds.endTab && position.position >= bounds.endPos) {
                                // Перескок на старт
                                self.playbackState.currentPosition.tabLineIndex = bounds.startTab
                                self.playbackState.currentPosition.position = bounds.startPos
                                self.playbackState.objectWillChange.send()
                                let loopPos = PlaybackPosition(tabLineIndex: bounds.startTab, position: bounds.startPos)
                                self.playNotesAtPosition(loopPos)
                                return
                            }
                        }
                        
                        self.playNotesAtPosition(position)
                    },
                    onComplete: { [weak self] in
                        guard let self else { return }
                        if self.isRepeatEnabled, let bounds = self.currentRepeatBounds() {
                            // Возвращаемся к актуальному старту repeat и продолжаем
                            self.playbackState.currentPosition.tabLineIndex = bounds.startTab
                            self.playbackState.currentPosition.position = bounds.startPos
                            self.playbackState.objectWillChange.send()
                            let loopPos = PlaybackPosition(tabLineIndex: bounds.startTab, position: bounds.startPos)
                            self.playNotesAtPosition(loopPos)
                            startLoop()
                        } else {
                            self.playbackState.isPlaying = false
                            GuitarSoundService.shared.stopAllNotes()
                        }
                    }
                )
            }
            
            startLoop()
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
                // Создаем ViewModel для выбора трека
                let trackSelectorVM = TrackSelectorViewModel(
                    availableTracks: midiInfo.tracks,
                    selectedTrackIndex: 0
                )
                trackSelectorVM.onTrackSelected = { [weak self] index in
                    self?.selectedTrackIndex = index
                }
                trackSelectorVM.onConfirm = { [weak self] in
                    self?.confirmTrackSelection()
                }
                trackSelectorViewModel = trackSelectorVM
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
            
            // Сбрасываем repeat на первый таб после загрузки (ID меняются)
            if let firstId = importedTabLines.first?.id {
                let newRepeat = TabRepeat(startTab: firstId, startPosition: 0.0, endTab: firstId, endPosition: 1.0)
                selectedRepeat = newRepeat
                toolbarViewModel.selectedRepeat = newRepeat
            }
            
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
        trackSelectorViewModel = nil
        pendingMIDIInfo = nil
    }
}

