//
//  GameState.swift
//  OrbitHopper
//
//  Created by Marco Barbosa on 09/05/2026.
//

import Foundation
import SwiftUI
import Combine

class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var progress: CGFloat = 0.0
    @Published var distanceToBlackHole: Int = 250
    @Published var isGameOver: Bool = false
    
    @Published var levelTitle: String = ""
    
    @Published var currentMenu: MenuState = .playing
    
    enum MenuState {
        case mainMenu, levelSelect, playing, gameOver
    }
}
