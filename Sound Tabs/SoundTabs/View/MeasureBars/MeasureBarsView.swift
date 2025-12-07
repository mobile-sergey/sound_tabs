//
//  MeasureBarsView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// View для отображения тактовых линий (вертикальных линий тактов) на табулатуре.
/// Отображает одинарные и двойные линии тактов на всех струнах.
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
                Rectangle()
                    .fill(Color.black)
                    .frame(width: viewModel.barWidth(for: bar))
                    .frame(height: viewModel.barHeight)
                    .position(
                        x: viewModel.calculateBarXPosition(for: bar),
                        y: viewModel.barYPosition
                    )
            }
        }
    }
}

