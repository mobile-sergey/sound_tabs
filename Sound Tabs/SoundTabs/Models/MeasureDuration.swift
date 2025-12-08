//
//  MeasureDuration.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// Длина такта: 1, 1/2, 1/4, 1/8, 1/16, 1/32 или 1/64.
enum MeasureDuration: Int, Codable, CaseIterable {
    case whole = 1        // 1
    case half = 2         // 1/2
    case quarter = 4      // 1/4
    case eighth = 8       // 1/8
    case sixteenth = 16   // 1/16
    case thirtySecond = 32 // 1/32
    case sixtyFourth = 64  // 1/64
    
    /// Строковое представление для отображения
    var displayString: String {
        switch self {
        case .whole:
            return "1"
        case .half:
            return "1/2"
        case .quarter:
            return "1/4"
        case .eighth:
            return "1/8"
        case .sixteenth:
            return "1/16"
        case .thirtySecond:
            return "1/32"
        case .sixtyFourth:
            return "1/64"
        }
    }
    
    /// Создает MeasureDuration на основе нижней цифры размера такта
    static func fromTimeSignatureBottom(_ bottom: Int) -> MeasureDuration {
        switch bottom {
        case 1:
            return .whole
        case 2:
            return .half
        case 4:
            return .quarter
        case 8:
            return .eighth
        case 16:
            return .sixteenth
        case 32:
            return .thirtySecond
        case 64:
            return .sixtyFourth
        default:
            // По умолчанию используем четверть
            return .quarter
        }
    }
}

