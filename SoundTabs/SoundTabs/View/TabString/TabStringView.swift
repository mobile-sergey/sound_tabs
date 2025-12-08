//
//  TabStringView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// View для отображения одной струны табулатуры с названием ноты, горизонтальной линией и ладами.
/// Отображает название струны слева и горизонтальную линию с нотами справа.
struct TabStringView: View {
    @ObservedObject var viewModel: TabStringViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            // Название ноты струны
            Text(viewModel.string.noteName)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 25)
                .foregroundColor(.primary) // Адаптируется к темному/светлому режиму
                .padding(.leading, -5)
            
            // Линия струны
            GeometryReader { stringGeometry in
                ZStack {
                    // Горизонтальная линия струны - чёрная
                    Rectangle()
                        .fill(Color.primary) // Адаптируется к темному/светлому режиму
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .position(
                            x: stringGeometry.size.width / 2,
                            y: viewModel.stringLineYPosition(in: stringGeometry)
                        )
                    
                    // Лады на струне - используем актуальные данные из tabLine
                    ForEach(viewModel.getCurrentFrets()) { fret in
                        TabFretView(
                            viewModel: viewModel.createTabFretViewModel(for: fret, stringSize: stringGeometry.size)
                        )
                    }
                }
            }
        }
    }
}

