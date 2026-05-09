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
            
            // Score label
            Text("\(gameState.score)")
                    .font(.custom("JetBrainsMono-Bold", size: 96))
                    .foregroundColor(.white.opacity(0.15))
                    .safeAreaPadding(.top)
                    .padding(.top, 240)
            
            // Progress tracker
            VStack {
                VStack(spacing: 8) {
                    Text(gameState.levelTitle)
                        .font(.custom("JetBrainsMono-ExtraBold", size: 20))
                        .foregroundColor(themeColor)
                    
                    HStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(red: 0.102, green: 0.137, blue: 0.145))
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(themeColor, lineWidth: 2))
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(themeColor)
                                    .frame(width: geometry.size.width * gameState.progress)
                                    .animation(.spring(), value: gameState.progress)
                            }
                        }
                        .frame(width: 280, height: 12)
                        
                        Text("\(Int(gameState.progress * 100))%")
                            .font(.custom("Orbitron-Bold", size: 16))
                            .foregroundColor(themeColor)
                    }
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.7))
                .overlay(Rectangle().fill(themeColor.opacity(0.4)).frame(height: 1), alignment: .bottom)
                
                Spacer() // Pushes top and bottom apart
                
                // --- BOTTOM SECTION ---
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
            }
            // --- THE LAYOUT FIX ---
            // This forces the VStack to take up the entire screen, pushing the Spacer to the max
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaPadding(.top)
        }
    }
}
