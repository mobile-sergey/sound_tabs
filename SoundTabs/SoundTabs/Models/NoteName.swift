//
//  NoteName.swift
//  Sound Tabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// Перечисление музыкальных нот: C, D, E, F, G, A, B.
/// Используется для вычисления названий нот на основе струны и лада.
enum NoteName: String, CaseIterable, Codable {
    case C = "C"
    case D = "D"
    case E = "E"
    case F = "F"
    case G = "G"
    case A = "A"
    case B = "B"
}

