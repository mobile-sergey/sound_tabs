//
//  TabHeaderView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// View для отображения заголовка таба: темпа (для первого таба), текста и аккордов.
/// Объединяет отображение темпа, текстового поля и аккордов в одной области над табом.
struct TabHeaderView: View {
    @ObservedObject var viewModel: TabHeaderViewModel
    @FocusState private var isTempoFocused: Bool
    @FocusState private var isTextFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Темп (только для первого таба)
                if viewModel.isFirstTab {
                    HStack(spacing: 2) {
                        Text("♩")
                            .font(.system(size: 14, weight: .bold))
                        Text("=")
                            .font(.system(size: 14))
                        TextField("", value: Binding(
                            get: { viewModel.tempo ?? 0 },
                            set: { viewModel.handleTempoChange($0) }
                        ), format: .number)
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 45)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .focused($isTempoFocused)
                            .onChange(of: isTempoFocused) { newValue in
                                viewModel.handleTempoFocusChange(newValue)
                            }
                    }
                    .foregroundColor(.primary)
                    .padding(.leading, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Текст над табом
                HStack {
                    // Отступ до первой вертикальной полоски с нотами
                    // startThinBarXPosition (30) + timeSignatureWidth (96) + spacingAfterTimeSignature (5) = 131
                    // Но уменьшаем отступ, чтобы текст начинался на том же уровне, что и у других табов
                    Spacer()
                        .frame(width: 121)
                    
                    TextField("", text: $viewModel.text)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .focused($isTextFocused)
                        .onTapGesture {
                            isTextFocused = true
                            viewModel.onFocusChange?()
                        }
                        .onChange(of: isTextFocused) { newValue in
                            viewModel.handleTextFocusChange(newValue)
                        }
                        .onChange(of: viewModel.text) { newValue in
                            viewModel.handleTextChange(newValue)
                        }
                }
                
                // Аккорды над табом
                ForEach(viewModel.chords) { chord in
                    Text(chord.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .position(
                            x: viewModel.chordXPosition(for: chord, in: geometry),
                            y: geometry.size.height / 2
                        )
                }
            }
        }
        .padding(.top, 2)
        .padding(.bottom, 2)
        .frame(height: 30)
        .background(Color(.systemBackground))
    }
}

