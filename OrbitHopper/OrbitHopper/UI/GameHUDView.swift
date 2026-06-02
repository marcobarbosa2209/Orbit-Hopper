//
//  GameHUDView.swift
//  OrbitHopper
//
//  Created by Marco Barbosa on 09/05/2026.
//

import SwiftUI

struct GameHUDView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        ZStack(alignment: .top) {
            
            // 1. Background score watermark
            VStack(spacing: -10) {
                Text("\(gameState.score.formatted())")
                    .font(.custom("Orbitron-Black", size: 80))
                    .foregroundColor(.white.opacity(0.08))
                
                // Combo multiplier
                if gameState.scoreMultiplier > 1 {
                    Text("x\(gameState.scoreMultiplier) COMBO!")
                        .font(DS.orbitron(22, weight: "ExtraBold"))
                        .foregroundColor(DS.orange)
                        .glow(DS.orange, radius: 8)
                        .scaleEffect(gameState.scoreMultiplier > 1 ? 1.1 : 1.0)
                        .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: gameState.scoreMultiplier > 1)
                }
            }
            .safeAreaPadding(.top)
            .padding(.top, 200)
            .allowsHitTesting(false)
            
            // 2. HUD overlay
            VStack {
                
                // Top bar with pause + score + shield
                SciFiPanel(borderColor: DS.green) {
                    HStack(spacing: 10) {
                        // Pause button
                        Button(action: {
                            gameState.currentMenu = .paused
                        }) {
                            HStack(spacing: 4) {
                                Rectangle()
                                    .fill(DS.green)
                                    .frame(width: 3, height: 16)
                                    .shadow(color: DS.green, radius: 3)
                                Rectangle()
                                    .fill(DS.green)
                                    .frame(width: 3, height: 16)
                                    .shadow(color: DS.green, radius: 3)
                            }
                            .frame(width: 42, height: 42)
                            .background(DS.green.opacity(0.1))
                            .clipShape(SciFiClipShape(cornerSize: 6))
                            .overlay(SciFiClipShape(cornerSize: 6).stroke(DS.green.opacity(0.5), lineWidth: 1))
                        }
                        
                        // Score
                        VStack(spacing: 1) {
                            Text("SCORE")
                                .font(DS.mono(8))
                                .foregroundColor(DS.green.opacity(0.6))
                                .tracking(3)
                            Text("\(gameState.score.formatted())")
                                .font(.custom("Orbitron-Black", size: 26))
                                .foregroundColor(DS.green)
                                .tracking(2)
                                .pulsingGlow(DS.green)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Multiplier indicator
                        if gameState.scoreMultiplier > 1 {
                            VStack(spacing: 2) {
                                Text("COMBO")
                                    .font(DS.mono(7))
                                    .foregroundColor(DS.orange.opacity(0.7))
                                    .tracking(2)
                                Text("x\(gameState.scoreMultiplier)")
                                    .font(.custom("Orbitron-Black", size: 16))
                                    .foregroundColor(DS.orange)
                                    .glow(DS.orange, radius: 6)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(DS.orange.opacity(0.08))
                            .clipShape(SciFiClipShape(cornerSize: 8))
                            .overlay(SciFiClipShape(cornerSize: 8).stroke(DS.orange.opacity(0.5), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                // 3. Level info panel
                SciFiPanel(borderColor: DS.green) {
                    VStack(spacing: 8) {
                        // Level name and number
                        HStack {
                            if gameState.levelTitle.contains(" // ") {
                                // Split: "GALAXY NAME // LEVEL 001"
                                Text(gameState.levelTitle.components(separatedBy: " // ").first ?? gameState.levelTitle)
                                    .font(DS.orbitron(13))
                                    .foregroundColor(.white)
                                    .glow(.white, radius: 6)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Spacer(minLength: 8)
                                
                                Text(gameState.levelTitle.components(separatedBy: " // ").last ?? "")
                                    .font(DS.mono(9))
                                    .foregroundColor(DS.cyan.opacity(0.7))
                                    .tracking(3)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(DS.cyan.opacity(0.08))
                                    .clipShape(SciFiClipShape(cornerSize: 6))
                                    .overlay(SciFiClipShape(cornerSize: 6).stroke(DS.cyan.opacity(0.25), lineWidth: 1))
                                    .layoutPriority(1)
                            } else {
                                Text(gameState.levelTitle)
                                    .font(DS.orbitron(13))
                                    .foregroundColor(.white)
                                    .glow(.white, radius: 6)
                            }
                        }
                        
                        // Progress bar
                        HStack(spacing: 10) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background track
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.07))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 3)
                                                .stroke(DS.green.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    // Fill
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(
                                            LinearGradient(
                                                colors: [DS.green, Color(red: 128/255, green: 255/255, blue: 176/255)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * min(1.0, gameState.progress))
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: gameState.progress)
                                }
                            }
                            .frame(height: 6)
                            
                            Text("\(Int(gameState.progress * 100))%")
                                .font(DS.mono(10))
                                .foregroundColor(DS.green)
                                .tracking(1)
                                .glow(DS.green, radius: 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .padding(.horizontal, 12)
                .allowsHitTesting(false)
                
                Spacer()
                
                // 4. Bottom: Black hole distance tracker
                VStack(spacing: 4) {
                    // Animated arrows
                    VStack(spacing: -2) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(DS.cyan.opacity(0.5))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(DS.cyan.opacity(0.9))
                    }
                    
                    Text("BLACK HOLE")
                        .font(DS.mono(8))
                        .foregroundColor(DS.cyan.opacity(0.6))
                        .tracking(2.5)
                    
                    Text("\(gameState.distanceToBlackHole) KM")
                        .font(DS.orbitron(18))
                        .foregroundColor(DS.cyan)
                        .tracking(2)
                        .pulsingGlow(DS.cyan)
                    
                    VStack(spacing: -2) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(DS.cyan.opacity(0.9))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(DS.cyan.opacity(0.5))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(DS.panelBg)
                .clipShape(SciFiClipShape())
                .overlay(SciFiClipShape().stroke(DS.cyan.opacity(0.35), lineWidth: 1))
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
                .opacity(gameState.distanceToBlackHole < 250 ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: gameState.distanceToBlackHole < 250)
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaPadding(.top)
        }
    }
}
