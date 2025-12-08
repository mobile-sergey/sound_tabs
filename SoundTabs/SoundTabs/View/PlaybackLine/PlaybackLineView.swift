//
//  PlaybackLineView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// View для отображения зелёной линии воспроизведения/выделения.
/// Отображает вертикальную зелёную линию на позиции воспроизведения или выделенной ноты.
struct PlaybackLineView: View {
    @ObservedObject var viewModel: PlaybackLineViewModel
    let geometry: GeometryProxy
    
    var body: some View {
        if viewModel.shouldShowLine() {
            let position = viewModel.getLinePosition()
            let xPosition = viewModel.calculateXPosition(for: position, in: geometry)
            
            Rectangle()
                .fill(Color.green)
                .frame(width: 2)
                .frame(height: geometry.size.height)
                .position(
                    x: xPosition,
                    y: geometry.size.height / 2
                )
        }
    }
}

