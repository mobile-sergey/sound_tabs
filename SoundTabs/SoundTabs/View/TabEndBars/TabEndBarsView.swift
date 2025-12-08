//
//  TabEndBarsView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// View для отображения вертикальных линий и точек в начале и конце табулатуры.
/// Отображает жирные и тонкие линии с точками между 2-3 и 4-5 струнами в начале и конце таба.
struct TabEndBarsView: View {
    @ObservedObject var viewModel: TabEndBarsViewModel
    
    var body: some View {
        ZStack {
            // Жирная линия в начале таба (смотрит наружу)
            Rectangle()
                .fill(Color.primary) // Адаптируется к темному/светлому режиму
                .frame(width: viewModel.thickBarWidth)
                .frame(height: viewModel.barHeight)
                .position(
                    x: viewModel.startThickBarXPosition,
                    y: viewModel.barYPosition
                )
            
            // Тонкая линия в начале таба (смотрит внутрь)
            Rectangle()
                .fill(Color.primary) // Адаптируется к темному/светлому режиму
                .frame(width: viewModel.thinBarWidth)
                .frame(height: viewModel.barHeight)
                .position(
                    x: viewModel.startThinBarXPosition,
                    y: viewModel.barYPosition
                )
            
            // Тонкая линия в конце таба (смотрит внутрь)
            Rectangle()
                .fill(Color.primary) // Адаптируется к темному/светлому режиму
                .frame(width: viewModel.thinBarWidth)
                .frame(height: viewModel.barHeight)
                .position(
                    x: viewModel.endThinBarXPosition,
                    y: viewModel.barYPosition
                )
            
            // Жирная линия в конце таба (смотрит наружу)
            Rectangle()
                .fill(Color.primary) // Адаптируется к темному/светлому режиму
                .frame(width: viewModel.thickBarWidth)
                .frame(height: viewModel.barHeight)
                .position(
                    x: viewModel.endThickBarXPosition,
                    y: viewModel.barYPosition
                )
            
            // Точки в начале таба (две точки) - между начальными вертикальными полосками и размером такта
            ForEach(0..<2) { index in
                Circle()
                    .fill(Color.primary) // Адаптируется к темному/светлому режиму
                    .frame(width: viewModel.dotSize, height: viewModel.dotSize)
                    .position(
                        x: viewModel.startDotXPosition,
                        y: viewModel.startDotYPosition(for: index)
                    )
            }
            
            // Точки в конце таба (две точки) - между тонкой и жирной линиями, между 2-3 и 4-5 струнами
            ForEach(0..<2) { index in
                Circle()
                    .fill(Color.primary) // Адаптируется к темному/светлому режиму
                    .frame(width: viewModel.dotSize, height: viewModel.dotSize)
                    .position(
                        x: viewModel.endDotXPosition,
                        y: viewModel.endDotYPosition(for: index)
                    )
            }
        }
    }
}

