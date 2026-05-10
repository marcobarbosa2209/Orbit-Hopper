//
//  ContentView.swift
//  OrbitHopper
//
//  Created by Marco Barbosa on 07/05/2026.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    
    @StateObject var gameState = GameState()
    @StateObject var adManager = AdManager()
    
    // 1. Stable scene reference to prevent unnecessary redraws
    @State private var currentScene: GameScene?
    
    private func makeScene() -> GameScene {
        let scene = GameScene()
        scene.gameState = gameState
        scene.size = CGSize(width: 300, height: 600)
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        ZStack {
            // 1. Bottom layer is the actual game
            if let scene = currentScene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
                    .id(gameState.gameSessionID)
            }
            
            // 2. Top layer is SwiftUI HUD and menus
            if gameState.currentMenu == .playing {
                GameHUDView(gameState: gameState)
            } else if gameState.currentMenu == .gameOver {
                GameOverOverlay(gameState: gameState, adManager: adManager)
            }
        }
        .onAppear {
            // 1. Initialize ad SDK and link game state
            adManager.gameState = gameState
            adManager.initialize()
            currentScene = makeScene()
        }
        .onChange(of: gameState.gameSessionID) {
            // 1. Create fresh scene on game restart
            currentScene = makeScene()
        }
    }
}


#Preview {
    ContentView()
}
