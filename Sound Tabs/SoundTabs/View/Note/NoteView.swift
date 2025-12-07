//
//  NoteView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

// Вид отдельной ноты
struct NoteView: View {
    @ObservedObject var viewModel: NoteViewModel
    
    init(viewModel: NoteViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Овал ноты
                Ellipse()
                    .fill(viewModel.isSelected ? Color.blue : Color.black)
                    .frame(width: 20, height: 15)
                
                // Штиль (если не целая нота)
                if viewModel.note.duration != .whole {
                    Rectangle()
                        .fill(viewModel.isSelected ? Color.blue : Color.black)
                        .frame(width: 2, height: 40)
                        .offset(x: 10, y: -20)
                }
                
                // Флажок для восьмых и шестнадцатых
                if viewModel.note.duration == .eighth || viewModel.note.duration == .sixteenth {
                    Path { path in
                        path.move(to: CGPoint(x: 12, y: -20))
                        path.addLine(to: CGPoint(x: 12, y: -35))
                        path.addQuadCurve(to: CGPoint(x: 20, y: -30), control: CGPoint(x: 16, y: -32))
                    }
                    .stroke(viewModel.isSelected ? Color.blue : Color.black, lineWidth: 2)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(viewModel.isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    .padding(-4)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        viewModel.handleDragChanged(translation: value.translation, location: value.location)
                    }
                    .onEnded { value in
                        viewModel.handleDragEnded(translation: value.translation, location: value.location)
                    }
            )
            .highPriorityGesture(
                DragGesture()
                    .onChanged { value in
                        viewModel.handleDragChanged(translation: value.translation, location: value.location)
                    }
                    .onEnded { value in
                        viewModel.handleDragEnded(translation: value.translation, location: value.location)
                    }
            )
            
            // Название ноты снизу
            if viewModel.showNoteName && viewModel.isSelected {
                VStack(spacing: 2) {
                    Text(viewModel.noteName)
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    Text("\(viewModel.noteNumber)")
                        .font(.system(size: 8))
                        .foregroundColor(.blue.opacity(0.7))
                }
                .padding(.top, 2)
            }
        }
    }
    
}

#Preview {
    NoteView(viewModel: NoteViewModel(
        note: Note(name: .C, octave: .first, position: 0),
        isSelected: true,
        showNoteName: true
    ))
}
