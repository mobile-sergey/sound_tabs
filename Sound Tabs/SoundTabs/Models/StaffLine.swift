//
//  StaffLine.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

// Строка нотного стана
struct StaffLine: Identifiable, Codable {
    let id: UUID
    var notes: [Note]
    var measureBars: [MeasureBar] // Вертикальные линии тактов
    
    init(id: UUID = UUID(), notes: [Note] = [], measureBars: [MeasureBar] = []) {
        self.id = id
        self.notes = notes
        self.measureBars = measureBars
    }
}

