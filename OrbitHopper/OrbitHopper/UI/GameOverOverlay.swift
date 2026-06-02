//
//  GameOverOverlay.swift
//  OrbitHopper
//

import SwiftUI

struct GameOverOverlay: View {
    @ObservedObject var gameState: GameState
    @ObservedObject var adManager: AdManager
    
    @State private var bgOpacity: Double = 0
    @State private var contentOffset: CGFloat = 40
    @State private var contentOpacity: Double = 0
    
    // 1. Check if this is a new high score for endless mode
    private var isNewRecord: Bool {
        gameState.isEndlessMode && gameState.score > SaveManager.getHighScore()
    }
    
    var body: some View {
        ZStack {
            // 2. Red pulsing vignette background
            Color.black.opacity(0.85).ignoresSafeArea()
            
            RadialGradient(
                colors: [DS.red.opacity(0.4), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()
            .opacity(bgOpacity)
            
            ScanlineOverlay()
            
            VStack(spacing: 0) {
                Spacer().frame(height: 60)
                
                // 3. Header
                Text("GAME OVER")
                    .font(DS.orbitron(42, weight: "Black"))
                    .foregroundColor(DS.red)
                    .pulsingGlow(DS.red)
                
                Text("CONSUMED BY THE VOID")
                    .font(DS.mono(10))
                    .foregroundColor(DS.red.opacity(0.6))
                    .tracking(4)
                    .padding(.top, 4)
                
                Spacer().frame(height: 40)
                
                // 4. Score Panel
                SciFiPanel(borderColor: DS.red) {
                    VStack(spacing: 0) {
                        
                        // New Record Badge
                        if isNewRecord {
                            HStack(spacing: 6) {
                                Text("🏆")
                                Text("NEW RECORD")
                                    .font(DS.mono(8))
                                    .foregroundColor(DS.gold)
                                    .tracking(2)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(DS.gold.opacity(0.1))
                            .clipShape(SciFiClipShape(cornerSize: 4))
                            .overlay(SciFiClipShape(cornerSize: 4).stroke(DS.gold.opacity(0.3), lineWidth: 1))
                            .padding(.top, -12)
                            .padding(.bottom, 12)
                        }
                        
                        Text("FINAL SCORE")
                            .font(DS.mono(9))
                            .foregroundColor(DS.red.opacity(0.7))
                            .tracking(3)
                        
                        Text("\(gameState.score.formatted())")
                            .font(.custom("Orbitron-Black", size: 48))
                            .foregroundColor(.white)
                            .glow(DS.red, radius: 8)
                        
                        Divider()
                            .background(DS.red.opacity(0.2))
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 0) {
                            // Left Stat
                            VStack(spacing: 4) {
                                Text(gameState.isEndlessMode ? "ALL-TIME BEST" : "PLANETS CLEARED")
                                    .font(DS.mono(7))
                                    .foregroundColor(DS.red.opacity(0.5))
                                    .tracking(2)
                                
                                let statValue = gameState.isEndlessMode ? SaveManager.getHighScore() : gameState.levelReached
                                Text("\(statValue.formatted())")
                                    .font(DS.orbitron(16))
                                    .foregroundColor(DS.red)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Rectangle()
                                .fill(DS.red.opacity(0.2))
                                .frame(width: 1, height: 30)
                            
                            // Right Stat
                            VStack(spacing: 4) {
                                Text("MAX COMBO")
                                    .font(DS.mono(7))
                                    .foregroundColor(DS.red.opacity(0.5))
                                    .tracking(2)
                                
                                Text("x\(gameState.scoreMultiplier)")
                                    .font(DS.orbitron(16))
                                    .foregroundColor(DS.red)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 24)
                }
                .padding(.horizontal, 30)
                
                Spacer().frame(height: 40)
                
                // 5. Buttons
                VStack(spacing: 12) {
                    if gameState.isAdReady {
                        SciFiButton("WATCH AD TO REVIVE", icon: "▶", style: .primary) {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                                adManager.showAd(from: rootVC)
                            }
                        }
                    }
                    
                    SciFiButton("PLAY AGAIN", icon: "↺", style: .red) {
                        gameState.resetForNewGame()
                        gameState.currentMenu = .playing
                        gameState.gameSessionID = UUID()
                    }
                    
                    SciFiButton("MAIN MENU", icon: "⌂", style: .secondary) {
                        gameState.resetForNewGame()
                        gameState.currentMenu = .mainMenu
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .offset(y: contentOffset)
            .opacity(contentOpacity)
        }
        .onAppear {
            // Animate background pulse
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                bgOpacity = 1.0
            }
            // Animate content slide up
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                contentOffset = 0
                contentOpacity = 1.0
            }
        }
    }
}
