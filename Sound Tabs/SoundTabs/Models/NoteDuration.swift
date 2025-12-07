//
//  NoteDuration.swift
//  Sound Tabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

// Длительность ноты
enum NoteDuration: String, CaseIterable, Codable {
    case whole = "целая"
    case half = "половинная"
    case quarter = "четвертная"
    case eighth = "восьмая"
    case sixteenth = "шестнадцатая"
    
    var value: Double {
        switch self {
        case .whole: return 1.0
        case .half: return 0.5
        case .quarter: return 0.25
        case .eighth: return 0.125
        case .sixteenth: return 0.0625
        }
    }
}

