//
//  RepeatViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 08.12.2025.
//

import Combine
import SwiftUI

@MainActor
class RepeatViewModel: ObservableObject {
    var repeatState: TabRepeat?
    var parentViewModel: ContentViewModel?
    var tabLineId: UUID
    var tabLineIndex: Int
    @Published var isRepeatEnabled: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(repeatState: TabRepeat?, parentViewModel: ContentViewModel?, tabLineId: UUID, tabLineIndex: Int, isRepeatEnabled: Bool = false) {
        self.repeatState = repeatState
        self.parentViewModel = parentViewModel
        self.tabLineId = tabLineId
        self.tabLineIndex = tabLineIndex
        self.isRepeatEnabled = isRepeatEnabled
        
        // Подписываемся на изменения isRepeatEnabled из parentViewModel
        if let parentVM = parentViewModel {
            parentVM.$isRepeatEnabled
                .sink { [weak self] enabled in
                    self?.isRepeatEnabled = enabled
                }
                .store(in: &cancellables)
            
            parentVM.$selectedRepeat
                .sink { [weak self] repeatState in
                    self?.repeatState = repeatState
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
            
            parentVM.$selectedRepeatType
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
    }
    
    func shouldShowLine() -> Bool {
        return isRepeatEnabled && repeatState != nil
    }
    
    func calculateStartPosition(_ geometry: GeometryProxy) -> CGFloat {
        if let repeatState {
            repeatState.startPosition * geometry.size.width
        } else {
            0.0
        }
    }
    
    func calculateEndPosition(_ geometry: GeometryProxy) -> CGFloat {
        if let repeatState {
            repeatState.endPosition * geometry.size.width
        } else {
            1.0
        }
    }
    
    /// Вычисляет диапазон подсветки для конкретного таба (startX, endX в пикселях)
    func highlightRange(for tabId: UUID, geometry: GeometryProxy) -> (CGFloat, CGFloat)? {
        guard let parentVM = parentViewModel,
              let repeatState = repeatState else { return nil }
        
        guard let startIdx = parentVM.tabLines.firstIndex(where: { $0.id == repeatState.startTab }),
              let endIdx = parentVM.tabLines.firstIndex(where: { $0.id == repeatState.endTab }),
              let currentIdx = parentVM.tabLines.firstIndex(where: { $0.id == tabId }) else {
            return nil
        }
        
        let startPos = CGFloat(repeatState.startPosition) * geometry.size.width
        let endPos = CGFloat(repeatState.endPosition) * geometry.size.width
        
        if startIdx == endIdx && currentIdx == startIdx {
            // Старт и финиш на одном табе
            return (min(startPos, endPos), max(startPos, endPos))
        }
        
        if currentIdx == startIdx {
            // Стартовый таб: от стартовой позиции до конца таба
            return (startPos, geometry.size.width)
        }
        
        if currentIdx == endIdx {
            // Финишный таб: от начала таба до конечной позиции
            return (0, endPos)
        }
        
        // Таб между стартом и финишем — полностью
        if (startIdx < endIdx && currentIdx > startIdx && currentIdx < endIdx) ||
            (endIdx < startIdx && currentIdx < startIdx && currentIdx > endIdx) {
            return (0, geometry.size.width)
        }
        
        return nil
    }
    
    func isStartSelected() -> Bool {
        guard let parentVM = parentViewModel,
              let repeatState = repeatState,
              let selectedType = parentVM.selectedRepeatType else {
            return false
        }
        return selectedType == .start && repeatState.startTab == tabLineId
    }
    
    func isEndSelected() -> Bool {
        guard let parentVM = parentViewModel,
              let repeatState = repeatState,
              let selectedType = parentVM.selectedRepeatType else {
            return false
        }
        return selectedType == .end && repeatState.endTab == tabLineId
    }
    
    func handleStartTap(at location: CGPoint, in geometry: GeometryProxy) {
        guard let parentVM = parentViewModel,
              let repeatState = repeatState,
              repeatState.startTab == tabLineId else { return }
        let startPosition = calculateStartPosition(geometry)
        let tapRadius: CGFloat = 30 // Увеличиваем радиус для более удобного тапа
        
        // Проверяем, попали ли мы на стартовую линию или стрелку
        let distanceToLine = abs(location.x - startPosition)
        let distanceToArrow = abs(location.x - (startPosition - 8.5))
        
        // Также проверяем вертикальную позицию (должна быть в пределах таба)
        let verticalCenter = geometry.size.height / 2
        let verticalDistance = abs(location.y - verticalCenter)
        let verticalRadius: CGFloat = geometry.size.height / 2 + 10
        
        if (distanceToLine < tapRadius || distanceToArrow < tapRadius) && verticalDistance < verticalRadius {
            if parentVM.selectedRepeatType == .start && repeatState.startTab == tabLineId {
                // Если уже выделен - снимаем выделение
                parentVM.deselectRepeat()
            } else {
                // Выделяем стартовый Repeat
                parentVM.selectRepeat(.start)
            }
        }
    }
    
    func handleEndTap(at location: CGPoint, in geometry: GeometryProxy) {
        guard let parentVM = parentViewModel,
              let repeatState = repeatState,
              repeatState.endTab == tabLineId else { return }
        let endPosition = calculateEndPosition(geometry)
        let tapRadius: CGFloat = 30 // Увеличиваем радиус для более удобного тапа
        
        // Проверяем, попали ли мы на финишную линию или стрелку
        let distanceToLine = abs(location.x - endPosition)
        let distanceToArrow = abs(location.x - (endPosition + 8.5))
        
        // Также проверяем вертикальную позицию (должна быть в пределах таба)
        let verticalCenter = geometry.size.height / 2
        let verticalDistance = abs(location.y - verticalCenter)
        let verticalRadius: CGFloat = geometry.size.height / 2 + 10
        
        if (distanceToLine < tapRadius || distanceToArrow < tapRadius) && verticalDistance < verticalRadius {
            if parentVM.selectedRepeatType == .end && repeatState.endTab == tabLineId {
                // Если уже выделен - снимаем выделение
                parentVM.deselectRepeat()
            } else {
                // Выделяем финишный Repeat
                parentVM.selectRepeat(.end)
            }
        }
    }
    
    func currentStartIndex() -> Int {
        if let parentVM = parentViewModel,
           let repeatState = repeatState,
           let idx = parentVM.tabLines.firstIndex(where: { $0.id == repeatState.startTab }) {
            return idx
        }
        return tabLineIndex
    }
    
    func currentEndIndex() -> Int {
        if let parentVM = parentViewModel,
           let repeatState = repeatState,
           let idx = parentVM.tabLines.firstIndex(where: { $0.id == repeatState.endTab }) {
            return idx
        }
        return tabLineIndex
    }
    
    func handleStartDragDuring(translation: CGSize, in geometry: GeometryProxy) -> Bool {
        guard let parentVM = parentViewModel,
              let repeatState = repeatState else { return false }
        
        // Определяем целевой таб по вертикальному смещению
        let tabStep: CGFloat = 200 // уменьшили шаг для чувствительности
        let deltaTabs = Int((translation.height / tabStep).rounded())
        let baseIndex = currentStartIndex()
        let targetIndex = min(max(baseIndex + deltaTabs, 0), parentVM.tabLines.count - 1)
        let targetTabId = parentVM.tabLines[targetIndex].id
        
        // Если таб изменился, сразу перепрыгиваем на него
        if targetTabId != repeatState.startTab {
            // Учитываем отступы таба (как в TabLineViewModel)
            let endOffset: CGFloat = 30
            let startThinBarXPosition: CGFloat = 30
            let timeSignatureWidth: CGFloat = 96
            let timeSignatureOffset = timeSignatureWidth + 5
            let startOffset = startThinBarXPosition + timeSignatureOffset
            let availableWidth = geometry.size.width - startOffset - endOffset
            
            let currentPosition = calculateStartPosition(geometry)
            let newX = currentPosition + translation.width
            
            // Нормализуем позицию с учетом отступов
            let adjustedX = newX - startOffset
            let normalizedPosition = adjustedX / availableWidth
            let clampedPosition = max(0, min(1, normalizedPosition))
            
            // Привязка к делениям
            let divisions = 8
            let snappedPosition = NoteSnappingHelper.snapToDivision(clampedPosition, divisions: divisions)
            
            // Вычисляем финальную позицию с учетом отступов
            let finalPosition = (startOffset / geometry.size.width) + snappedPosition * (availableWidth / geometry.size.width)
            
            var updatedRepeat = repeatState
            updatedRepeat.startTab = targetTabId
            updatedRepeat.startPosition = finalPosition
            parentVM.selectedRepeat = updatedRepeat
            return true // Перепрыгнули на другой таб
        }
        return false // Остались на том же табе
    }
    
    func handleStartDrag(translation: CGSize, in geometry: GeometryProxy) {
        guard let parentVM = parentViewModel,
              let repeatState = repeatState else { return }
        
        // Учитываем отступы таба (как в TabLineViewModel)
        let endOffset: CGFloat = 30
        let startThinBarXPosition: CGFloat = 30
        let timeSignatureWidth: CGFloat = 96
        let timeSignatureOffset = timeSignatureWidth + 5
        let startOffset = startThinBarXPosition + timeSignatureOffset
        let availableWidth = geometry.size.width - startOffset - endOffset
        
        let currentPosition = calculateStartPosition(geometry)
        let newX = currentPosition + translation.width
        
        // Определяем целевой таб по вертикальному смещению
        let tabStep: CGFloat = 220 // приблизительная высота одного таба с заголовком
        let deltaTabs = Int((translation.height / tabStep).rounded())
        let targetIndex = min(max(tabLineIndex + deltaTabs, 0), parentVM.tabLines.count - 1)
        let targetTabId = parentVM.tabLines[targetIndex].id
        
        // Нормализуем позицию с учетом отступов
        let adjustedX = newX - startOffset
        let normalizedPosition = adjustedX / availableWidth
        let clampedPosition = max(0, min(1, normalizedPosition))
        
        // Привязка к делениям
        let divisions = 8
        let snappedPosition = NoteSnappingHelper.snapToDivision(clampedPosition, divisions: divisions)
        
        // Вычисляем финальную позицию с учетом отступов
        let finalPosition = (startOffset / geometry.size.width) + snappedPosition * (availableWidth / geometry.size.width)
        
        var updatedRepeat = repeatState
        updatedRepeat.startTab = targetTabId
        updatedRepeat.startPosition = finalPosition
        parentVM.selectedRepeat = updatedRepeat
    }
    
    func handleEndDragDuring(translation: CGSize, in geometry: GeometryProxy) -> Bool {
        guard let parentVM = parentViewModel,
              let repeatState = repeatState else { return false }
        
        // Определяем целевой таб по вертикальному смещению
        let tabStep: CGFloat = 200 // уменьшили шаг для чувствительности
        let deltaTabs = Int((translation.height / tabStep).rounded())
        let baseIndex = currentEndIndex()
        let targetIndex = min(max(baseIndex + deltaTabs, 0), parentVM.tabLines.count - 1)
        let targetTabId = parentVM.tabLines[targetIndex].id
        
        // Если таб изменился, сразу перепрыгиваем на него
        if targetTabId != repeatState.endTab {
            // Учитываем отступы таба (как в TabLineViewModel)
            let endOffset: CGFloat = 30
            let startThinBarXPosition: CGFloat = 30
            let timeSignatureWidth: CGFloat = 96
            let timeSignatureOffset = timeSignatureWidth + 5
            let startOffset = startThinBarXPosition + timeSignatureOffset
            let availableWidth = geometry.size.width - startOffset - endOffset
            
            let currentPosition = calculateEndPosition(geometry)
            let newX = currentPosition + translation.width
            
            // Нормализуем позицию с учетом отступов
            let adjustedX = newX - startOffset
            let normalizedPosition = adjustedX / availableWidth
            let clampedPosition = max(0, min(1, normalizedPosition))
            
            // Привязка к делениям
            let divisions = 8
            let snappedPosition = NoteSnappingHelper.snapToDivision(clampedPosition, divisions: divisions)
            
            // Вычисляем финальную позицию с учетом отступов
            let finalPosition = (startOffset / geometry.size.width) + snappedPosition * (availableWidth / geometry.size.width)
            
            var updatedRepeat = repeatState
            updatedRepeat.endTab = targetTabId
            updatedRepeat.endPosition = finalPosition
            parentVM.selectedRepeat = updatedRepeat
            return true // Перепрыгнули на другой таб
        }
        return false // Остались на том же табе
    }
    
    func handleEndDrag(translation: CGSize, in geometry: GeometryProxy) {
        guard let parentVM = parentViewModel,
              let repeatState = repeatState else { return }
        
        // Учитываем отступы таба (как в TabLineViewModel)
        let endOffset: CGFloat = 30
        let startThinBarXPosition: CGFloat = 30
        let timeSignatureWidth: CGFloat = 96
        let timeSignatureOffset = timeSignatureWidth + 5
        let startOffset = startThinBarXPosition + timeSignatureOffset
        let availableWidth = geometry.size.width - startOffset - endOffset
        
        let currentPosition = calculateEndPosition(geometry)
        let newX = currentPosition + translation.width
        
        // Определяем целевой таб по вертикальному смещению
        let tabStep: CGFloat = 220 // приблизительная высота одного таба с заголовком
        let deltaTabs = Int((translation.height / tabStep).rounded())
        let targetIndex = min(max(tabLineIndex + deltaTabs, 0), parentVM.tabLines.count - 1)
        let targetTabId = parentVM.tabLines[targetIndex].id
        
        // Нормализуем позицию с учетом отступов
        let adjustedX = newX - startOffset
        let normalizedPosition = adjustedX / availableWidth
        let clampedPosition = max(0, min(1, normalizedPosition))
        
        // Привязка к делениям
        let divisions = 8
        let snappedPosition = NoteSnappingHelper.snapToDivision(clampedPosition, divisions: divisions)
        
        // Вычисляем финальную позицию с учетом отступов
        let finalPosition = (startOffset / geometry.size.width) + snappedPosition * (availableWidth / geometry.size.width)
        
        var updatedRepeat = repeatState
        updatedRepeat.endTab = targetTabId
        updatedRepeat.endPosition = finalPosition
        parentVM.selectedRepeat = updatedRepeat
    }
}
