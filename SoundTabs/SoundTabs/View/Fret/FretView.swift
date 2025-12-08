//
//  FretView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// View для отображения номера лада с фоном (круг для стирания линии) и оранжевым квадратом при выделении.
/// Отображает номер лада с адаптацией к темному/светлому режиму.
struct FretView: View {
    @ObservedObject var viewModel: FretViewModel
    
    init(viewModel: FretViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            // Круг для стирания линий под цифрой (цвет фона)
            Circle()
                .fill(Color(.systemBackground)) // Адаптируется к темному/светлому режиму
                .frame(width: 22, height: 22)
            
            // Оранжевый квадрат для выделенной ноты (всегда ярко оранжевый)
            if viewModel.isSelected {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.orange)
                    .frame(width: 24, height: 24)
            }
            
            // Номер лада - адаптируется к режиму
            Text("\(viewModel.fretNumber)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary) // Адаптируется к темному/светлому режиму
        }
    }
}

