//
//  TabLineContainerView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// View-контейнер, объединяющий заголовок таба (темп, текст, аккорды) и саму табулатуру.
/// Отображает все компоненты таба в вертикальном стеке.
struct TabLineContainerView: View {
    @ObservedObject var viewModel: TabLineContainerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок таба (темп для первого таба, текст и аккорды)
            TabHeaderView(
                viewModel: viewModel.tabHeaderViewModel
            )
            
            // Сам таб
            TabLineView(
                viewModel: viewModel.tabLineViewModel
            )
        }
    }
}

