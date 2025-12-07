//
//  RepeatMarkLineViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

class RepeatMarkLineViewModel: ObservableObject {
    @Published var dragOffsetX: CGFloat = 0
    @Published var dragOffsetY: CGFloat = 0
    @Published var dragStartLocation: CGPoint = .zero
    
    func handleDragChanged(value: DragGesture.Value, isDraggable: Bool, position: CGFloat, onDrag: (CGFloat) -> Void, onVerticalDrag: ((CGFloat) -> Void)?) {
        if isDraggable {
            if dragStartLocation == .zero {
                dragStartLocation = value.startLocation
            }
            dragOffsetX = value.translation.width
            dragOffsetY = value.translation.height
            
            let newPosition = position + value.translation.width
            onDrag(newPosition)
            
            if let onVerticalDrag = onVerticalDrag {
                onVerticalDrag(value.translation.height)
            }
        }
    }
    
    func handleDragEnded(value: DragGesture.Value, isDraggable: Bool, position: CGFloat, onDrag: (CGFloat) -> Void, onDragEnd: ((CGPoint) -> Void)?, onDeselect: (() -> Void)?) {
        if isDraggable {
            let newPosition = position + value.translation.width
            onDrag(newPosition)
            
            if let onDragEnd = onDragEnd {
                let globalLocation = CGPoint(
                    x: value.location.x,
                    y: value.startLocation.y + value.translation.height
                )
                onDragEnd(globalLocation)
            }
            
            onDeselect?()
            resetDragState()
        }
    }
    
    func resetDragState() {
        dragOffsetX = 0
        dragOffsetY = 0
        dragStartLocation = .zero
    }
}

