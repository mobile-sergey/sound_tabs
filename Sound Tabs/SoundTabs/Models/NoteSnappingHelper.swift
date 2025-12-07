//
//  NoteSnappingHelper.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// Вспомогательный класс для привязки позиций нот к делениям табулатуры.
/// Обеспечивает выравнивание нот по перекрестьям (позициям) на табе.
struct NoteSnappingHelper {
    // Привязка к делениям (для позиционирования ладов на табулатуре)
    // divisions - количество перекрестий (позиций)
    // Для 8 перекрестий нужно 7 интервалов (0, 1/7, 2/7, ..., 6/7, 1.0)
    static func snapToDivision(_ position: Double, divisions: Int = 16) -> Double {
        // Количество интервалов = divisions - 1
        let intervals = max(1, divisions - 1)
        let step = 1.0 / Double(intervals)
        let snapped = round(position / step) * step
        return max(0, min(1, snapped))
    }
}

