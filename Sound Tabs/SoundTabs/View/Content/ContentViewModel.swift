//
//  ContentViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

@MainActor
class ContentViewModel: ObservableObject {
    @Published var staffLines: [StaffLine] = [StaffLine()]
    @Published var selectedNote: Note?
    @Published var repeatMark: RepeatMark?
    @Published var isRepeatMode = false
    @Published var selectedRepeatLine: RepeatLineType? // .start или .end
    
    func addStaffLine() {
        let newLine = StaffLine()
        staffLines.append(newLine)
    }
    
    func addNote(to lineId: UUID, at position: Double) {
        if let index = staffLines.firstIndex(where: { $0.id == lineId }) {
            // Привязка к делениям и проверка позиции после скрипичного ключа
            let snappedPosition = snapToDivision(position, divisions: 16)
            guard isPositionAfterClef(snappedPosition) else { return }
            
            // Создаём ноту с малой октавой C по умолчанию
            let newNote = Note(
                name: .C,
                octave: .small,
                duration: .quarter,
                position: snappedPosition
            )
            staffLines[index].notes.append(newNote)
            selectedNote = newNote
        }
    }
    
    func deleteNote(_ note: Note) {
        for index in staffLines.indices {
            if let noteIndex = staffLines[index].notes.firstIndex(where: { $0.id == note.id }) {
                staffLines[index].notes.remove(at: noteIndex)
                if selectedNote?.id == note.id {
                    selectedNote = nil
                }
                break
            }
        }
    }
    
    func updateNote(_ note: Note) {
        for index in staffLines.indices {
            if let noteIndex = staffLines[index].notes.firstIndex(where: { $0.id == note.id }) {
                staffLines[index].notes[noteIndex] = note
                selectedNote = note
                break
            }
        }
    }
    
    func selectNote(_ note: Note) {
        selectedNote = note
    }
    
    func toggleRepeatMode() {
        isRepeatMode.toggle()
        if isRepeatMode && !staffLines.isEmpty {
            // Создаём маркер повтора для первой строки
            repeatMark = RepeatMark(
                startPosition: 0.0,
                endPosition: 1.0,
                tablatureId: staffLines[0].id
            )
        } else {
            repeatMark = nil
        }
    }
    
    func updateRepeatMarkStart(_ position: Double, toLineId: UUID? = nil) {
        guard var mark = repeatMark else { return }
        let snappedPosition = snapToDivision(max(0, min(1, position)), divisions: 16)
        mark.startPosition = snappedPosition
        if let lineId = toLineId {
            mark.tablatureId = lineId
        }
        repeatMark = mark
        // Обновляем range выделения
        updateSelectionRange()
    }
    
    func updateRepeatMarkEnd(_ position: Double, toLineId: UUID? = nil) {
        guard var mark = repeatMark else { return }
        let snappedPosition = snapToDivision(max(0, min(1, position)), divisions: 16)
        mark.endPosition = snappedPosition
        if let lineId = toLineId {
            mark.tablatureId = lineId
        }
        repeatMark = mark
        // Обновляем range выделения
        updateSelectionRange()
    }
    
    private func updateSelectionRange() {
        guard let mark = repeatMark else { return }
        // Обновляем selectionRange на основе позиций зелёных линий
        // Находим стан с mark.tablatureId и обновляем range
        if staffLines.firstIndex(where: { $0.id == mark.tablatureId }) != nil {
            // Range выделения будет визуализирован через repeatMarksView
            // Здесь можно добавить дополнительную логику при необходимости
        }
    }
    
    func selectRepeatLine(_ lineType: RepeatLineType) {
        // Переключаем выделение: если уже выделена эта линия - снимаем выделение
        if selectedRepeatLine == lineType {
            selectedRepeatLine = nil
        } else {
            selectedRepeatLine = lineType
        }
    }
    
    func deselectRepeatLine() {
        selectedRepeatLine = nil
    }
    
    func loadMoreIfNeeded(at index: Int) {
        // Пагинация: если прокрутили к последним 3 строкам, добавляем новые
        if index >= staffLines.count - 3 {
            addStaffLine()
        }
    }
}

