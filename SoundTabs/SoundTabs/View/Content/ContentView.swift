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
    @StateObject private var viewModel: ContentViewModel
    
    init() {
        let contentVM = ContentViewModel()
        _viewModel = StateObject(wrappedValue: contentVM)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbarSection
            
            scrollSection
        }
        .sheet(isPresented: $viewModel.shouldShowMIDIPicker) {
            MIDIFilePicker(isPresented: $viewModel.shouldShowMIDIPicker) { url in
                viewModel.importMIDIFile(from: url)
            }
        }
        .sheet(isPresented: $viewModel.shouldShowTrackSelector) {
            if let trackSelectorViewModel = viewModel.trackSelectorViewModel {
                TrackSelectorView(viewModel: trackSelectorViewModel)
            }
        }
    }
    
    private var toolbarSection: some View {
        ToolbarView(viewModel: viewModel.toolbarViewModel)
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
        .background(Color(.systemBackground))
    }
    
    private var tabLinesSection: some View {
        LazyVStack(spacing: 5) {
            ForEach(Array(viewModel.tabLines.enumerated()), id: \.element.id) { index, tabLine in
                TabLineContainerView(
                    viewModel: viewModel.createTabLineContainerViewModel(
                        for: tabLine,
                        at: index,
                        tabWidth: UIScreen.main.bounds.width - 40
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

