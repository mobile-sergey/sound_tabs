//
//  PositionMarkersView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// View для отображения вертикальных маркеров позиций на табулатуре (в настоящее время скрыт).
/// Используется для вычисления позиций нот, но сами линии не отображаются.
struct PositionMarkersView: View {
    @ObservedObject var viewModel: PositionMarkersViewModel
    let geometry: GeometryProxy
    
    init(viewModel: PositionMarkersViewModel = PositionMarkersViewModel(), geometry: GeometryProxy) {
        self.geometry = geometry
        self.viewModel = viewModel
        self.viewModel.size = geometry.size
    }
    
    var body: some View {
        // Вертикальные линии скрыты
        EmptyView()
    }
}

