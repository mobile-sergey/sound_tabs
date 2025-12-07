//
//  SizeView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// View для отображения размера такта внутри таба: две цифры (верхняя и нижняя) вертикально.
/// Отображается после начальных вертикальных линий таба, занимает всю высоту таба.
struct SizeView: View {
    @ObservedObject var viewModel: SizeViewModel
    @FocusState private var isTopFocused: Bool
    @FocusState private var isBottomFocused: Bool
    
    var body: some View {
        // Размер такта - две большие цифры вертикально, занимающие всю высоту таба
            VStack(spacing: 0) {
                TextField("", value: $viewModel.sizeTop, format: .number)
                    .font(.system(size: viewModel.fontSize, weight: .light))
                    .frame(width: viewModel.fieldWidth)
                    .frame(height: viewModel.fieldHeight)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .focused($isTopFocused)
                    .onTapGesture {
                        isTopFocused = true
                    }
                    .onChange(of: isTopFocused) { newValue in
                        viewModel.handleTopFocusChange(newValue)
                    }
                    .onChange(of: viewModel.sizeTop) { newValue in
                        viewModel.handleTopChange(newValue)
                    }
                
                TextField("", value: $viewModel.sizeBottom, format: .number)
                    .font(.system(size: viewModel.fontSize, weight: .light))
                    .frame(width: viewModel.fieldWidth)
                    .frame(height: viewModel.fieldHeight)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .focused($isBottomFocused)
                    .onTapGesture {
                        isBottomFocused = true
                    }
                    .onChange(of: isBottomFocused) { newValue in
                        viewModel.handleBottomFocusChange(newValue)
                    }
                    .onChange(of: viewModel.sizeBottom) { newValue in
                        viewModel.handleBottomChange(newValue)
                    }
            }
            .foregroundColor(.primary) // Адаптируется к темному/светлому режиму
            .frame(height: viewModel.tabHeight)
            .position(
                x: viewModel.sizeXPosition,
                y: viewModel.sizeYPosition
            )
    }
}

