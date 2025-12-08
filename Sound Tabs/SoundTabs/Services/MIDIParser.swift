//
//  MIDIParser.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import AudioToolbox

/// Структура для хранения MIDI события (нота)
struct MIDINoteEvent {
    let midiNote: Int // MIDI номер ноты (0-127)
    let startTime: Int // Время начала в тиках
    let duration: Int // Длительность в тиках
    let velocity: Int // Громкость (0-127)
    let trackIndex: Int // Индекс трека
}

/// Структура для хранения информации о треке
struct MIDITrackInfo {
    let trackIndex: Int
    let name: String? // Название трека
    let instrument: Int? // Program Change (инструмент)
    let notes: [MIDINoteEvent] // Ноты в треке
    let isGuitar: Bool // Является ли трек гитарой
}

/// Структура для хранения информации о MIDI файле
struct MIDIFileInfo {
    let tempo: Int // BPM
    let timeSignatureTop: Int // Верхняя цифра размера
    let timeSignatureBottom: Int // Нижняя цифра размера
    let ticksPerQuarter: Int // Тиков на четверть
    let tracks: [MIDITrackInfo] // Все треки
    let notes: [MIDINoteEvent] // Все ноты (для обратной совместимости)
}

/// Парсер MIDI файлов
class MIDIParser {
    
    /// Парсит MIDI файл и возвращает информацию о нём
    static func parseMIDIFile(from url: URL) throws -> MIDIFileInfo {
        // Загружаем MIDI файл через AudioToolbox
        var musicSequence: MusicSequence?
        var status = NewMusicSequence(&musicSequence)
        guard status == noErr, let sequence = musicSequence else {
            throw NSError(domain: "MIDIParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось создать MIDI последовательность"])
        }
        defer {
            DisposeMusicSequence(sequence)
        }
        
