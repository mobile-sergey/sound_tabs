//
//  TabString.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// Струна гитары с нотами (ладами) и тактовыми линиями.
/// Каждая струна имеет название ноты (E, A, D, G, B, e) и массив ладов.
struct TabString: Identifiable, Codable {
    let id: UUID
    var noteName: String // Название ноты струны (E, A, D, G, B, e)
    var frets: [TabFret] // Лады на струне
    var measureBars: [MeasureBar] // Вертикальные линии тактов
    
    init(id: UUID = UUID(), noteName: String, frets: [TabFret] = [], measureBars: [MeasureBar] = []) {
        self.id = id
        self.noteName = noteName
        self.frets = frets
        self.measureBars = measureBars
    }
}

