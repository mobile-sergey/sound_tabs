//
//  ContentView.swift
//  Sound Tabs
//
//  Created by Sergey on 07.12.2025.
//

import SwiftUI

/// Главный View приложения, отображающий панель инструментов и прокручиваемую область с табулатурами.
/// Содержит панель выбора номера лада и область с темпом, текстом над табами и самими табами.
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var toolbarViewModel: ToolbarViewModel
    
    init() {
        let contentVM = ContentViewModel()
        let toolbarVM = ToolbarViewModel(selectedFret: contentVM.selectedFret)
        _viewModel = StateObject(wrappedValue: contentVM)
        _toolbarViewModel = StateObject(wrappedValue: toolbarVM)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbarSection
            
            scrollSection
        }
    }
    
    private var toolbarSection: some View {
        ToolbarView(viewModel: toolbarViewModel)
            .onAppear {
                viewModel.setupToolbarCallbacks(for: toolbarViewModel)
            }
            .onChange(of: viewModel.selectedFret) { _ in
                toolbarViewModel.selectedFret = viewModel.selectedFret
            }
            .onChange(of: viewModel.playbackState.isPlaying) { isPlaying in
                toolbarViewModel.isPlaying = isPlaying
            }
    }
    
    private var scrollSection: some View {
        ScrollView {
                VStack(spacing: 0) {
                    tabLinesSection
            }
            .contentShape(Rectangle())
            .gesture(
                TapGesture()
                    .onEnded { _ in
                        hideKeyboard()
                    }
            )
        }
        .background(Color(.systemBackground)) // Адаптируется к темному/светлому режиму
    }
    
    private var tabLinesSection: some View {
        LazyVStack(spacing: 5) { // Уменьшено расстояние между табами
            ForEach(Array(viewModel.tabLines.enumerated()), id: \.element.id) { index, tabLine in
                TabLineContainerView(
                    viewModel: viewModel.createTabLineContainerViewModel(
                        for: tabLine,
                        at: index,
                        tabWidth: UIScreen.main.bounds.width - 40 // Учитываем padding
                    )
                )
                .id(viewModel.tabLines[index].id)
                .onAppear {
                    viewModel.loadMoreIfNeeded(at: index)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ContentView()
}

