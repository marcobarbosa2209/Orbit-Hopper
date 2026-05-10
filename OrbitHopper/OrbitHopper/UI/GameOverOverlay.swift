//
//  GameOverOverlay.swift
//  OrbitHopper
//
//  Created by Marco Barbosa on 10/05/2026.
//


import SwiftUI

struct GameOverOverlay: View {
    @ObservedObject var gameState: GameState
    @ObservedObject var adManager: AdManager
    
    let themeColor = Color(red: 0.45, green: 0.95, blue: 0.90)
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("GAME OVER")
                    .font(.custom("JetBrainsMono-Bold", size: 48))
                    .foregroundColor(.white)
                
                VStack(spacing: 10) {
                    Text("SCORE")
                        .font(.custom("Orbitron-Bold", size: 20))
                        .foregroundColor(themeColor)
                    Text("\(gameState.score.formatted())")
                        .font(.custom("JetBrainsMono-Bold", size: 56))
                        .foregroundColor(.white)
                }
                
                // 1. Reward button for player resurrection
                if gameState.isAdReady {
                    Button(action: {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                            adManager.showAd(from: rootVC)
                        }
                    }) {
                        HStack {
                            Image(systemName: "play.tv.fill")
                            Text("WATCH AD TO REVIVE")
                        }
                        .font(.custom("JetBrainsMono-ExtraBold", size: 18))
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: 300)
                        .background(themeColor)
                        .cornerRadius(12)
                    }
                }
                
                // 2. Restart button for a completely fresh run
                Button(action: {
                    // 1. Reset player stats
                    gameState.score = 0
                    gameState.progress = 0.0
                    gameState.distanceToBlackHole = 0
                    gameState.scoreMultiplier = 1
                    
                    // 2. Return to the active game menu
                    gameState.currentMenu = .playing
                    
                    // 3. Trigger scene recreation via ID change
                    gameState.gameSessionID = UUID()
                    
                }) {
                    Text("RESTART")
                        .font(.custom("JetBrainsMono-ExtraBold", size: 18))
                        .foregroundColor(themeColor)
                        .padding()
                        .frame(maxWidth: 300)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeColor, lineWidth: 2))
                }
            }

        }
    }
}
