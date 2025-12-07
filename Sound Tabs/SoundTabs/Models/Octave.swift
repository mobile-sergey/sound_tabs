//
//  Octave.swift
//  Sound Tabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

// Октава для гитары
enum Octave: Int, CaseIterable, Codable {
    case small = 0  // Малая октава
    case first = 1  // Первая октава
    case second = 2 // Вторая октава
    case third = 3  // Третья октава
    
    var displayName: String {
        switch self {
        case .small: return "Малая"
        case .first: return "Первая"
        case .second: return "Вторая"
        case .third: return "Третья"
        }
    }
}

