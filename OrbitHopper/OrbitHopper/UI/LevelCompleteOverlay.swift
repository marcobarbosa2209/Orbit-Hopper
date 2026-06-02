//
//  LevelCompleteOverlay.swift
//  OrbitHopper
//

import SwiftUI

struct LevelCompleteOverlay: View {
    @ObservedObject var gameState: GameState
    
    @State private var bgOpacity: Double = 0
    @State private var contentOffset: CGFloat = 40
    @State private var contentOpacity: Double = 0
    
    @State private var showStar1 = false
    @State private var showStar2 = false
    @State private var showStar3 = false
    @State private var showScore = false
    
    // Animate score counting up
    @State private var displayScore: Int = 0
    
    var body: some View {
        ZStack {
            // 1. Green pulsing vignette background
            Color.black.opacity(0.85).ignoresSafeArea()
            
            RadialGradient(
                colors: [DS.green.opacity(0.25), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()
            .opacity(bgOpacity)
            
            ScanlineOverlay()
            
            VStack(spacing: 0) {
                Spacer().frame(height: 50)
                
                // 2. Header
                Text("🛸")
                    .font(.system(size: 42))
                    .shadow(color: DS.green.opacity(0.5), radius: 10)
                    .padding(.bottom, 10)
                
                Text(gameState.levelTitle.replacingOccurrences(of: " // ", with: " · "))
                    .font(DS.mono(10))
                    .foregroundColor(DS.green.opacity(0.8))
                    .tracking(3)
                
                Text("MISSION ACCOMPLISHED")
                    .font(DS.orbitron(24, weight: "Black"))
                    .foregroundColor(DS.green)
                    .pulsingGlow(DS.green)
                    .padding(.top, 4)
                
                Spacer().frame(height: 30)
                
                // 3. Stars Display
                HStack(spacing: 16) {
                    StarIcon(filled: gameState.starsEarned >= 1, show: showStar1)
                    StarIcon(filled: gameState.starsEarned >= 2, show: showStar2)
                        .offset(y: -10) // Middle star is higher
                    StarIcon(filled: gameState.starsEarned >= 3, show: showStar3)
                }
                .padding(.bottom, 30)
                
                // 4. Score Panel
                if showScore {
                    SciFiPanel(borderColor: DS.green) {
                        VStack(spacing: 16) {
                            
                            // Breakdown
                            VStack(spacing: 10) {
                                ScoreRow(title: "BASE SCORE", value: gameState.baseScore)
                                ScoreRow(title: "TIME BONUS", value: gameState.timeBonus, color: DS.cyan)
                                ScoreRow(title: "PRECISION BONUS", value: gameState.precisionBonus, color: DS.gold)
                            }
                            
                            Divider().background(DS.green.opacity(0.2))
                            
                            // Total
                            HStack {
                                Text("TOTAL SCORE")
                                    .font(DS.mono(9))
                                    .foregroundColor(DS.green.opacity(0.7))
                                    .tracking(2)
                                Spacer()
                                Text("\(displayScore.formatted())")
                                    .font(.custom("Orbitron-Black", size: 28))
                                    .foregroundColor(.white)
                                    .glow(DS.green, radius: 8)
                            }
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer().frame(height: 40)
                
                // 5. Buttons
                VStack(spacing: 12) {
                    SciFiButton("NEXT LEVEL", icon: "▶", style: .gold) {
                        // Advance to next level
                        gameState.selectedLevelIndex += 1
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
            runAnimations()
        }
    }
    
    private func runAnimations() {
        // Background pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            bgOpacity = 1.0
        }
        
        // Slide up content
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
            contentOffset = 0
            contentOpacity = 1.0
        }
        
        // Pop stars sequentially
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.4)) { showStar1 = true }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.6)) { showStar2 = true }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.8)) { showStar3 = true }
        
        // Show score panel
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.2)) {
            showScore = true
        }
        
        // Animate total score count up
        let targetScore = gameState.baseScore + gameState.timeBonus + gameState.precisionBonus
        let duration = 1.5
        let steps = 30
        let stepDuration = duration / Double(steps)
        let increment = targetScore / steps
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4 + (stepDuration * Double(i))) {
                if i == steps {
                    displayScore = targetScore
                } else {
                    displayScore += increment
                }
            }
        }
    }
}

// MARK: - Helper Views
struct StarIcon: View {
    let filled: Bool
    let show: Bool
    
    var body: some View {
        ZStack {
            Text("★")
                .font(.system(size: 48))
                .foregroundColor(filled ? DS.gold : .white.opacity(0.1))
                .shadow(color: filled ? DS.gold.opacity(0.8) : .clear, radius: 10)
                .scaleEffect(show ? 1.0 : 0.001)
                .rotationEffect(.degrees(show ? 0 : -90))
        }
    }
}

struct ScoreRow: View {
    let title: String
    let value: Int
    var color: Color = .white
    
    var body: some View {
        HStack {
            Text(title)
                .font(DS.mono(8))
                .foregroundColor(DS.green.opacity(0.6))
                .tracking(2)
            Spacer()
            Text(value > 0 ? "+\(value.formatted())" : "0")
                .font(DS.orbitron(14))
                .foregroundColor(color)
        }
    }
}
