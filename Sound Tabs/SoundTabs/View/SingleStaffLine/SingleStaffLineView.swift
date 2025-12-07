//
//  SingleStaffLineView.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

struct SingleStaffLineView: View {
    @ObservedObject var viewModel: SingleStaffLineViewModel
    @ObservedObject var parentViewModel: ContentViewModel
    let staffLineIndex: Int
    var scrollProxy: ScrollViewProxy?
    var onScrollToLine: (UUID) -> Void
    var onFindStaffLineAt: (CGPoint) -> UUID?
    
    init(
        viewModel: SingleStaffLineViewModel,
        parentViewModel: ContentViewModel,
        staffLineIndex: Int,
        scrollProxy: ScrollViewProxy? = nil,
        onScrollToLine: @escaping (UUID) -> Void = { _ in },
        onFindStaffLineAt: @escaping (CGPoint) -> UUID? = { _ in nil }
    ) {
        self.viewModel = viewModel
        self._parentViewModel = ObservedObject(wrappedValue: parentViewModel)
        self.staffLineIndex = staffLineIndex
        self.scrollProxy = scrollProxy
        self.onScrollToLine = onScrollToLine
        self.onFindStaffLineAt = onFindStaffLineAt
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                staffLinesView
                clefView(geometry: geometry)
                PositionMarkersView(viewModel: PositionMarkersViewModel(), geometry: geometry)
                measureBarsView(geometry: geometry)
                selectionBracketView(geometry: geometry)
                notesView(geometry: geometry)
                interactionArea(geometry: geometry)
            }
            .overlay {
                // Зелёные линии рисуются поверх всего
                repeatMarksView(geometry: geometry)
            }
        }
        .frame(height: 150)
        .background(Color.white)
        .border(Color.gray.opacity(0.3), width: 1)
    }
    
    private var staffLinesView: some View {
        VStack(spacing: viewModel.staffLineSpacing) {
            ForEach(0..<5, id: \.self) { _ in
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(height: 1)
            }
        }
        .frame(height: viewModel.staffHeight)
        .padding(.horizontal, 40)
    }
    
    private func clefView(geometry: GeometryProxy) -> some View {
        let offsetX = -geometry.size.width / 2 + 50
        return Text("𝄞")
            .font(.system(size: 50))
            .offset(x: offsetX, y: 0)
    }
    
    private func measureBarsView(geometry: GeometryProxy) -> some View {
        ForEach(viewModel.staffLine.measureBars) { bar in
            let x = geometry.size.width * bar.position
            let y = geometry.size.height / 2
            let width = bar.isDouble ? 3.0 : 1.0
            
            Rectangle()
                .fill(Color.black)
                .frame(width: width)
                .frame(height: viewModel.staffHeight + 20)
                .position(x: x, y: y)
        }
    }
    
    @ViewBuilder
    private func selectionBracketView(geometry: GeometryProxy) -> some View {
        if viewModel.shouldShowSelection {
            let startX = geometry.size.width * viewModel.selectionRange.normalizedStart
            let endX = geometry.size.width * viewModel.selectionRange.normalizedEnd
            SelectionBracketView(
                startX: startX,
                endX: endX,
                staffHeight: viewModel.staffHeight
            )
        }
    }
    
    private func notesView(geometry: GeometryProxy) -> some View {
        ForEach(viewModel.staffLine.notes.indices, id: \.self) { noteIndex in
            let note = viewModel.staffLine.notes[noteIndex]
            let bindingNote = Binding(
                get: { viewModel.staffLine.notes[noteIndex] },
                set: { 
                    viewModel.staffLine.notes[noteIndex] = $0
                    parentViewModel.staffLines[staffLineIndex] = viewModel.staffLine
                }
            )
            let x = geometry.size.width * note.position
            let yOffset = getStaffPosition(for: note).yOffset
            let y = geometry.size.height / 2 + yOffset
            let isSelected = viewModel.selectedNote?.id == note.id
            
            ZStack {
                NoteView(
                    viewModel: NoteViewModel(
                        note: note,
                        isSelected: isSelected,
                        showNoteName: isSelected,
                        onDrag: { translation, location in
                            if let updatedNote = viewModel.handleNoteDrag(translation: translation, location: location, note: note, geometry: geometry) {
                                parentViewModel.updateNote(updatedNote)
                                parentViewModel.staffLines[staffLineIndex] = viewModel.staffLine
                            }
                        },
                        onDragEnd: {
                            parentViewModel.selectedNote = nil
                        },
                        onNoteChanged: { updatedNote in
                            bindingNote.wrappedValue = updatedNote
                        }
                    )
                )
                
                // Отображение цифры под нотой
                if isSelected {
                    let number = NoteNumberHelper.noteToNumber(note)
                    Text("\(number)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                        .offset(y: 35)
                }
            }
            .position(x: x, y: y)
            .allowsHitTesting(true)
            .zIndex(isSelected ? 1 : 0)
        }
    }
    
    @ViewBuilder
    private func repeatMarksView(geometry: GeometryProxy) -> some View {
        if let mark = parentViewModel.repeatMark, mark.tablatureId == viewModel.staffLine.id {
            // Фон выделенного интервала
            if parentViewModel.isRepeatMode {
                let startX = geometry.size.width * mark.startPosition
                let endX = geometry.size.width * mark.endPosition
                if abs(endX - startX) > 0 {
                    Rectangle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: abs(endX - startX))
                        .frame(height: viewModel.staffHeight + 30)
                        .position(
                            x: (startX + endX) / 2,
                            y: viewModel.staffHeight / 2 + 15
                        )
                }
            }
            
            // Левая зелёная линия
            RepeatMarkLineView(
                position: geometry.size.width * mark.startPosition,
                staffHeight: viewModel.staffHeight,
                isDraggable: parentViewModel.isRepeatMode,
                isSelected: parentViewModel.selectedRepeatLine == .start,
                onDrag: { newPosition in
                    let normalizedPosition = snapToDivision(newPosition / geometry.size.width, divisions: 16)
                    parentViewModel.updateRepeatMarkStart(normalizedPosition, toLineId: viewModel.staffLine.id)
                },
                onVerticalDrag: { _ in },
                onTap: {
                    parentViewModel.selectRepeatLine(.start)
                },
                onDragEnd: { location in
                    handleRepeatLineDragEnd(location: location, geometry: geometry, lineType: .start)
                },
                onDeselect: {
                    parentViewModel.deselectRepeatLine()
                }
            )
            
            // Правая зелёная линия
            RepeatMarkLineView(
                position: geometry.size.width * mark.endPosition,
                staffHeight: viewModel.staffHeight,
                isDraggable: parentViewModel.isRepeatMode,
                isSelected: parentViewModel.selectedRepeatLine == .end,
                onDrag: { newPosition in
                    let normalizedPosition = snapToDivision(newPosition / geometry.size.width, divisions: 16)
                    parentViewModel.updateRepeatMarkEnd(normalizedPosition, toLineId: viewModel.staffLine.id)
                },
                onVerticalDrag: { _ in },
                onTap: {
                    parentViewModel.selectRepeatLine(.end)
                },
                onDragEnd: { location in
                    handleRepeatLineDragEnd(location: location, geometry: geometry, lineType: .end)
                },
                onDeselect: {
                    parentViewModel.deselectRepeatLine()
                }
            )
        }
    }
    
    private func interactionArea(geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        handleTap(at: value.location, in: geometry)
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        if !viewModel.isSelecting {
                            // Добавление тактовой линии
                        }
                    }
            )
    }
    
    private func handleTap(at location: CGPoint, in geometry: GeometryProxy) {
        // Если клик за пределами таба - снимаем выделение
        if !viewModel.isWithinStaffBounds(location, in: geometry) {
            if viewModel.selectedNote != nil {
                parentViewModel.selectedNote = nil
            }
            if parentViewModel.selectedRepeatLine != nil {
                parentViewModel.deselectRepeatLine()
            }
            return
        }
        
        let xPosition = location.x / geometry.size.width
        let clampedPosition = max(0, min(1, xPosition))
        
        // Проверяем, не попали ли мы на ноту
        let tappedNote = viewModel.findNoteAt(location: location, in: geometry)
        
        if let note = tappedNote {
            // Нажали на ноту - выделяем её
            parentViewModel.selectNote(note)
        } else {
            // Нажали на пустое место - создаём новую ноту
            if !viewModel.isSelecting && isPositionAfterClef(clampedPosition) {
                let snappedPosition = snapToDivision(clampedPosition, divisions: 16)
                parentViewModel.addNote(to: viewModel.staffLine.id, at: snappedPosition)
                // Синхронизируем изменения
                viewModel.staffLine = parentViewModel.staffLines[staffLineIndex]
            }
        }
    }
    
    private func handleRepeatLineDragEnd(location: CGPoint, geometry: GeometryProxy, lineType: RepeatLineType) {
        let normalizedPosition = snapToDivision(location.x / geometry.size.width, divisions: 16)
        
        let staffCenterY = geometry.size.height / 2
        let staffTop = staffCenterY - viewModel.staffHeight / 2
        let staffBottom = staffCenterY + viewModel.staffHeight / 2
        
        var targetLineId = viewModel.staffLine.id
        if location.y < staffTop || location.y > staffBottom {
            if let foundLineId = onFindStaffLineAt(location) {
                targetLineId = foundLineId
            }
        }
        
        if lineType == .start {
            parentViewModel.updateRepeatMarkStart(normalizedPosition, toLineId: targetLineId)
        } else {
            parentViewModel.updateRepeatMarkEnd(normalizedPosition, toLineId: targetLineId)
        }
    }
}

// Вид зелёной скобки выделения
struct SelectionBracketView: View {
    let startX: CGFloat
    let endX: CGFloat
    let staffHeight: CGFloat
    
    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Color.green.opacity(0.25))
                .frame(width: max(3, endX - startX))
                .frame(height: staffHeight + 40)
                .position(
                    x: (startX + endX) / 2,
                    y: staffHeight / 2 + 20
                )
            
            Rectangle()
                .fill(Color.green)
                .frame(width: 3)
                .frame(height: staffHeight + 30)
                .position(x: startX, y: staffHeight / 2 + 15)
            
            Rectangle()
                .fill(Color.green)
                .frame(width: 3)
                .frame(height: staffHeight + 30)
                .position(x: endX, y: staffHeight / 2 + 15)
            
            Image(systemName: "heart.fill")
                .foregroundColor(.green)
                .font(.system(size: 18))
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                )
                .position(
                    x: (startX + endX) / 2,
                    y: 8
                )
        }
    }
}
