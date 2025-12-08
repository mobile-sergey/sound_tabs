//
//  TrackSelectorView.swift
//  SoundTabs
//
//  Created by Sergey on 08.12.2025.
//

import SwiftUI

struct TrackSelectorView: View {
    @ObservedObject var viewModel: TrackSelectorViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(viewModel.availableTracks.enumerated()), id: \.offset) { index, _ in
                    Button(action: {
                        viewModel.selectTrack(at: index)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.getTrackName(at: index))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(viewModel.getInstrumentName(at: index))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("\(viewModel.getNotesCount(at: index)) нот")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if viewModel.isTrackSelected(at: index) {
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
                        viewModel.confirmSelection()
                        dismiss()
                    }
                    .disabled(viewModel.isConfirmButtonDisabled)
                }
            }
        }
    }
}

