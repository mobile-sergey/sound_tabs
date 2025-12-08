//
//  MeasureBarsView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// View для отображения тактовых линий (вертикальных линий тактов) на табулатуре.
/// Отображает одинарные и двойные линии тактов на всех струнах и длину такта под каждым тактом.
struct MeasureBarsView: View {
    @ObservedObject var viewModel: MeasureBarsViewModel
    let geometry: GeometryProxy
    
    init(viewModel: MeasureBarsViewModel, geometry: GeometryProxy) {
        self.viewModel = viewModel
        self.geometry = geometry
    }
    
    var body: some View {
        if !viewModel.measureBars.isEmpty {
            ForEach(viewModel.measureBars) { bar in
                ZStack {                    
                    // Длина такта внизу таба, под струнами
                    Text(viewModel.getDuration(for: bar).displayString)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewModel.isBarSelected(bar) ? .orange : .primary)
                        .position(
                            x: viewModel.calculateBarXPosition(for: bar),
                            y: viewModel.barHeight - 10 // Внизу таба, под последней струной
                        )
                        .onTapGesture {
                            viewModel.handleBarTap(bar)
                        }
                }
            }
        }
    }
}

