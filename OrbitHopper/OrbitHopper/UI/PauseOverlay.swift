//
//  PauseOverlay.swift
//  OrbitHopper
//

import SwiftUI

struct PauseOverlay: View {
    @ObservedObject var gameState: GameState
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            // 1. Semi-transparent backdrop
            Color.black.opacity(0.75)
                .ignoresSafeArea()
            
            // 2. Pause panel
            VStack(spacing: 20) {
                // Pause icon bars
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(DS.green)
                        .frame(width: 5, height: 22)
                        .shadow(color: DS.green, radius: 5)
                    Rectangle()
                        .fill(DS.green)
                        .frame(width: 5, height: 22)
                        .shadow(color: DS.green, radius: 5)
                }
                
                // Title
                Text("PAUSED")
                    .font(.custom("Orbitron-Black", size: 28))
                    .foregroundColor(DS.green)
                    .tracking(4)
                    .pulsingGlow(DS.green)
                
                // Subtitle
                Text(gameState.levelTitle.replacingOccurrences(of: " // ", with: " · "))
                    .font(DS.mono(8))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(2.5)
                
                // 3. Stats row
                HStack(spacing: 0) {
                    // Score
                    VStack(spacing: 3) {
                        Text("SCORE")
                            .font(DS.mono(7))
                            .foregroundColor(DS.green.opacity(0.5))
                            .tracking(2)
                        Text("\(gameState.score.formatted())")
                            .font(DS.orbitron(15))
                            .foregroundColor(DS.green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(DS.green.opacity(0.04))
                    .overlay(
                        Rectangle().stroke(DS.green.opacity(0.15), lineWidth: 1)
                    )
                    
                    // Distance
                    VStack(spacing: 3) {
                        Text("DISTANCE")
                            .font(DS.mono(7))
                            .foregroundColor(DS.green.opacity(0.5))
                            .tracking(2)
                        Text("\(gameState.distanceToBlackHole) KM")
                            .font(DS.orbitron(13))
                            .foregroundColor(DS.cyan)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(DS.green.opacity(0.04))
                    .overlay(
                        Rectangle().stroke(DS.green.opacity(0.15), lineWidth: 1)
                    )
                }
                
                // 4. Buttons
                VStack(spacing: 10) {
                    SciFiButton("RESUME", icon: "▶", style: .primary) {
                        gameState.currentMenu = .playing
                    }
                    
                    SciFiButton("RESTART LEVEL", icon: "↺", style: .secondary) {
                        gameState.resetForNewGame()
                        gameState.currentMenu = .playing
                        gameState.gameSessionID = UUID()
                    }
                    
                    SciFiButton("QUIT TO MENU", icon: "⌂", style: .danger) {
                        gameState.resetForNewGame()
                        gameState.currentMenu = .mainMenu
                    }
                }
            }
            .padding(24)
            .frame(width: 310)
            .background(Color(red: 3/255, green: 12/255, blue: 24/255).opacity(0.97))
            .clipShape(SciFiClipShape())
            .overlay(SciFiClipShape().stroke(DS.green.opacity(0.38), lineWidth: 1))
            .overlay(CornerAccents(color: DS.green))
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .opacity(isVisible ? 1.0 : 0)
            .offset(y: isVisible ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}
