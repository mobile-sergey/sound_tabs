//
//  GuitarSoundService.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import AVFoundation

/// Сервис для проигрывания звуков гитары
@MainActor
class GuitarSoundService {
    static let shared = GuitarSoundService()
    
    private var audioEngine: AVAudioEngine
    private var playerNodes: [AVAudioPlayerNode] = []
    private var audioFiles: [Int: AVAudioFile] = [:] // MIDI note -> AVAudioFile
    
    private init() {
        audioEngine = AVAudioEngine()
        setupAudioSession()
        setupAudioEngine()
        loadGuitarSamples()
    }
    
    /// Настраивает AVAudioSession для воспроизведения звука
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("AVAudioSession настроен успешно")
        } catch {
            print("Ошибка настройки AVAudioSession: \(error)")
        }
    }
    
    private func setupAudioEngine() {
        // Не подключаем узлы здесь, сделаем это при первом проигрывании
        // чтобы использовать правильный формат
    }
    
    /// Убеждается, что audioEngine запущен и правильно настроен
    private func ensureEngineRunning() {
        guard !audioEngine.isRunning else { return }
        
        // Получаем формат от outputNode
        let outputNode = audioEngine.outputNode
        let outputFormat = outputNode.inputFormat(forBus: 0)
        print("Output format: sampleRate=\(outputFormat.sampleRate), channels=\(outputFormat.channelCount)")
        
        // Подключаем mainMixerNode к outputNode с правильным форматом
        let mainMixer = audioEngine.mainMixerNode
        
        // Проверяем, не подключен ли уже mainMixer
        // Если нет, подключаем
        do {
            audioEngine.connect(mainMixer, to: outputNode, format: outputFormat)
            try audioEngine.start()
            print("AudioEngine успешно запущен, sampleRate=\(outputFormat.sampleRate)")
        } catch {
            print("Ошибка запуска аудио движка: \(error)")
            // Пробуем переподключить
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            audioEngine = AVAudioEngine()
            let newOutputNode = audioEngine.outputNode
            let newOutputFormat = newOutputNode.inputFormat(forBus: 0)
            let newMainMixer = audioEngine.mainMixerNode
            audioEngine.connect(newMainMixer, to: newOutputNode, format: newOutputFormat)
            do {
                try audioEngine.start()
                print("AudioEngine перезапущен успешно")
            } catch {
                print("Критическая ошибка запуска аудио движка: \(error)")
            }
        }
    }
    
    /// Загружает семплы гитары для каждой ноты
    private func loadGuitarSamples() {
        // Генерируем синтетические звуки гитары для каждой MIDI ноты (40-88, что соответствует E2-E6)
        // В реальном приложении здесь можно загрузить WAV файлы с семплами гитары
        // Сейчас семплы генерируются на лету в playNote, поэтому здесь ничего не делаем
    }
    
    /// Преобразует MIDI ноту в частоту в Гц
    private func midiNoteToFrequency(midiNote: Int) -> Double {
        // Формула: f = 440 * 2^((n-69)/12), где n - номер MIDI ноты
        return 440.0 * pow(2.0, Double(midiNote - 69) / 12.0)
    }
    
    /// Проигрывает ноту гитары
    /// - Parameters:
    ///   - midiNote: MIDI номер ноты (40-88)
    ///   - duration: Длительность в секундах
    ///   - velocity: Громкость (0-127)
    func playNote(midiNote: Int, duration: TimeInterval, velocity: Int = 100) {
        // Убеждаемся, что audioEngine запущен перед созданием формата
        ensureEngineRunning()
        
        // Получаем формат от outputNode для совместимости (это правильный формат)
        let outputNode = audioEngine.outputNode
        let outputFormat = outputNode.inputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate
        let channelCount = outputFormat.channelCount
        
        // Получаем mainMixer для подключения
        let mainMixer = audioEngine.mainMixerNode
        
        let frequency = midiNoteToFrequency(midiNote: midiNote)
        print("Проигрывание ноты: MIDI=\(midiNote), frequency=\(frequency) Hz, duration=\(duration), sampleRate=\(sampleRate), channels=\(channelCount)")
        
        let frameCount = Int(sampleRate * duration)
        
        guard frameCount > 0 else {
            print("Ошибка: frameCount = 0")
            return
        }
        
        // Создаем формат, совместимый с outputNode (используем outputFormat напрямую)
        // Создаем буфер в формате outputNode
        guard let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(frameCount)) else {
            print("Ошибка создания аудио буфера")
            return
        }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Генерируем звук с обертонами для имитации гитары
        let velocityFactor = Float(velocity) / 127.0
        
        for frame in 0..<frameCount {
            let time = Double(frame) / sampleRate
            // Основной тон
            let fundamental = sin(2.0 * .pi * frequency * time)
            // Добавляем обертоны для более реалистичного звука гитары
            let harmonic2 = sin(2.0 * .pi * frequency * 2.0 * time)
            let harmonic3 = sin(2.0 * .pi * frequency * 3.0 * time)
            // Комбинируем все компоненты
            var sample: Float = Float(fundamental)
            sample += Float(0.3 * harmonic2)
            sample += Float(0.2 * harmonic3)
            // Применяем огибающую (envelope) для имитации затухания струны
            let envelope = exp(-time * 2.0) // Экспоненциальное затухание
            sample *= Float(envelope) * velocityFactor
            
            // Записываем в все каналы (моно в стерео)
            for channel in 0..<Int(channelCount) {
                if let channelData = buffer.floatChannelData?[channel] {
                    channelData[frame] = sample
                }
            }
        }
        
        // Создаем player node для этой ноты
        let playerNode = AVAudioPlayerNode()
        audioEngine.attach(playerNode)
        
        // Подключаем к главному микшеру с форматом outputNode
        // Используем формат от outputNode для полной совместимости
        audioEngine.connect(playerNode, to: mainMixer, format: outputFormat)
        
        // Устанавливаем громкость для playerNode (максимальная)
        playerNode.volume = 1.0
        
        // Устанавливаем громкость для mainMixer (максимальная)
        mainMixer.volume = 1.0
        
        print("Создан playerNode для MIDI=\(midiNote), всего активных playerNodes: \(playerNodes.count + 1)")
        
        // Проигрываем
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
            Task { @MainActor in
                print("Завершено проигрывание MIDI=\(midiNote)")
                // Удаляем player node после завершения
                self?.removePlayerNode(playerNode)
                self?.audioEngine.detach(playerNode)
            }
        })
        
        // Запускаем проигрывание
        playerNode.play()
        
        // Сохраняем ссылку для управления
        playerNodes.append(playerNode)
        print("Запущено проигрывание MIDI=\(midiNote), всего активных playerNodes: \(playerNodes.count), volume=\(playerNode.volume)")
    }
    
    /// Останавливает все проигрываемые ноты
    func stopAllNotes() {
        for playerNode in playerNodes {
            playerNode.stop()
            audioEngine.detach(playerNode)
        }
        playerNodes.removeAll()
    }
    
    /// Удаляет player node из списка после завершения проигрывания
    private func removePlayerNode(_ playerNode: AVAudioPlayerNode) {
        if let index = playerNodes.firstIndex(where: { $0 === playerNode }) {
            playerNodes.remove(at: index)
        }
    }
}

