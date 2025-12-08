//
//  RepeatView.swift
//  SoundTabs
//
//  Created by Sergey on 08.12.2025.
//

import SwiftUI

struct RepeatView: View {
    @ObservedObject var viewModel: RepeatViewModel
    let geometry: GeometryProxy
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        if viewModel.shouldShowLine() {
            let startPosition = viewModel.calculateStartPosition(geometry)
            let endPosition = viewModel.calculateEndPosition(geometry)
            
            // Стартовая группа (стрелка + линия) - только если startTab совпадает с текущим табом
            if viewModel.repeatState?.startTab == viewModel.tabLineId {
                ZStack {
                    // Стрелка вправо перед стартовой линией
                    RightArrow()
                        .fill(Color.green)
                        .frame(width: 12, height: 60)
                        .position(
                            x: startPosition - 8.5 + (viewModel.isStartSelected() ? dragOffset.width : 0),
                            y: geometry.size.height / 2
                        )

                    // Стартовая зелёная линия
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 5)
                        .frame(height: geometry.size.height)
                        .position(
                            x: startPosition + (viewModel.isStartSelected() ? dragOffset.width : 0),
                            y: geometry.size.height / 2
                        )
                    
                    // Обводка при выделении стартового Repeat
                    if viewModel.isStartSelected() {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.green, lineWidth: 2)
                            .frame(width: 40, height: geometry.size.height + 10)
                            .position(
                                x: startPosition + dragOffset.width,
                                y: geometry.size.height / 2
                            )
                    }
                }
                .contentShape(Rectangle().inset(by: -30))
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // При начале движения выделяем, если не выделен
                            if !viewModel.isStartSelected() {
                                viewModel.handleStartTap(at: value.startLocation, in: geometry)
                            } else {
                                // Если уже выделен, обрабатываем перетаскивание и перепрыгивание на другие табы
                                let didJump = viewModel.handleStartDragDuring(translation: value.translation, in: geometry)
                                // Если Repeat перепрыгнул на другой таб, сбрасываем offset
                                if didJump {
                                    dragOffset = .zero
                                } else {
                                    dragOffset = value.translation
                                }
                            }
                        }
                        .onEnded { value in
                            if viewModel.isStartSelected() && abs(value.translation.width) > 2 {
                                viewModel.handleStartDrag(translation: value.translation, in: geometry)
                                dragOffset = .zero
                            } else if abs(value.translation.width) < 5 && abs(value.translation.height) < 5 {
                                // Это был тап, а не перетаскивание
                                viewModel.handleStartTap(at: value.startLocation, in: geometry)
                            }
                        }
                )
            }
            
            // Финишная группа (линия + стрелка) - только если endTab совпадает с текущим табом
            if viewModel.repeatState?.endTab == viewModel.tabLineId {
                ZStack {
                    // Финишная зелёная линия
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 5)
                        .frame(height: geometry.size.height)
                        .position(
                            x: endPosition + (viewModel.isEndSelected() ? dragOffset.width : 0),
                            y: geometry.size.height / 2
                        )
                    
                    // Стрелка влево после финишной линии
                    LeftArrow()
                        .fill(Color.green)
                        .frame(width: 12, height: 60)
                        .position(
                            x: endPosition + 8.5 + (viewModel.isEndSelected() ? dragOffset.width : 0),
                            y: geometry.size.height / 2
                        )
                    
                    // Обводка при выделении финишного Repeat
                    if viewModel.isEndSelected() {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.green, lineWidth: 2)
                            .frame(width: 40, height: geometry.size.height + 10)
                            .position(
                                x: endPosition + dragOffset.width,
                                y: geometry.size.height / 2
                            )
                    }
                }
                .contentShape(Rectangle().inset(by: -30))
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // При начале движения выделяем, если не выделен
                            if !viewModel.isEndSelected() {
                                viewModel.handleEndTap(at: value.startLocation, in: geometry)
                            } else {
                                // Если уже выделен, обрабатываем перетаскивание и перепрыгивание на другие табы
                                let didJump = viewModel.handleEndDragDuring(translation: value.translation, in: geometry)
                                // Если Repeat перепрыгнул на другой таб, сбрасываем offset
                                if didJump {
                                    dragOffset = .zero
                                } else {
                                    dragOffset = value.translation
                                }
                            }
                        }
                        .onEnded { value in
                            if viewModel.isEndSelected() && abs(value.translation.width) > 2 {
                                viewModel.handleEndDrag(translation: value.translation, in: geometry)
                                dragOffset = .zero
                            } else if abs(value.translation.width) < 5 && abs(value.translation.height) < 5 {
                                // Это был тап, а не перетаскивание
                                viewModel.handleEndTap(at: value.startLocation, in: geometry)
                            }
                        }
                )
            }
        }
    }
}

// Трапеция-стрелка вправо (острие справа)
struct RightArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let offset = rect.width // Отступ для широкой части трапеции
        
        // Начинаем с левого нижнего угла (широкая часть)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + offset))
        // Левая сторона вверх
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - offset))
        // Верхняя сторона вправо (к острию)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        // Правая сторона вниз (острие)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        // Нижняя сторона влево (к широкой части)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + offset))
        path.closeSubpath()
        return path
    }
}

// Трапеция-стрелка влево (острие слева)
struct LeftArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let offset = rect.width // Отступ для широкой части трапеции
        
        // Начинаем с левого верхнего угла (острие)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        // Левая сторона вниз (острие)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        // Нижняя сторона вправо (к широкой части)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - offset))
        // Правая сторона вверх (широкая часть)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + offset))
        // Верхняя сторона влево (к острию)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
