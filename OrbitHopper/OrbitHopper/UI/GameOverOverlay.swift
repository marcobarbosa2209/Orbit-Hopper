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
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("GAME OVER")
                    .font(.custom("JetBrainsMono-Bold", size: 48))
                    .foregroundColor(.white)
                    .shadow(color: themeColor.opacity(0.8), radius: 15)
                
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
                        .shadow(color: themeColor.opacity(0.5), radius: 10)
                    }
                    .buttonStyle(BouncyButtonStyle())
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
                .buttonStyle(BouncyButtonStyle())
            }
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .offset(y: isVisible ? 0 : 50)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isVisible = true
                }
            }
        }
    }
}

// 3. Custom Button Style for the juicy feeling
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
