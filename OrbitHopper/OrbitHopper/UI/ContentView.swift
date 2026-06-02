//
//  ContentView.swift
//  OrbitHopper
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    
    @StateObject var gameState = GameState()
    @StateObject var adManager = AdManager()
    
    // Stable scene reference to prevent unnecessary redraws
    @State private var currentScene: GameScene?
    
    private func makeScene() -> GameScene {
        let scene = GameScene()
        scene.gameState = gameState
        scene.size = CGSize(width: 300, height: 600)
        scene.scaleMode = .resizeFill
        
        // Pass the correct director based on game mode
        if gameState.isEndlessMode {
            scene.director = EndlessDirector()
        } else {
            scene.director = CampaignDirector(levelIndex: gameState.selectedLevelIndex)
        }
        
        return scene
    }

    var body: some View {
        ZStack {
            // 1. Bottom layer: The actual game (only rendered when playing/paused/etc)
            if gameState.currentMenu != .mainMenu && gameState.currentMenu != .levelSelect && gameState.currentMenu != .settings {
                if let scene = currentScene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                        .id(gameState.gameSessionID)
                }
            }
            
            // 2. Top layer: Menus and overlays
            switch gameState.currentMenu {
            case .mainMenu:
                MainMenuView(gameState: gameState)
                
            case .levelSelect:
                LevelSelectView(gameState: gameState)
                
            case .settings:
                MainMenuView(gameState: gameState) // Keep menu in background
                SettingsView(gameState: gameState, audioManager: AudioManager.shared)
                
            case .playing:
                GameHUDView(gameState: gameState)
                
            case .paused:
                GameHUDView(gameState: gameState)
                PauseOverlay(gameState: gameState)
                
            case .gameOver:
                GameOverOverlay(gameState: gameState, adManager: adManager)
                
            case .levelComplete:
                LevelCompleteOverlay(gameState: gameState)
            }
        }
        .onAppear {
            adManager.gameState = gameState
            adManager.initialize()
            
            // Start with menu music
            AudioManager.shared.playMenuMusic()
        }
        .onChange(of: gameState.currentMenu) { newValue in
            // Handle music transitions
            if newValue == .playing {
                AudioManager.shared.pauseMenuMusic()
                // Unpause scene if returning from pause
                currentScene?.isPaused = false
            } else if newValue == .paused || newValue == .gameOver || newValue == .levelComplete {
                // Pause the SpriteKit scene when an overlay is up
                currentScene?.isPaused = true
            } else {
                AudioManager.shared.playMenuMusic()
                // Destroy scene if we went back to main menus
                if newValue == .mainMenu || newValue == .levelSelect {
                    currentScene = nil
                }
            }
        }
        .onChange(of: gameState.gameSessionID) {
            // Create fresh scene on game restart
            currentScene = makeScene()
        }
    }
}

#Preview {
    ContentView()
}
