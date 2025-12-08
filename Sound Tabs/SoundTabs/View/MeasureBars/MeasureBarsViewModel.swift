//
//  MeasureBarsViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

/// ViewModel для тактовых линий (вертикальных линий тактов) на табулатуре.
/// Вычисляет позиции и размеры тактовых линий (одинарных и двойных).
@MainActor
class MeasureBarsViewModel: ObservableObject {
    let measureBars: [MeasureBar]
    var size: CGSize = .zero
    var parentViewModel: ContentViewModel?
    var tabLineId: UUID?
    var defaultDuration: MeasureDuration?
    
    let nameWidth: CGFloat = 25
    
    init(measureBars: [MeasureBar], parentViewModel: ContentViewModel? = nil, tabLineId: UUID? = nil, defaultDuration: MeasureDuration? = nil) {
        self.measureBars = measureBars
        self.parentViewModel = parentViewModel
        self.tabLineId = tabLineId
        self.defaultDuration = defaultDuration
    }
    
    var availableWidth: CGFloat {
        size.width - nameWidth
    }
    
    func calculateBarXPosition(for bar: MeasureBar) -> CGFloat {
        let normalizedPosition = (bar.position - nameWidth / size.width) / (availableWidth / size.width)
        return nameWidth + availableWidth * normalizedPosition
    }
    
    func barWidth(for bar: MeasureBar) -> CGFloat {
        bar.isDouble ? 3.0 : 2.0
    }
    
    var barHeight: CGFloat {
        size.height
    }
    
    var barYPosition: CGFloat {
        barHeight / 2
    }
    
    func getDuration(for bar: MeasureBar) -> MeasureDuration {
        // Если у такта есть сохраненная длина, используем её
        if let duration = bar.measureDuration {
            return duration
        }
        // Иначе используем длину по умолчанию
        return defaultDuration ?? .quarter
    }
    
    func isBarSelected(_ bar: MeasureBar) -> Bool {
        return parentViewModel?.selectedMeasureBar?.id == bar.id
    }
    
    func handleBarTap(_ bar: MeasureBar) {
        guard let tabLineId = tabLineId else { return }
        if isBarSelected(bar) {
            // Если такт уже выделен - снимаем выделение
            parentViewModel?.deselectAllMeasureBars()
        } else {
            // Выделяем такт
            parentViewModel?.selectMeasureBar(bar, in: tabLineId)
        }
    }
}

