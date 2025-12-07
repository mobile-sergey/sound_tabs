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

/// Табулатура - одна строка с 6 струнами гитары.
/// Содержит массив струн, текст над табом и идентификатор.
struct TabLine: Identifiable, Codable {
    let id: UUID
    var strings: [TabString] // 6 струн
    var textAbove: String // Текст над табом
    
    init(id: UUID = UUID(), strings: [TabString]? = nil, textAbove: String = "") {
        self.id = id
        self.textAbove = textAbove
        if let strings = strings {
            self.strings = strings
        } else {
            // Стандартные 6 струн гитары
            self.strings = [
                TabString(noteName: "e"), // Ми первой октавы
                TabString(noteName: "B"), // Си
                TabString(noteName: "G"), // Соль
                TabString(noteName: "D"), // Ре
                TabString(noteName: "A"), // Ля
                TabString(noteName: "E")  // Ми большой октавы
            ]
        }
    }
}

