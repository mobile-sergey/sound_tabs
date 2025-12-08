//
//  TabLineView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// View для отображения одной строки табулатуры с 6 струнами, размером такта, маркерами позиций и тактовыми линиями.
/// Обрабатывает жесты тапа и двойного тапа для создания и выделения нот.
struct TabLineView: View {
    @ObservedObject var viewModel: TabLineViewModel
    
    init(viewModel: TabLineViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // 6 струн гитары
                    ForEach(Array(viewModel.tabLine.strings.enumerated()), id: \.element.id) { index, string in
                        TabStringView(
                            viewModel: viewModel.createTabStringViewModel(for: string, at: index, with: geometry.size)
                        )
                    }
                    .frame(height: 30)
                }
                .background(Color(.systemBackground)) // Адаптируется к темному/светлому режиму
                
                // Размер такта внутри таба, над ним, сразу после первых вертикальных линий
                if let sizeVM = viewModel.createSizeViewModel(
                    tabHeight: geometry.size.height,
                    onFocusChange: {
                        viewModel.parentViewModel?.deselectAllFrets()
                    }
                ) {
                    SizeView(viewModel: sizeVM)
                }
                
                // Вертикальные линии маркеров позиций (8 перекрестий) - на весь таб
                PositionMarkersView(
                    viewModel: viewModel.createPositionMarkersViewModel(
                        divisions: 8,
                        size: geometry.size,
                        timeSignatureWidth: viewModel.timeSignatureWidth,
                        spacingAfterTimeSignature: 5
                    ),
                    geometry: geometry
                )
                
                
                // Тактовые линии на весь таб (рисуются поверх маркеров, но под нотами)
                MeasureBarsView(
                    viewModel: viewModel.createMeasureBarsViewModel(measureBars: viewModel.getMeasureBars(), size: geometry.size),
                    geometry: geometry
                )
                
                // Жирные вертикальные линии в начале и конце таба
                TabEndBarsView(
                    viewModel: TabEndBarsViewModel(size: geometry.size)
                )
                
                // Зелёная вертикальная линия для выделения ноты или воспроизведения
                PlaybackLineView(
                    viewModel: viewModel.createPlaybackLineViewModel(),
                    geometry: geometry
                )
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        // Проверяем, что это был тап (без перетаскивания), а не отпускание после перетаскивания ноты
                        // Если перетаскивали ноту, то не создаем новую ноту
                        if abs(value.translation.width) < 5 && abs(value.translation.height) < 5 {
                            viewModel.handleTap(at: value.location, in: geometry)
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded { _ in
                        // Двойной тап - создаем новую ноту
                        if let location = viewModel.lastTapLocation, let geo = viewModel.lastTapGeometry {
                            viewModel.handleDoubleTap(at: location, in: geo)
                        }
                    }
            )
        }
        .frame(height: 200) // 6 струн * 30 + место для цифр такта внизу
        .background(Color(.systemBackground)) // Адаптируется к темному/светлому режиму
    }
}

