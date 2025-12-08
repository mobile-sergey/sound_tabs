//
//  MIDIService.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation

/// Сервис для работы с MIDI файлами: импорт и экспорт табулатур.
class MIDIService {
    
    /// Импортирует конкретный трек из MIDI файла
    static func importMIDIFromTrack(midiInfo: MIDIFileInfo, trackIndex: Int) throws -> (tabLines: [TabLine], tempo: Int, timeSignatureTop: Int, timeSignatureBottom: Int) {
        guard trackIndex >= 0 && trackIndex < midiInfo.tracks.count else {
            throw NSError(domain: "MIDIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Неверный индекс трека"])
        }
        
        let track = midiInfo.tracks[trackIndex]
        
        // Группируем ноты по тактам
        let ticksPerMeasure = midiInfo.ticksPerQuarter * midiInfo.timeSignatureTop
        
        // Сортируем ноты по времени начала
        let sortedNotes = track.notes.sorted { $0.startTime < $1.startTime }
        
        // Группируем ноты по моментам времени (startTime)
        // Округляем время до некоторой точности, чтобы ноты, звучащие почти одновременно, считались одним моментом
        let timePrecision = ticksPerMeasure / 32 // Делим такт на 32 части для группировки
        
        var timeMoments: [Int: [MIDINoteEvent]] = [:] // roundedTime -> [notes]
        
        for note in sortedNotes {
            // Округляем время начала до ближайшего момента
            let roundedTime = (note.startTime / timePrecision) * timePrecision
            if timeMoments[roundedTime] == nil {
                timeMoments[roundedTime] = []
            }
            timeMoments[roundedTime]?.append(note)
        }
        
        // Сортируем моменты времени
        let sortedTimeMoments = timeMoments.keys.sorted()
        
        // Создаём табы
        var tabLines: [TabLine] = []
        
        // Разбиваем на табы (максимум 8 моментов времени на таб)
        let momentsPerTab = 8
        var currentTab = TabLine()
        var currentMomentIndex = 0
        
        for timeMoment in sortedTimeMoments {
            guard let notesAtMoment = timeMoments[timeMoment] else { continue }
            
            // Если нужно, создаём новый таб
            if currentMomentIndex > 0 && currentMomentIndex % momentsPerTab == 0 {
                tabLines.append(currentTab)
                currentTab = TabLine()
            }
            
            // Добавляем тактовую линию в начале таба (если это первый момент таба)
            if currentMomentIndex % momentsPerTab == 0 {
                // Добавляем начальную тактовую линию
                for stringIndex in 0..<currentTab.strings.count {
                    let measureBar = MeasureBar(position: 0.0, isDouble: false)
                    currentTab.strings[stringIndex].measureBars.append(measureBar)
                }
            }
            
            // Вычисляем позицию момента времени на табе (0.0 - 1.0)
            // Учитываем отступ для цифр размера в начале таба (используем ту же логику, что и в TabLineViewModel)
            let screenWidth: CGFloat = 375 // Примерная ширина экрана
            let endOffset: CGFloat = 30 // Расстояние до боковой линии
            let startThinBarXPosition: CGFloat = 30
            let timeSignatureWidth: CGFloat = 96
            let spacing: CGFloat = 5
            let timeSignatureOffset = timeSignatureWidth + spacing
            let startOffset = startThinBarXPosition + timeSignatureOffset
            let availableWidth = screenWidth - startOffset - endOffset
            
            // Вычисляем нормализованную позицию начала области для нот
            let startOffsetRatio = Double(startOffset / screenWidth)
            // Вычисляем нормализованную ширину доступной области
            let availableWidthRatio = Double(availableWidth / screenWidth)
            
            // Распределяем моменты времени равномерно в доступной области
            let momentIndexInTab = currentMomentIndex % momentsPerTab
            // Позиция внутри доступной области (0.0 - 1.0)
            let positionInAvailableArea = Double(momentIndexInTab) / Double(momentsPerTab)
            // Итоговая позиция на табе (0.0 - 1.0)
            let momentPositionInTab = startOffsetRatio + positionInAvailableArea * availableWidthRatio
            
            // Для полифонии выбираем струны так, чтобы лады были максимально близкими
            let assignedStrings = assignStringsForPolyphony(notes: notesAtMoment)
            
            // Добавляем все ноты этого момента времени на выбранные струны
            for (noteIndex, note) in notesAtMoment.enumerated() {
                guard noteIndex < assignedStrings.count else {
                    continue
                }
                let stringIndex = assignedStrings[noteIndex]
                let fret = midiNoteToFret(midiNote: note.midiNote, stringIndex: stringIndex)
                let tabFret = TabFret(fretNumber: fret, position: momentPositionInTab, isSelected: false)
                currentTab.strings[stringIndex].frets.append(tabFret)
            }
            
            // Добавляем тактовую линию в конце таба (если это последний момент таба)
            if (currentMomentIndex + 1) % momentsPerTab == 0 {
                let measureEndPosition = 1.0
                for stringIndex in 0..<currentTab.strings.count {
                    let measureBar = MeasureBar(position: measureEndPosition, isDouble: true)
                    currentTab.strings[stringIndex].measureBars.append(measureBar)
                }
            }
            
            currentMomentIndex += 1
        }
        
