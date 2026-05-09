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

    var scene: SKScene {
        let scene = GameScene()
        scene.gameState = gameState
        scene.size = CGSize(width: 300, height: 600)
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        ZStack {
            // 1. Bottom layer is the actual game
            SpriteView(scene: scene)
                .ignoresSafeArea()
            
            // 2. Top layer is SwiftUI
            if gameState.currentMenu == .playing {
                GameHUDView(gameState: gameState)
            } else if gameState.currentMenu == .mainMenu {
                // MainMenuView()
            }
        }
    }
}

#Preview {
    ContentView()
}
 
