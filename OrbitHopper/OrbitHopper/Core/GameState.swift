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
    @Published var scoreMultiplier: Int = 1
    @Published var progress: CGFloat = 0.0
    @Published var distanceToBlackHole: Int = 250
    @Published var isGameOver: Bool = false
    @Published var gameSessionID = UUID()
    
    @Published var levelTitle: String = ""
    
    @Published var currentMenu: MenuState = .mainMenu
    
    // Ad Tracking
    @Published var isAdReady: Bool = false
    @Published var triggerResurrection: Bool = false
    
    // Level selection
    @Published var selectedLevelIndex: Int = 0
    @Published var isEndlessMode: Bool = false
    
    // Level Complete data
    @Published var starsEarned: Int = 0
    @Published var baseScore: Int = 0
    @Published var timeBonus: Int = 0
    @Published var precisionBonus: Int = 0
    
    // Game Over data
    @Published var levelReached: Int = 0
    
    enum MenuState {
        case mainMenu, levelSelect, settings, playing, paused, gameOver, levelComplete
    }
    
    /// Resets gameplay-related state for a fresh run
    func resetForNewGame() {
        score = 0
        scoreMultiplier = 1
        progress = 0.0
        distanceToBlackHole = 250
        isGameOver = false
        starsEarned = 0
        baseScore = 0
        timeBonus = 0
        precisionBonus = 0
        levelReached = 0
    }
}