        // Добавляем последний таб
        if !currentTab.strings.isEmpty {
            tabLines.append(currentTab)
        }
        
        // Если табы пустые, создаём хотя бы один
        if tabLines.isEmpty {
            tabLines.append(TabLine())
        }
        
        return (tabLines, midiInfo.tempo, midiInfo.timeSignatureTop, midiInfo.timeSignatureBottom)
    }
    
    /// Назначает струны для полифонии так, чтобы лады были максимально близкими
    private static func assignStringsForPolyphony(notes: [MIDINoteEvent]) -> [Int] {
        guard !notes.isEmpty else { return [] }
        
        // Для каждой ноты находим все возможные струны
        var possibleAssignments: [[(stringIndex: Int, fret: Int)]] = []
        for note in notes {
            var assignments: [(stringIndex: Int, fret: Int)] = []
            for stringIndex in 0..<6 {
                let fret = midiNoteToFret(midiNote: note.midiNote, stringIndex: stringIndex)
                if fret >= 0 && fret <= 24 {
                    assignments.append((stringIndex: stringIndex, fret: fret))
                }
            }
            // Сортируем по номеру лада (предпочитаем меньшие лады)
            assignments.sort { $0.fret < $1.fret }
            possibleAssignments.append(assignments)
        }
        
        // Используем улучшенный алгоритм: для каждой ноты выбираем струну, которая минимизирует разброс с уже выбранными
        // Но также стараемся использовать разные струны, когда это возможно
        var selectedStrings: [Int] = []
        var selectedFrets: [Int] = []
        var usedStrings: Set<Int> = []
        
        for (noteIndex, assignments) in possibleAssignments.enumerated() {
            guard !assignments.isEmpty else {
                selectedStrings.append(0)
                selectedFrets.append(0)
                continue
            }
            
            var bestStringIndex = assignments[0].stringIndex
            var bestFret = assignments[0].fret
            var bestScore = Double.infinity
            
            // Если это первая нота, выбираем струну с минимальным ладом
            if selectedFrets.isEmpty {
                bestStringIndex = assignments[0].stringIndex
                bestFret = assignments[0].fret
            } else {
                // Для остальных нот выбираем струну, которая минимизирует разброс
                for assignment in assignments {
                    // Пробуем эту струну
                    let testFrets = selectedFrets + [assignment.fret]
                    
                    // Вычисляем разброс ладов (стандартное отклонение)
                    let mean = Double(testFrets.reduce(0, +)) / Double(testFrets.count)
                    let variance = testFrets.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(testFrets.count)
                    let stdDev = sqrt(variance)
                    
                    // Предпочитаем использовать разные струны, если разброс не сильно увеличивается
                    let stringBonus = usedStrings.contains(assignment.stringIndex) ? 0.5 : 0.0 // Штраф за повторное использование струны
                    let score = stdDev + stringBonus
                    
                    if score < bestScore {
                        bestScore = score
                        bestStringIndex = assignment.stringIndex
                        bestFret = assignment.fret
                    }
                }
            }
            
            selectedStrings.append(bestStringIndex)
            selectedFrets.append(bestFret)
            usedStrings.insert(bestStringIndex)
        }
        
        return selectedStrings
    }
    
    /// Экспортирует табулатуру в MIDI файл
    static func exportMIDI(tabLines: [TabLine], tempo: Int, timeSignatureTop: Int, timeSignatureBottom: Int, to url: URL) throws {
        try MIDIWriter.createMIDIFile(
            tabLines: tabLines,
            tempo: tempo,
            timeSignatureTop: timeSignatureTop,
            timeSignatureBottom: timeSignatureBottom,
            to: url
        )
    }
    
    /// Преобразует MIDI ноту в номер лада на струне
    static func midiNoteToFret(midiNote: Int, stringIndex: Int) -> Int {
        let openStringMIDI: [Int] = [40, 45, 50, 55, 59, 64] // E, A, D, G, B, e (от 6-й к 1-й струне)
        guard stringIndex >= 0 && stringIndex < openStringMIDI.count else { 
            return 0 
        }
        let openNote = openStringMIDI[stringIndex]
        let fret = midiNote - openNote
        return max(0, min(24, fret))
    }
    
    /// Преобразует номер лада на струне в MIDI ноту
    static func fretToMIDINote(stringIndex: Int, fretNumber: Int) -> Int {
        let openStringMIDI: [Int] = [40, 45, 50, 55, 59, 64] // E, A, D, G, B, e
        guard stringIndex >= 0 && stringIndex < openStringMIDI.count else { return 60 }
        return openStringMIDI[stringIndex] + fretNumber
    }
}

