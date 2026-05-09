//
//  GameHUDView.swift
//  OrbitHopper
//
//  Created by Marco Barbosa on 09/05/2026.
//

import SwiftUI

struct GameHUDView: View {
    @ObservedObject var gameState: GameState
    let themeColor = Color(red: 0.45, green: 0.95, blue: 0.90)
    
    var body: some View {
        ZStack(alignment: .top) {
            
            // Score layer
            VStack(spacing: -10) {
                // Using .formatted() to automatically adds commas
                Text("\(gameState.score.formatted())")
                    .font(.custom("JetBrainsMono-Bold", size: 80))
                    .foregroundColor(.white.opacity(0.15))
                
                // Combo multiplier
                if gameState.scoreMultiplier > 1 {
                    Text("x\(gameState.scoreMultiplier) COMBO!")
                        .font(.custom("JetBrainsMono-ExtraBold", size: 28))
                        .foregroundColor(.yellow.opacity(0.8))
                        // Add a pulse effect to the combo
                        .scaleEffect(gameState.scoreMultiplier > 1 ? 1.1 : 1.0)
                        .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: gameState.scoreMultiplier > 1)
                }
            }
            .safeAreaPadding(.top)
            .padding(.top, 240)
            .allowsHitTesting(false)
            
            // Progress tracker
            VStack {
                
                // HStack containing the Progress Card and Pause Button
                HStack(spacing: 12) {
                    
                    // Left Card: Progress Tracker
                    VStack(alignment: .leading, spacing: 12) {
                        
                        HStack {
                            // Left side: Galaxy Name, truncating with ellipsis if too long
                            Text(gameState.levelTitle.components(separatedBy: " // ").first ?? gameState.levelTitle)
                                .font(.custom("JetBrainsMono-ExtraBold", size: 16))
                                .foregroundColor(themeColor)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            if gameState.levelTitle.contains(" // ") {
                                Spacer(minLength: 8)
                                
                                // Right side: Level Number
                                Text("\(gameState.levelTitle.components(separatedBy: " // ").last ?? "")")
                                    .font(.custom("JetBrainsMono-ExtraBold", size: 16))
                                    .foregroundColor(themeColor)
                                    .layoutPriority(1)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background Track
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(red: 0.102, green: 0.137, blue: 0.145))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(gameState.progress <= 1 ? themeColor : Color.yellow, lineWidth: 1))
                                    
                                    // Fill
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(gameState.progress <= 1 ? themeColor : Color.yellow)
                                        .frame(width: geometry.size.width * min(1.0, gameState.progress))
                                        .animation(.spring(), value: gameState.progress)
                                }
                            }
                            .frame(height: 10)
                            
                            Text("\(Int(gameState.progress * 100))%")
                                .font(.custom("Orbitron-Bold", size: 16))
                                .foregroundColor(gameState.progress <= 1 ? themeColor : Color.yellow)
                        }
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeColor, lineWidth: 1.5))
                    .allowsHitTesting(false)
                    
                    
                    // Right Card: Pause Button
                    Button(action: {
                        print("Pause button tapped!")
                        // TODO: Add pause button logic
                    }) {
                        Image(systemName: "pause")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(themeColor)
                            .frame(width: 84, height: 84)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeColor, lineWidth: 1.5))
                    }
                    
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer() // Pushes top and bottom apart
                
                // Bottom Section: Distance Tracker ---
                VStack(spacing: 4) {
                    Text("\(gameState.distanceToBlackHole)km")
                        .font(.custom("JetBrainsMono-Bold", size: 24))
                        .foregroundColor(themeColor)
                    
                    Image(systemName: "arrow.down")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(themeColor)
                }
                .padding(.bottom, 20)
                .opacity(gameState.distanceToBlackHole < 250 ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: gameState.distanceToBlackHole < 250)
                .allowsHitTesting(false) // Ghost the distance tracker
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaPadding(.top)
        }
    }
}
