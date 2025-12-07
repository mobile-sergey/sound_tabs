//
//  PositionMarkersViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

/// ViewModel для вертикальных маркеров позиций (перекрестий) на табулатуре.
/// Вычисляет позиции вертикальных линий, обозначающих места для размещения нот (скрыты, но позиции используются).
class PositionMarkersViewModel: ObservableObject {
    var divisions: Int = 8
    var size: CGSize = .zero
    var timeSignatureWidth: CGFloat = 0 // Ширина для размера такта (только для первого таба)
    var spacingAfterTimeSignature: CGFloat = 0 // Промежуток после размера такта
    
    func markerXPosition(for index: Int) -> CGFloat {
        let endOffset: CGFloat = 30 // Расстояние до боковой линии
        // Размер такта теперь внутри таба, сразу после первых вертикальных линий
        // startThinBarXPosition = nameWidth + thickBarWidth + barSpacing = 25 + 3 + 2 = 30
        let startThinBarXPosition: CGFloat = 30
        let timeSignatureOffset = timeSignatureWidth + spacingAfterTimeSignature
        let startOffset = startThinBarXPosition + timeSignatureOffset
        let availableWidth = size.width - startOffset - endOffset
        // 8 перекрестий = 7 интервалов (индексы 0-7)
        let intervals = max(1, divisions - 1)
        let position = CGFloat(index) / CGFloat(intervals)
        return startOffset + availableWidth * position
    }
}

