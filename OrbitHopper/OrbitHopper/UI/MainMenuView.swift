//
//  MainMenuView.swift
//  OrbitHopper
//

import SwiftUI

struct MainMenuView: View {
    @ObservedObject var gameState: GameState
    @State private var logoOffset: CGFloat = 0
    @State private var titleGlowing = false
    
    var body: some View {
        ZStack {
            // Space background with planets
            SpaceBackground(topLeftPlanet: true, topRightPlanet: true, bottomGlow: DS.green)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo section
                VStack(spacing: 6) {
                    // Rocket
                    Text("🚀")
                        .font(.system(size: 52))
                        .shadow(color: DS.green.opacity(0.5), radius: 16)
                    
                    // ORBIT
                    Text("ORBIT")
                        .font(DS.orbitron(52, weight: "Black"))
                        .foregroundColor(DS.green)
                        .pulsingGlow(DS.green)
                    
                    // HOPPER
                    Text("HOPPER")
                        .font(DS.orbitron(52, weight: "Black"))
                        .foregroundColor(.white)
                        .offset(y: -4)
                    
                    // Divider line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, DS.green.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.horizontal, 40)
                    
                    // Tagline
                    Text("NAVIGATE · SURVIVE · CONQUER")
                        .font(DS.mono(8))
                        .foregroundColor(DS.green.opacity(0.45))
                        .tracking(3)
                }
                .offset(y: logoOffset)
                .onAppear {
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        logoOffset = -6
                    }
                }
                
                Spacer()
                    .frame(height: 36)
                
                // Buttons
                VStack(spacing: 12) {
                    SciFiButton("CAMPAIGN", icon: "▶", style: .primary) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            gameState.currentMenu = .levelSelect
                        }
                    }
                    
                    SciFiButton("ENDLESS MODE", icon: "∞", style: .secondary) {
                        gameState.isEndlessMode = true
                        gameState.resetForNewGame()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            gameState.currentMenu = .playing
                            gameState.gameSessionID = UUID()
                        }
                    }
                }
                .padding(.horizontal, 28)
                
                // Bottom bar
                HStack {
                    // Settings gear
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            gameState.currentMenu = .settings
                        }
                    }) {
                        Text("⚙")
                            .font(.system(size: 18))
                            .frame(width: 44, height: 44)
                            .background(DS.green.opacity(0.08))
                            .clipShape(SciFiClipShape(cornerSize: 6))
                            .overlay(SciFiClipShape(cornerSize: 6).stroke(DS.green.opacity(0.3), lineWidth: 1))
                    }
                    
                    Spacer()
                    
                    // Version
                    Text("v1.0.0")
                        .font(DS.mono(7))
                        .foregroundColor(.white.opacity(0.15))
                    
                    Spacer()
                    
                    // Best score
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("BEST SCORE")
                            .font(DS.mono(7))
                            .foregroundColor(DS.green.opacity(0.45))
                            .tracking(2)
                        Text("\(SaveManager.getHighScore().formatted())")
                            .font(DS.orbitron(16))
                            .foregroundColor(DS.green)
                            .glow(DS.green, radius: 5)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Copyright
                Text("ORBIT HOPPER © 2025")
                    .font(DS.mono(7))
                    .foregroundColor(.white.opacity(0.15))
                    .tracking(1)
                    .padding(.bottom, 20)
            }
        }
    }
}