        status = MusicSequenceFileLoad(sequence, url as CFURL, .midiType, [])
        guard status == noErr else {
            throw NSError(domain: "MIDIParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось загрузить MIDI файл: \(status)"])
        }
        // Получаем информацию о последовательности
        var tempoTrack: MusicTrack?
        status = MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        guard status == noErr else {
            throw NSError(domain: "MIDIParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить трек темпа"])
        }
        
        // Получаем темп (по умолчанию 120)
        var tempo: Double = 120.0
        var tempoIterator: MusicEventIterator?
        status = NewMusicEventIterator(tempoTrack!, &tempoIterator)
        if status == noErr, let iterator = tempoIterator {
            var hasEvent: DarwinBoolean = false
            MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)
            while hasEvent.boolValue {
                var eventTime: MusicTimeStamp = 0
                var eventType: MusicEventType = 0
                var eventData: UnsafeRawPointer?
                var eventDataSize: UInt32 = 0
                
                MusicEventIteratorGetEventInfo(iterator, &eventTime, &eventType, &eventData, &eventDataSize)
                if eventType == kMusicEventType_ExtendedTempo {
                    if let tempoEvent = eventData?.bindMemory(to: ExtendedTempoEvent.self, capacity: 1).pointee {
                        tempo = tempoEvent.bpm
                    }
                }
                MusicEventIteratorNextEvent(iterator)
                MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)
            }
            DisposeMusicEventIterator(iterator)
        }
        
        var timeSignatureTop: Int = 4
        var timeSignatureBottom: Int = 4
        let ticksPerQuarter: Int = 480
        
        // Получаем количество треков
        var trackCount: UInt32 = 0
        MusicSequenceGetTrackCount(sequence, &trackCount)
        
        var tracks: [MIDITrackInfo] = []
        
        // Парсим каждый трек
        for trackIndex in 0..<Int(trackCount) {
            var musicTrack: MusicTrack?
            status = MusicSequenceGetIndTrack(sequence, UInt32(trackIndex), &musicTrack)
            guard status == noErr, let track = musicTrack else {
                continue
            }
            
            var trackName: String? = nil
            var trackInstrument: Int? = nil
            var trackNotes: [MIDINoteEvent] = []
            var activeNotes: [Int: (startTime: Double, velocity: Int)] = [:]
            
            // Итерируем по событиям трека
            var eventIterator: MusicEventIterator?
            status = NewMusicEventIterator(track, &eventIterator)
            guard status == noErr, let iterator = eventIterator else {
                continue
            }
            
            var hasEvent: DarwinBoolean = false
            MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)
            
            while hasEvent.boolValue {
                var eventTime: MusicTimeStamp = 0
                var eventType: MusicEventType = 0
                var eventData: UnsafeRawPointer?
                var eventDataSize: UInt32 = 0
                
                MusicEventIteratorGetEventInfo(iterator, &eventTime, &eventType, &eventData, &eventDataSize)
                
                switch eventType {
                case kMusicEventType_Meta:
                    if let eventData = eventData {
                        var metaEvent = eventData.bindMemory(to: MIDIMetaEvent.self, capacity: 1).pointee
                        if metaEvent.metaEventType == 0x03 { // Track Name
                            let dataPointer = withUnsafePointer(to: &metaEvent.data) { $0 }
                            let data = Data(bytes: dataPointer, count: Int(metaEvent.dataLength))
                            trackName = String(data: data, encoding: .utf8)
                        } else if metaEvent.metaEventType == 0x58 { // Time Signature
                            let dataPointer = withUnsafePointer(to: &metaEvent.data) { $0 }
                            let data = Data(bytes: dataPointer, count: Int(metaEvent.dataLength))
                            if data.count >= 4 {
                                timeSignatureTop = Int(data[0])
                                let bottomPower = Int(data[1])
                                timeSignatureBottom = Int(pow(2.0, Double(bottomPower)))
                            }
                        }
                    }
                    
                case kMusicEventType_MIDIChannelMessage:
                    if let channelMessage = eventData?.bindMemory(to: MIDIChannelMessage.self, capacity: 1).pointee {
                        let status = channelMessage.status & 0xF0
                        let data1 = Int(channelMessage.data1)
                        let data2 = Int(channelMessage.data2)
                        
                        if status == 0x90 && data2 > 0 { // Note On
                            activeNotes[data1] = (startTime: eventTime, velocity: data2)
                        } else if status == 0x80 || (status == 0x90 && data2 == 0) { // Note Off
                            if let noteInfo = activeNotes[data1] {
                                // Преобразуем время из beats в тики
                                let startTimeTicks = Int(noteInfo.startTime * Double(ticksPerQuarter))
                                let endTimeTicks = Int(eventTime * Double(ticksPerQuarter))
                                let duration = endTimeTicks - startTimeTicks
                                
                                trackNotes.append(MIDINoteEvent(
                                    midiNote: data1,
                                    startTime: startTimeTicks,
                                    duration: duration,
                                    velocity: noteInfo.velocity,
                                    trackIndex: trackIndex
                                ))
                                activeNotes.removeValue(forKey: data1)
                            }
                        } else if status == 0xC0 { // Program Change
                            trackInstrument = data1
                        }
                    }
                    
                case kMusicEventType_MIDINoteMessage:
                    if let noteMessage = eventData?.bindMemory(to: MIDINoteMessage.self, capacity: 1).pointee {
                        let startTimeTicks = Int(eventTime * Double(ticksPerQuarter))
                        let durationTicks = Int(Double(noteMessage.duration) * Double(ticksPerQuarter))
                        
                        trackNotes.append(MIDINoteEvent(
                            midiNote: Int(noteMessage.note),
                            startTime: startTimeTicks,
                            duration: durationTicks,
                            velocity: Int(noteMessage.velocity),
                            trackIndex: trackIndex
                        ))
                    }
                    
                default:
                    break
                }
                
                MusicEventIteratorNextEvent(iterator)
                MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)
            }
            
            DisposeMusicEventIterator(iterator)
            
            // Определяем, является ли трек гитарой
            let isGuitar = isGuitarTrack(instrument: trackInstrument, name: trackName)
            
            tracks.append(MIDITrackInfo(
                trackIndex: trackIndex,
                name: trackName,
                instrument: trackInstrument,
                notes: trackNotes,
                isGuitar: isGuitar
            ))
        }
        
        // Собираем все ноты из всех треков
        let allNotes = tracks.flatMap { $0.notes }
        
        return MIDIFileInfo(
            tempo: Int(tempo),
            timeSignatureTop: timeSignatureTop,
            timeSignatureBottom: timeSignatureBottom,
            ticksPerQuarter: ticksPerQuarter,
            tracks: tracks,
            notes: allNotes
        )
    }
    
    /// Определяет, является ли трек гитарой на основе инструмента и названия
    private static func isGuitarTrack(instrument: Int?, name: String?) -> Bool {
        // MIDI Program Change для гитар: 24-31 (Acoustic Guitar, Electric Guitar, etc.)
        if let inst = instrument {
            if inst >= 24 && inst <= 31 {
                return true
            }
        }
        
        // Проверяем название трека
        if let trackName = name?.lowercased() {
            let guitarKeywords = ["guitar", "guit", "гитар", "гит"]
            for keyword in guitarKeywords {
                if trackName.contains(keyword) {
                    return true
                }
            }
        }
        
        return false
    }
}
