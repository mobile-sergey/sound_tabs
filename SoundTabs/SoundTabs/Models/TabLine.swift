//
//  TabLine.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

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

