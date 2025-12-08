//
//  TrackSelectorViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 08.12.2025.
//

import Foundation
import SwiftUI

/// ViewModel для выбора трека из MIDI файла
@MainActor
class TrackSelectorViewModel: ObservableObject {
    @Published var availableTracks: [MIDITrackInfo] = []
    @Published var selectedTrackIndex: Int = 0
    
    var onTrackSelected: ((Int) -> Void)?
    var onConfirm: (() -> Void)?
    
    init(availableTracks: [MIDITrackInfo] = [], selectedTrackIndex: Int = 0) {
        self.availableTracks = availableTracks
        self.selectedTrackIndex = selectedTrackIndex
    }
    
    func selectTrack(at index: Int) {
        guard index >= 0 && index < availableTracks.count else { return }
        selectedTrackIndex = index
        onTrackSelected?(index)
    }
    
    func confirmSelection() {
        onConfirm?()
    }
    
    func getTrackName(at index: Int) -> String {
        guard index >= 0 && index < availableTracks.count else {
            return "Трек \(index + 1)"
        }
        return availableTracks[index].name ?? "Трек \(index + 1)"
    }
    
    func getInstrumentName(at index: Int) -> String {
        guard index >= 0 && index < availableTracks.count else {
            return ""
        }
        return MIDIInstrumentNames.getShortInstrumentName(programChange: availableTracks[index].instrument)
    }
    
    func getNotesCount(at index: Int) -> Int {
        guard index >= 0 && index < availableTracks.count else {
            return 0
        }
        return availableTracks[index].notes.count
    }
    
    func isTrackSelected(at index: Int) -> Bool {
        return selectedTrackIndex == index
    }
    
    var isConfirmButtonDisabled: Bool {
        return availableTracks.isEmpty
    }
}

