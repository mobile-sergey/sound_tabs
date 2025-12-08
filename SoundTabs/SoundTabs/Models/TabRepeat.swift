//
//  TabRepeat.swift
//  SoundTabs
//
//  Created by Sergey on 08.12.2025.
//

import Foundation

struct TabRepeat: Codable {
    var startTab: UUID // ID начального таба
    var startPosition: Double // Позиция начала в табе (0.0 - начало, 1.0 - конец)
    var endTab: UUID // ID финишного таба
    var endPosition: Double // Позиция финиша в табе (0.0 - начало, 1.0 - конец)
    
    init(startTab: UUID, startPosition: Double, endTab: UUID, endPosition: Double) {
        self.startTab = startTab
        self.startPosition = startPosition
        self.endTab = endTab
        self.endPosition = endPosition
    }
}
