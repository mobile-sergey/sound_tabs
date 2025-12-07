//
//  PositionMarkersView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

// Вид маркеров позиций (16 делений)
struct PositionMarkersView: View {
    @ObservedObject var viewModel: PositionMarkersViewModel
    let geometry: GeometryProxy
    
    init(viewModel: PositionMarkersViewModel = PositionMarkersViewModel(), geometry: GeometryProxy) {
        self.viewModel = viewModel
        self.geometry = geometry
    }
    
    var body: some View {
        ForEach(0..<viewModel.divisions, id: \.self) { index in
            if viewModel.shouldShowMarker(at: index, in: geometry) {
                let x = viewModel.markerXPosition(for: index, in: geometry)
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1)
                    .frame(height: 100)
                    .position(x: x, y: geometry.size.height / 2)
            }
        }
    }
}

