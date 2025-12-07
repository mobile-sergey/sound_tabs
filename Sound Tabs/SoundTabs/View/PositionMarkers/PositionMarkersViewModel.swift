//
//  PositionMarkersViewModel.swift
//  SoundTabs
//
//  Created by Sergey on 07.12.2025.
//

import Foundation
import SwiftUI

class PositionMarkersViewModel: ObservableObject {
    let divisions: Int = 16
    let clefWidth: CGFloat = 50
    
    func markerPosition(for index: Int, in geometry: GeometryProxy) -> CGFloat {
        let position = CGFloat(index) / CGFloat(divisions)
        return geometry.size.width * position
    }
    
    func shouldShowMarker(at index: Int, in geometry: GeometryProxy) -> Bool {
        let position = markerPosition(for: index, in: geometry)
        return position > clefWidth
    }
    
    func markerXPosition(for index: Int, in geometry: GeometryProxy) -> CGFloat {
        markerPosition(for: index, in: geometry)
    }
}

