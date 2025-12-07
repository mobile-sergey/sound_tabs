//
//  ContentView.swift
//  Sound Tabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                toolbarView
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(viewModel.staffLines.enumerated()), id: \.element.id) { index, _ in
                                SingleStaffLineView(
                                    viewModel: SingleStaffLineViewModel(
                                        staffLine: viewModel.staffLines[index],
                                        selectedNote: viewModel.selectedNote,
                                        selectionRange: SelectionRange(),
                                        isSelecting: false,
                                        repeatMark: viewModel.repeatMark,
                                        isRepeatMode: viewModel.isRepeatMode,
                                        selectedRepeatLine: viewModel.selectedRepeatLine
                                    ),
                                    parentViewModel: viewModel,
                                    staffLineIndex: index,
                                    scrollProxy: proxy,
                                    onScrollToLine: { lineId in
                                        withAnimation {
                                            proxy.scrollTo(lineId, anchor: .center)
                                        }
                                    },
                                    onFindStaffLineAt: { _ in
                                        viewModel.staffLines[index].id
                                    }
                                )
                                .padding(.horizontal)
                                .id(viewModel.staffLines[index].id)
                                .onAppear {
                                    viewModel.loadMoreIfNeeded(at: index)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .scrollDisabled(viewModel.selectedNote != nil || viewModel.selectedRepeatLine != nil)
                }
                
                if let selected = viewModel.selectedNote {
                    selectedNoteView(selected)
                }
            }
            .navigationTitle("Нотный стан")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var toolbarView: some View {
        HStack {
            Button(action: viewModel.toggleRepeatMode) {
                Image(systemName: "repeat")
                    .font(.title2)
                    .foregroundColor(viewModel.isRepeatMode ? .green : .blue)
            }
            
            Spacer()
            
            Button(action: {
                if let note = viewModel.selectedNote {
                    viewModel.deleteNote(note)
                }
            }) {
                Image(systemName: "trash")
                    .font(.title2)
                    .foregroundColor(viewModel.selectedNote != nil ? .red : .gray)
            }
            .disabled(viewModel.selectedNote == nil)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private func selectedNoteView(_ note: Note) -> some View {
        HStack {
            let number = NoteNumberHelper.noteToNumber(note)
            Text("Нота: \(note.name.rawValue)\(note.isSharp ? "♯" : note.isFlat ? "♭" : "") \(note.octave.displayName) | Цифра: \(number)")
                .font(.headline)
                .foregroundColor(.blue)
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }
}


#Preview {
    ContentView()
}
