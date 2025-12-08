//
//  TabFretView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// View для отображения одного лада на табулатуре с номером и названием ноты (при выделении).
/// Позиционирует лад на пересечении струны и вертикальной линии позиции.
struct TabFretView: View {
    @ObservedObject var viewModel: TabFretViewModel
    
    var body: some View {
        VStack(spacing: 2) {
            FretView(
                viewModel: viewModel.createFretViewModel()
            )
            
            // Название ноты под выделенным ладом
            if viewModel.isSelected {
                Text(viewModel.noteName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.orange)
            }
        }
        // Позиционируем точно на пересечении линий
        .position(
            x: viewModel.fretXPosition,
            y: viewModel.fretYPosition
        )
        .onTapGesture {
            // При нажатии на ноту - выделяем её
            viewModel.handleTap()
        }
    }
}

