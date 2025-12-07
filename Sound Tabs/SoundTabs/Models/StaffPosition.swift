//
//  StaffPosition.swift
//  Sound Tabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

// Позиция ноты на нотном стане (линия или промежуток)
enum StaffPosition: Int, CaseIterable {
    case above5 = 0  // Выше 5-й линии
    case line5 = 1   // 5-я линия (верхняя)
    case space4 = 2  // Промежуток между 4-й и 5-й
    case line4 = 3   // 4-я линия
    case space3 = 4  // Промежуток между 3-й и 4-й
    case line3 = 5   // 3-я линия (средняя)
    case space2 = 6  // Промежуток между 2-й и 3-й
    case line2 = 7   // 2-я линия
    case space1 = 8  // Промежуток между 1-й и 2-й
    case line1 = 9   // 1-я линия (нижняя)
    case below1 = 10 // Ниже 1-й линии
    
    var yOffset: CGFloat {
        switch self {
        case .above5: return -40
        case .line5: return -30
        case .space4: return -20
        case .line4: return -10
        case .space3: return 0
        case .line3: return 10
        case .space2: return 20
        case .line2: return 30
        case .space1: return 40
        case .line1: return 50
        case .below1: return 60
        }
    }
}

