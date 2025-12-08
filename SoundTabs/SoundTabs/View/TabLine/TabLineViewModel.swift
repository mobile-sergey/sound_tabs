//
//  TabLineViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel для одной строки табулатуры, управляющая обработкой тапов, созданием нот и созданием дочерних ViewModels.
/// Обрабатывает взаимодействия пользователя с табом (тапы, двойные тапы) и создает ViewModels для струн и размера такта.
@MainActor
class TabLineViewModel: ObservableObject {
    @Published var tabLine: TabLine
    var parentViewModel: ContentViewModel?
    var tabLineIndex: Int = 0
    
    // Сохраняем последнюю позицию тапа для двойного тапа
    var lastTapLocation: CGPoint? = nil
    var lastTapGeometry: GeometryProxy? = nil
    
    let divisions: Int = 8
    
    var metadata: TabMetadata?
    var isFirstTab: Bool = false
    var timeSignatureWidth: CGFloat = 96 // Ширина размера такта: точки (8) + ширина 2-значного числа (80) + отступ (8)
    var playbackState: PlaybackState?
    private var cancellables = Set<AnyCancellable>()
    
    init(
        tabLine: TabLine,
        tabLineIndex: Int = 0,
        parentViewModel: ContentViewModel? = nil,
        metadata: TabMetadata? = nil,
        isFirstTab: Bool = false,
        playbackState: PlaybackState? = nil
    ) {
        self.tabLine = tabLine
        self.tabLineIndex = tabLineIndex
        self.parentViewModel = parentViewModel
        self.metadata = metadata
        self.isFirstTab = isFirstTab
        self.playbackState = playbackState
        
        // Подписываемся на изменения playbackState для обновления UI
        if let playback = playbackState {
            playback.$currentPosition
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
        
        // Подписываемся на изменения selectedFret для обновления зелёной линии
        if let parentVM = parentViewModel {
            parentVM.$selectedFret
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
    }
    
    func handleTap(at location: CGPoint, in geometry: GeometryProxy) {
        // Сохраняем позицию тапа для возможного двойного тапа
        lastTapLocation = location
        lastTapGeometry = geometry
        
        // Учитываем отступ от начала (названия струн)
        let endOffset: CGFloat = 30 // Расстояние до боковой линии
        // Размер такта теперь внутри таба, сразу после первых вертикальных линий
        let startThinBarXPosition: CGFloat = 30 // nameWidth (25) + thickBarWidth (3) + barSpacing (2)
        let timeSignatureOffset = timeSignatureWidth + 5 // Отступ после размера такта
        let startOffset = startThinBarXPosition + timeSignatureOffset
        let availableWidth = geometry.size.width - startOffset - endOffset
        
        // Проверяем, что клик не на названии струны или размере такта
        guard location.x >= startOffset else {
            // Клик на названии струны или размере такта - снимаем выделение
            parentViewModel?.deselectAllFrets()
            return
        }
        
        // Определяем, на какую струну кликнули
        let stringHeight = geometry.size.height / 6
        let stringIndex = Int(location.y / stringHeight)
        
        guard stringIndex >= 0 && stringIndex < tabLine.strings.count else {
            // Клик за пределами струн - снимаем выделение
            parentViewModel?.deselectAllFrets()
            return
        }
        
        // Определяем позицию по X (с учетом всех отступов)
        let adjustedX = location.x - startOffset
        let xPosition = adjustedX / availableWidth
        let clampedPosition = max(0, min(1, xPosition))
        
        // Привязка к перекрестьям (8 позиций = 7 интервалов)
        let snappedPosition = NoteSnappingHelper.snapToDivision(clampedPosition, divisions: divisions)
        
        // Проверяем, не попали ли мы на существующий лад
        let tappedFret = findFretAt(location: location, in: geometry, stringIndex: stringIndex)
        
        if let fret = tappedFret {
            // Нажали на лад
            // Проверяем, выделена ли эта нота через parentViewModel
            if let parentVM = parentViewModel, parentVM.selectedFret.id == fret.id && parentVM.selectedFret.isSelected {
                // Если нота уже выделена - снимаем выделение
                parentVM.deselectAllFrets()
            } else {
                // Если нота не выделена - выделяем её
                parentViewModel?.selectFret(fret)
            }
        } else {
            // Нажали на пустое место (перекрестье) - создаём новый лад (по умолчанию 0)
            // Нормализуем позицию с учетом всех отступов для сохранения
            let finalPosition = (startOffset / geometry.size.width) + snappedPosition * (availableWidth / geometry.size.width)
            parentViewModel?.addFret(to: tabLine.id, stringIndex: stringIndex, at: finalPosition, fretNumber: 0)
            // Синхронизируем изменения
            if let updatedLine = parentViewModel?.tabLines[tabLineIndex] {
                tabLine = updatedLine
            }
        }
    }
    
    func handleDoubleTap(at location: CGPoint, in geometry: GeometryProxy) {
        // Учитываем отступ от начала (названия струн)
        let endOffset: CGFloat = 30
        // Размер такта теперь внутри таба, сразу после первых вертикальных линий
        let startThinBarXPosition: CGFloat = 30 // nameWidth + thickBarWidth + barSpacing
        let timeSignatureOffset = timeSignatureWidth + 5
        let startOffset = startThinBarXPosition + timeSignatureOffset
        let availableWidth = geometry.size.width - startOffset - endOffset
        
        // Проверяем, что клик не на названии струны или размере такта
        guard location.x >= startOffset else { return }
        
        // Определяем, на какую струну кликнули
        let stringHeight = geometry.size.height / 6
        let stringIndex = Int(location.y / stringHeight)
        
        guard stringIndex >= 0 && stringIndex < tabLine.strings.count else { return }
        
        // Проверяем, не попали ли мы на существующий лад
        let tappedFret = findFretAt(location: location, in: geometry, stringIndex: stringIndex)
        
        // Создаем новую ноту только если не попали на существующую
        guard tappedFret == nil else { return }
        
        // Определяем позицию по X (с учетом всех отступов)
        let adjustedX = location.x - startOffset
        let xPosition = adjustedX / availableWidth
        let clampedPosition = max(0, min(1, xPosition))
        
        // Привязка к перекрестьям (8 позиций = 7 интервалов)
        let snappedPosition = NoteSnappingHelper.snapToDivision(clampedPosition, divisions: divisions)
        
        // Нормализуем позицию с учетом всех отступов для сохранения
        let finalPosition = (startOffset / geometry.size.width) + snappedPosition * (availableWidth / geometry.size.width)
        parentViewModel?.addFret(to: tabLine.id, stringIndex: stringIndex, at: finalPosition, fretNumber: 0)
        
        // Синхронизируем изменения
        if let updatedLine = parentViewModel?.tabLines[tabLineIndex] {
            tabLine = updatedLine
        }
    }
    
    func findFretAt(location: CGPoint, in geometry: GeometryProxy, stringIndex: Int) -> TabFret? {
        let tapRadius: CGFloat = 20
        
        guard stringIndex >= 0 && stringIndex < tabLine.strings.count else { return nil }
        
        for fret in tabLine.strings[stringIndex].frets {
            // fret.position уже сохранена как позиция относительно всего таба (0.0 - 1.0)
            // Вычисляем реальную позицию ноты на экране
            let fretX = fret.position * geometry.size.width
            let stringCenterY = (CGFloat(stringIndex) + 0.5) * (geometry.size.height / 6)
            
            let distance = abs(location.x - fretX)
            if distance < tapRadius && abs(location.y - stringCenterY) < 15 {
                return fret
            }
        }
        return nil
    }
    
    func getMeasureBars() -> [MeasureBar] {
        // Берем тактовые линии из первой струны, так как они одинаковые для всех
        guard !tabLine.strings.isEmpty else { return [] }
        
        // Если тактов нет, планируем их создание асинхронно, но возвращаем пустой массив
        // чтобы не изменять @Published свойство во время обновления view
        if tabLine.strings[0].measureBars.isEmpty {
            // Планируем создание тактов асинхронно
            DispatchQueue.main.async { [weak self] in
                self?.createDefaultMeasureBarsSync()
            }
            // Возвращаем пустой массив, такты появятся после следующего обновления view
            return []
        }
        
        return tabLine.strings[0].measureBars
    }
    
    private func createDefaultMeasureBarsSync() {
        // Создаем такты для всех 8 позиций деления
        let divisions = 8
        let endOffset: CGFloat = 30
        let startThinBarXPosition: CGFloat = 30
        let timeSignatureOffset = timeSignatureWidth + 5
        let startOffset = startThinBarXPosition + timeSignatureOffset
        
        // Используем примерную ширину экрана для вычисления позиций
        // Позиции будут нормализованы относительно ширины таба (0.0 - 1.0)
        let screenWidth: CGFloat = 375
        let availableWidth = screenWidth - startOffset - endOffset
        
        // Создаем новый TabLine с обновленными measureBars, чтобы избежать изменения @Published свойства во время обновления view
        var updatedStrings = tabLine.strings
        
        for i in 0..<divisions {
            // Вычисляем нормализованную позицию (0.0 - 1.0)
            // Для 8 делений: 0, 1/7, 2/7, ..., 6/7, 1.0
            let snappedPosition = Double(i) / Double(max(1, divisions - 1))
            // Нормализуем позицию с учетом отступов
            let finalPosition = (startOffset / screenWidth) + snappedPosition * (availableWidth / screenWidth)
            
            // Создаем такт на каждой позиции деления
            for stringIndex in updatedStrings.indices {
                let measureBar = MeasureBar(
                    position: finalPosition,
                    isDouble: false,
                    measureDuration: nil, // Будет использоваться значение по умолчанию
                    isSelected: false
                )
                updatedStrings[stringIndex].measureBars.append(measureBar)
            }
        }
        
        // Создаем новый TabLine с обновленными данными
        var updatedTabLine = tabLine
        updatedTabLine.strings = updatedStrings
        
        // Обновляем данные напрямую, так как мы уже в async блоке
        tabLine = updatedTabLine
        if let lineIndex = parentViewModel?.tabLines.firstIndex(where: { $0.id == updatedTabLine.id }) {
            parentViewModel?.tabLines[lineIndex] = updatedTabLine
        }
    }
    
    private func createDefaultMeasureBars() {
        createDefaultMeasureBarsSync()
    }
    
    func createMeasureBarsViewModel(measureBars: [MeasureBar], size: CGSize) -> MeasureBarsViewModel {
        let defaultDuration = metadata.map { MeasureDuration.fromTimeSignatureBottom($0.sizeBottom) }
        let vm = MeasureBarsViewModel(
            measureBars: measureBars,
            parentViewModel: parentViewModel,
            tabLineId: tabLine.id,
            defaultDuration: defaultDuration
        )
        vm.size = size
        return vm
    }
    
    func createTabStringViewModel(for string: TabString, at index: Int, with size: CGSize) -> TabStringViewModel {
        // Получаем актуальную строку из tabLine
        let actualString = tabLine.strings[index]
        let vm = TabStringViewModel(
            string: actualString,
            stringIndex: index,
            parentViewModel: self
        )
        vm.tabSize = size
        return vm
    }
    
    func createSizeViewModel(tabHeight: CGFloat, onFocusChange: (() -> Void)?) -> SizeViewModel? {
        guard let metadata = metadata else { return nil }
        return SizeViewModel(
            sizeTop: metadata.sizeTop,
            sizeBottom: metadata.sizeBottom,
            nameWidth: 25,
            tabHeight: tabHeight,
            startThinBarXPosition: 30, // nameWidth (25) + thickBarWidth (3) + barSpacing (2) = 30
            onSizeChange: { [weak self] top, bottom in
                self?.parentViewModel?.updateTimeSignature(top: top, bottom: bottom)
            },
            onFocusChange: onFocusChange
        )
    }
    
    func createPlaybackLineViewModel() -> PlaybackLineViewModel {
        return PlaybackLineViewModel(
            playbackState: playbackState,
            parentViewModel: parentViewModel,
            tabLineIndex: tabLineIndex
        )
    }
    
}

