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
            
            // Панель выбора номера лада (0-24) - всегда видима
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
                } else {
                    // Пустая панель с надписью, когда нота не выбрана
                    HStack {
                        Spacer()
                        Text("Выберите ноту для изменения")
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

