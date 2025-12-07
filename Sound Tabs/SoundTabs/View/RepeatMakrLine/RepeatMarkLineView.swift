//
//  RepeatMarkLineView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

struct RepeatMarkLineView: View {
    @StateObject private var viewModel = RepeatMarkLineViewModel()
    
    let position: CGFloat
    let staffHeight: CGFloat
    let isDraggable: Bool
    let isSelected: Bool
    var onDrag: (CGFloat) -> Void
    var onVerticalDrag: ((CGFloat) -> Void)?
    var onTap: () -> Void
    var onDragEnd: ((CGPoint) -> Void)?
    var onDeselect: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Зелёный прямоугольник выделения
            if isSelected {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 40, height: staffHeight + 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.green, lineWidth: 2)
                    )
                    .position(x: position + viewModel.dragOffsetX, y: staffHeight / 2 + 15 + viewModel.dragOffsetY)
            }
            
            // Вертикальная линия
            Rectangle()
                .fill(Color.green)
                .frame(width: isSelected ? 5 : 3)
                .frame(height: staffHeight + 30)
                .position(x: position + viewModel.dragOffsetX, y: staffHeight / 2 + 15 + viewModel.dragOffsetY)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    viewModel.handleDragChanged(
                        value: value,
                        isDraggable: isDraggable,
                        position: position,
                        onDrag: onDrag,
                        onVerticalDrag: onVerticalDrag
                    )
                }
                .onEnded { value in
                    viewModel.handleDragEnded(
                        value: value,
                        isDraggable: isDraggable,
                        position: position,
                        onDrag: onDrag,
                        onDragEnd: onDragEnd,
                        onDeselect: onDeselect
                    )
                }
        )
        .onTapGesture {
            onTap()
        }
        .highPriorityGesture(
            DragGesture()
                .onChanged { value in
                    viewModel.handleDragChanged(
                        value: value,
                        isDraggable: isDraggable,
                        position: position,
                        onDrag: onDrag,
                        onVerticalDrag: onVerticalDrag
                    )
                }
                .onEnded { value in
                    viewModel.handleDragEnded(
                        value: value,
                        isDraggable: isDraggable,
                        position: position,
                        onDrag: onDrag,
                        onDragEnd: onDragEnd,
                        onDeselect: onDeselect
                    )
                }
        )
    }
}

