//
//  TabEndBarsViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

/// ViewModel для вертикальных линий и точек в начале и конце табулатуры.
/// Вычисляет позиции и размеры жирных/тонких линий и точек между струнами.
@MainActor
class TabEndBarsViewModel: ObservableObject {
    var size: CGSize = .zero
    
    let nameWidth: CGFloat = 25 // Ширина для названий струн
    
    init(size: CGSize = .zero) {
        self.size = size
    }
    
    var thickBarWidth: CGFloat {
        3.0 // Жирная линия
    }
    
    var thinBarWidth: CGFloat {
        1.0 // Тонкая линия
    }
    
    var barSpacing: CGFloat {
        2.0 // Расстояние между жирной и тонкой линиями
    }
    
    var barHeight: CGFloat {
        // Высота линий должна быть от первой до последней струны
        // 6 струн, каждая высотой size.height / 6
        // Первая струна на позиции size.height / 6 / 2 = size.height / 12
        // Последняя струна на позиции size.height - size.height / 12
        // Высота = (size.height - size.height / 12) - (size.height / 12) = size.height - size.height / 6
        return size.height - size.height / 6
    }
    
    var barYPosition: CGFloat {
        // Центр линий - между первой и последней струной
        return size.height / 2
    }
    
    var startThickBarXPosition: CGFloat {
        nameWidth
    }
    
    var startThinBarXPosition: CGFloat {
        nameWidth + thickBarWidth + barSpacing
    }
    
    var endThinBarXPosition: CGFloat {
        size.width - thickBarWidth - barSpacing - thinBarWidth / 2
    }
    
    var endThickBarXPosition: CGFloat {
        size.width - thickBarWidth / 2
    }
    
    var endDotXPosition: CGFloat {
        endThinBarXPosition - 6
    }
    
    var startDotXPosition: CGFloat {
        startThinBarXPosition + 8 // После начальных полосок
    }
    
    var dotSize: CGFloat {
        4.0
    }
    
    var dotSpacing: CGFloat {
        size.height / 6 // Расстояние между струнами
    }
    
    func startDotYPosition(for index: Int) -> CGFloat {
        // Первая точка на половину расстояния между струнами ниже струны 2 (индекс 1)
        // Вторая точка на половину расстояния между струнами ниже струны 4 (индекс 3)
        let stringIndex = index == 0 ? 1 : 3 // Струна 2 (индекс 1) или струна 4 (индекс 3)
        let stringCenterY = (CGFloat(stringIndex) + 0.5) * dotSpacing // Центр струны
        let halfSpacing = dotSpacing / 2.0 // Половина расстояния между струнами
        return stringCenterY + halfSpacing // Центр струны + половина расстояния вниз
    }
    
    func endDotYPosition(for index: Int) -> CGFloat {
        // Первая точка на половину расстояния между струнами ниже струны 2 (индекс 1)
        // Вторая точка на половину расстояния между струнами ниже струны 4 (индекс 3)
        let stringIndex = index == 0 ? 1 : 3 // Струна 2 (индекс 1) или струна 4 (индекс 3)
        let stringCenterY = (CGFloat(stringIndex) + 0.5) * dotSpacing // Центр струны
        let halfSpacing = dotSpacing / 2.0 // Половина расстояния между струнами
        return stringCenterY + halfSpacing // Центр струны + половина расстояния вниз
    }
}

