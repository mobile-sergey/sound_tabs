//
//  MIDIWriter.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import AudioToolbox

/// Класс для создания MIDI файлов
class MIDIWriter {
    
    /// Создаёт MIDI файл из табулатуры
    static func createMIDIFile(
        tabLines: [TabLine],
        tempo: Int,
        timeSignatureTop: Int,
        timeSignatureBottom: Int,
        to url: URL
    ) throws {
        // Создаём MIDI последовательность
        var musicSequence: MusicSequence?
        var status = NewMusicSequence(&musicSequence)
        guard status == noErr, let sequence = musicSequence else {
            throw NSError(domain: "MIDIWriter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось создать MIDI последовательность"])
        }
        defer {
            DisposeMusicSequence(sequence)
        }
        
        // Устанавливаем тип последовательности
        MusicSequenceSetSequenceType(sequence, MusicSequenceType.beats)
        
        // Создаём трек для нот
        var musicTrack: MusicTrack?
        status = MusicSequenceNewTrack(sequence, &musicTrack)
        guard status == noErr, let track = musicTrack else {
            throw NSError(domain: "MIDIWriter", code: 2, userInfo: [NSLocalizedDescriptionKey: "Не удалось создать MIDI трек"])
        }
        
        // Устанавливаем инструмент - Guitar (Acoustic Guitar steel = 25)
        var channelMessage = MIDIChannelMessage(status: 0xC0, data1: 25, data2: 0, reserved: 0)
        let timeStamp = MusicTimeStamp(0.0)
        status = MusicTrackNewMIDIChannelEvent(track, timeStamp, &channelMessage)
        guard status == noErr else {
            throw NSError(domain: "MIDIWriter", code: 3, userInfo: [NSLocalizedDescriptionKey: "Не удалось установить инструмент"])
        }
        
        // Собираем все ноты из табов
        var allNotes: [(time: Int, note: Int, duration: Int, velocity: Int)] = []
        let ticksPerQuarter = 480
        let ticksPerMeasure = ticksPerQuarter * timeSignatureTop
        let noteDuration = ticksPerMeasure / 8 // 1/8 от верхней цифры размера
        
        // Вычисляем отступ для цифр размера (та же логика, что и при импорте)
        let screenWidth: CGFloat = 375
        let endOffset: CGFloat = 30
        let startThinBarXPosition: CGFloat = 30
        let timeSignatureWidth: CGFloat = 96
        let spacing: CGFloat = 5
        let timeSignatureOffset = timeSignatureWidth + spacing
        let startOffset = startThinBarXPosition + timeSignatureOffset
        let availableWidth = screenWidth - startOffset - endOffset
        let startOffsetRatio = Double(startOffset / screenWidth)
        let availableWidthRatio = Double(availableWidth / screenWidth)
        
        for (tabIndex, tabLine) in tabLines.enumerated() {
            // Группируем ноты по позициям для обработки полифонии
            var notesByPosition: [Double: [(stringIndex: Int, fret: TabFret)]] = [:]
            
            for (stringIndex, string) in tabLine.strings.enumerated() {
                for fret in string.frets {
                    let position = fret.position
                    if notesByPosition[position] == nil {
                        notesByPosition[position] = []
                    }
                    notesByPosition[position]?.append((stringIndex: stringIndex, fret: fret))
                }
            }
            
            // Сортируем позиции
            let sortedPositions = notesByPosition.keys.sorted()
            
            for position in sortedPositions {
                guard let notesAtPosition = notesByPosition[position] else { continue }
                
                // Вычисляем время в тиках
                // Позиция на табе (0.0 - 1.0) учитывает отступ для цифр размера
                // Преобразуем позицию в момент времени
                // Позиция начинается с startOffsetRatio и распределяется по availableWidthRatio
                let positionInAvailableArea = (position - startOffsetRatio) / availableWidthRatio
                let clampedPosition = max(0.0, min(1.0, positionInAvailableArea))
                
                // В одном табе максимум 8 моментов времени
                let momentsPerTab = 8
                let momentIndexInTab = Int(clampedPosition * Double(momentsPerTab))
                let momentInTab = min(momentsPerTab - 1, max(0, momentIndexInTab))
                
                // Вычисляем абсолютный момент времени
                let absoluteMoment = tabIndex * momentsPerTab + momentInTab
                
                // Вычисляем время в тиках (каждый момент = 1/8 такта)
                let ticksPerMoment = ticksPerMeasure / 8
                let absoluteTime = absoluteMoment * ticksPerMoment
                
                // Добавляем все ноты на этой позиции (полифония)
                for (stringIndex, fret) in notesAtPosition {
                    let midiNote = MIDIService.fretToMIDINote(stringIndex: stringIndex, fretNumber: fret.fretNumber)
                    allNotes.append((
                        time: absoluteTime,
                        note: midiNote,
                        duration: noteDuration,
                        velocity: 100 // Стандартная громкость
                    ))
                }
            }
        }
        
        // Сортируем ноты по времени
        allNotes.sort { $0.time < $1.time }
        
        // Устанавливаем темп
        var tempoTrack: MusicTrack?
        status = MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        guard status == noErr, let tempoTrk = tempoTrack else {
            throw NSError(domain: "MIDIWriter", code: 4, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить трек темпа"])
        }
        
        status = MusicTrackNewExtendedTempoEvent(tempoTrk, 0.0, Float64(tempo))
        guard status == noErr else {
            throw NSError(domain: "MIDIWriter", code: 5, userInfo: [NSLocalizedDescriptionKey: "Не удалось установить темп"])
        }
        
        // Пропускаем установку размера такта через мета-событие
        // Это не критично для создания MIDI файла, и вызывает проблемы с копированием данных
        // Размер такта будет использоваться из параметров функции для вычисления длительности нот
        
        // Добавляем ноты в трек
        // Преобразуем тики в музыкальное время (beats)
        let ticksPerQuarterForConversion = 480
        
        for noteEvent in allNotes {
            // Преобразуем время из тиков в beats
            let startTimeBeats = Double(noteEvent.time) / Double(ticksPerQuarterForConversion)
            let durationBeats = Double(noteEvent.duration) / Double(ticksPerQuarterForConversion)
            
            // Создаём MIDI ноту
            var noteMessage = MIDINoteMessage(
                channel: 0,
                note: UInt8(noteEvent.note),
                velocity: UInt8(noteEvent.velocity),
                releaseVelocity: 0,
                duration: Float32(durationBeats)
            )
            
            status = MusicTrackNewMIDINoteEvent(track, startTimeBeats, &noteMessage)
            if status != noErr {
                throw NSError(domain: "MIDIWriter", code: 6, userInfo: [NSLocalizedDescriptionKey: "Не удалось добавить ноту: \(status)"])
            }
        }
        
        // Сохраняем MIDI файл
        // Важно: последний параметр - это ticksPerQuarterNote, должен быть 480
        status = MusicSequenceFileCreate(sequence, url as CFURL, .midiType, .eraseFile, Int16(ticksPerQuarter))
        guard status == noErr else {
            throw NSError(domain: "MIDIWriter", code: 7, userInfo: [NSLocalizedDescriptionKey: "Не удалось сохранить MIDI файл: \(status)"])
        }
    }
}

