//
//  MIDIFilePicker.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI
import UniformTypeIdentifiers

/// Обёртка для UIDocumentPickerViewController для выбора MIDI файлов
struct MIDIFilePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onFileSelected: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.midi, .audio], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // Обновление не требуется
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: MIDIFilePicker
        
        init(_ parent: MIDIFilePicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Получаем доступ к файлу
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // Копируем файл во временную директорию для доступа
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            
            do {
                // Удаляем старый файл, если есть
                try? FileManager.default.removeItem(at: tempURL)
                
                // Копируем файл
                try FileManager.default.copyItem(at: url, to: tempURL)
                
                // Вызываем callback с временным URL
                parent.onFileSelected(tempURL)
            } catch {
                print("Ошибка копирования файла: \(error)")
                // Пробуем использовать оригинальный URL
                parent.onFileSelected(url)
            }
            
            parent.isPresented = false
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}

