//
//  ToolbarView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// View для панели инструментов с кнопкой удаления ноты и панелью выбора номера лада (0-24).
/// Отображает кнопку удаления и горизонтальную прокручиваемую панель с номерами ладов.
struct ToolbarView: View {
    @ObservedObject var viewModel: ToolbarViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Кнопки управления воспроизведением и экспорта/импорта
                HStack(spacing: 16) {
                    // Кнопка Play/Pause
                    Button(action: viewModel.togglePlayPause) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    // Кнопка Save
                    Button(action: viewModel.save) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    // Кнопка Load
                    Button(action: viewModel.load) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    // Кнопка Repeat
                    Button(action: viewModel.toggleRepeat) {
                        Image(systemName: "repeat.circle")
                            .font(.title2)
                            .foregroundColor(viewModel.isRepeatEnabled ? .green : .primary)
                    }
                }
                
                Spacer()
                
                Button(action: viewModel.deleteFret) {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(viewModel.deleteButtonColor)
                }
                .disabled(viewModel.isDeleteButtonDisabled)
            }
            .padding(.top, 8) // Отступ сверху, чтобы не перекрывалось часами
            .padding(.horizontal)
            .padding(.bottom)
            .background(Color(.systemBackground)) // Адаптируется к темному/светлому режиму
            
            // Панель выбора номера лада (0-24) или длины такта - всегда видима
            ScrollView(.horizontal, showsIndicators: false) {
                if viewModel.shouldShowFretSelector {
                    HStack(spacing: 10) {
                        ForEach(0...24, id: \.self) { fretNumber in
                            Button(action: {
                                viewModel.updateFretNumber(fretNumber)
                            }) {
                                ZStack {
                                    // Фон для выделенного номера - белый в светлом режиме, черный в темном
                                    if viewModel.isFretNumberSelected(fretNumber) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color(.systemBackground)) // Белый в светлом, черный в темном
                                            .frame(width: 24, height: 24)
                                    }
                                    
                                    // Оранжевый квадрат для выделенного номера (всегда ярко оранжевый)
                                    if viewModel.isFretNumberSelected(fretNumber) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.orange)
                                            .frame(width: 24, height: 24)
                                    }
                                    
                                    Text("\(fretNumber)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary) // Адаптируется к темному/светлому режиму
                                }
                                .frame(width: 40, height: 40)
                            }
                        }
                    }
                    .padding(.horizontal)
                } else if viewModel.shouldShowMeasureDurationSelector {
                    HStack(spacing: 10) {
                        ForEach(MeasureDuration.allCases, id: \.self) { duration in
                            Button(action: {
                                viewModel.updateMeasureDuration(duration)
                            }) {
                                ZStack {
                                    // Фон для выделенной длины - белый в светлом режиме, черный в темном
                                    if viewModel.isMeasureDurationSelected(duration) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color(.systemBackground)) // Белый в светлом, черный в темном
                                            .frame(width: 40, height: 24)
                                    }
                                    
                                    // Оранжевый квадрат для выделенной длины (всегда ярко оранжевый)
                                    if viewModel.isMeasureDurationSelected(duration) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.orange)
                                            .frame(width: 40, height: 24)
                                    }
                                    
                                    Text(duration.displayString)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary) // Адаптируется к темному/светлому режиму
                                }
                                .frame(width: 50, height: 40)
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Пустая панель с надписью, когда нота или такт не выбраны
                    HStack {
                        Spacer()
                        Text("Выберите ноту или такт для изменения")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary) // Адаптируется к темному/светлому режиму
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .frame(height: 60)
            .background(Color(.systemBackground)) // Адаптируется к темному/светлому режиму
        }
    }
}

