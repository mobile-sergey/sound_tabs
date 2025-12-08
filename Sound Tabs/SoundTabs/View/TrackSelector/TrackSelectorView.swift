//
//  TrackSelectorView.swift
//  SoundTabs
//
//  Created by Sergey on 08.12.2025.
//

import SwiftUI

struct TrackSelectorView: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(viewModel.availableTracks.enumerated()), id: \.offset) { index, track in
                    Button(action: {
                        viewModel.selectedTrackIndex = index
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(track.name ?? "Трек \(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(MIDIInstrumentNames.getShortInstrumentName(programChange: track.instrument))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("\(track.notes.count) нот")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if viewModel.selectedTrackIndex == index {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Выберите трек")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Загрузить") {
                        viewModel.confirmTrackSelection()
                        dismiss()
                    }
                    .disabled(viewModel.availableTracks.isEmpty)
                }
            }
        }
    }
}

