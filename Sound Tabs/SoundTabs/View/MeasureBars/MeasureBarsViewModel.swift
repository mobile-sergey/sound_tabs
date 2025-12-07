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
    
    let nameWidth: CGFloat = 25
    
    init(measureBars: [MeasureBar]) {
        self.measureBars = measureBars
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
}

