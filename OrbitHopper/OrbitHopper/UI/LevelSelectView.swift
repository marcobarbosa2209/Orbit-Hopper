//
//  LevelSelectView.swift
//  OrbitHopper
//

import SwiftUI
import SpriteKit

// MARK: - Level Select View
struct LevelSelectView: View {
    @ObservedObject var gameState: GameState
    let levels = LevelLoader.loadLevels()
    
    // 1. Track how far the player has unlocked
    private var unlockedUpTo: Int {
        SaveManager.getCurrentLevelIndex()
    }
    
    // 2. Count how many levels have at least 1 star
    private var completedCount: Int {
        var count = 0
        for i in 0..<levels.count {
            if SaveManager.getStars(forLevel: i) > 0 { count += 1 }
        }
        return count
    }
    
    var body: some View {
        ZStack {
            SpaceBackground()
            
            VStack(spacing: 0) {
                // 1. Top navigation bar
                topBar
                
                // 2. Completion status
                chapterBar
                
                // 3. Scrollable level path
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 30)
                            
                            // Reverse so highest level is at the top
                            ForEach(Array(levels.enumerated().reversed()), id: \.offset) { index, level in
                                LevelPathNode(
                                    index: index,
                                    level: level,
                                    isUnlocked: index <= unlockedUpTo,
                                    isCurrent: index == unlockedUpTo,
                                    stars: SaveManager.getStars(forLevel: index),
                                    isLast: index == levels.count - 1
                                ) {
                                    // Start this level
                                    gameState.isEndlessMode = false
                                    gameState.selectedLevelIndex = index
                                    gameState.resetForNewGame()
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        gameState.currentMenu = .playing
                                        gameState.gameSessionID = UUID()
                                    }
                                }
                                .id(index)
                            }
                            
                            Spacer().frame(height: 40)
                        }
                    }
                    .onAppear {
                        // 4. Auto-scroll to the current level on appear
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(unlockedUpTo, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        SciFiPanel(borderColor: DS.green) {
            HStack(spacing: 12) {
                // 1. Back button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        gameState.currentMenu = .mainMenu
                    }
                }) {
                    Text("◀")
                        .font(.system(size: 16))
                        .foregroundColor(DS.green)
                        .frame(width: 34, height: 34)
                        .background(DS.green.opacity(0.08))
                        .clipShape(SciFiClipShape(cornerSize: 6))
                        .overlay(SciFiClipShape(cornerSize: 6).stroke(DS.green.opacity(0.35), lineWidth: 1))
                }
                
                Spacer()
                
                // 2. Title
                Text("CAMPAIGN")
                    .font(DS.orbitron(14))
                    .foregroundColor(.white)
                    .tracking(3)
                
                Spacer()
                
                // 3. Spacer to balance layout
                Color.clear.frame(width: 34, height: 34)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 12)
        .padding(.top, 14)
    }
    
    // MARK: - Chapter Bar
    private var chapterBar: some View {
        HStack {
            Text("\(completedCount)/\(levels.count) COMPLETED")
                .font(DS.mono(8))
                .foregroundColor(DS.cyan)
                .tracking(2.5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 28)
        .background(DS.cyan.opacity(0.07))
        .clipShape(SciFiClipShape(cornerSize: 6))
        .overlay(SciFiClipShape(cornerSize: 6).stroke(DS.cyan.opacity(0.3), lineWidth: 1))
        .padding(.horizontal, 12)
        .padding(.top, 10)
    }
}

// MARK: - Level Path Node
struct LevelPathNode: View {
    let index: Int
    let level: Level
    let isUnlocked: Bool
    let isCurrent: Bool
    let stars: Int
    let isLast: Bool
    let onTap: () -> Void
    
    // 1. Calculate offsets for winding path
    private func getOffset(for idx: Int) -> CGFloat {
        let offsets: [CGFloat] = [-60, 40, -30, 60, -50, 30, -40, 50, -20, 45]
        return offsets[idx % offsets.count]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Connecting path line (except for the topmost node)
            if !isLast {
                CurvedPathLine(startXOffset: getOffset(for: index + 1), endXOffset: getOffset(for: index))
                    .stroke(
                        isUnlocked ? DS.green.opacity(0.3) : Color.white.opacity(0.08),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
                    .frame(height: 50)
            }
            
            // 2. The level node
            Button(action: {
                if isUnlocked { onTap() }
            }) {
                VStack(spacing: 8) {
                    // 3. Black hole shader preview
                    ZStack {
                        BlackHolePreview(hexColor: level.blackHoleColor)
                            .frame(width: 90, height: 90)
                            .opacity(isUnlocked ? 1.0 : 0.2)
                        
                        // Pulsing ring for current level
                        if isCurrent {
                            Circle()
                                .stroke(DS.green.opacity(0.6), lineWidth: 2)
                                .frame(width: 90, height: 90)
                                .pulsingGlow(DS.green)
                        }
                        
                        // Lock overlay for locked levels
                        if !isUnlocked {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 80, height: 80)
                            Text("🔒")
                                .font(.system(size: 24))
                        }
                        
                        // 4. Level number badge
                        Text(String(format: "%03d", index + 1))
                            .font(DS.mono(7))
                            .foregroundColor(isUnlocked ? DS.cyan.opacity(0.7) : .white.opacity(0.25))
                            .tracking(2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isUnlocked ? DS.cyan.opacity(0.1) : Color.clear)
                            .clipShape(SciFiClipShape(cornerSize: 4))
                            .overlay(SciFiClipShape(cornerSize: 4).stroke(
                                isUnlocked ? DS.cyan.opacity(0.25) : Color.white.opacity(0.1),
                                lineWidth: 1
                            ))
                            .offset(y: -48)
                        
                        // 5. "CURRENT" badge
                        if isCurrent {
                            Text("CURRENT")
                                .font(DS.mono(6))
                                .foregroundColor(DS.green)
                                .tracking(1.5)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(DS.green.opacity(0.12))
                                .clipShape(SciFiClipShape(cornerSize: 3))
                                .overlay(SciFiClipShape(cornerSize: 3).stroke(DS.green.opacity(0.4), lineWidth: 1))
                                .offset(x: 44, y: -40)
                        }
                    }
                    
                    // 6. Level name
                    Text(isUnlocked ? level.galaxyName.uppercased() : "???")
                        .font(DS.orbitron(9))
                        .foregroundColor(isUnlocked ? .white : .white.opacity(0.2))
                        .tracking(1)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 120)
                    
                    // 7. Star rating
                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { starIndex in
                            Text("★")
                                .font(.system(size: 11))
                                .foregroundColor(starIndex < stars ? DS.gold : .white.opacity(0.2))
                                .shadow(color: starIndex < stars ? DS.gold.opacity(0.8) : .clear, radius: 4)
                        }
                    }
                }
            }
            .disabled(!isUnlocked)
            .offset(x: getOffset(for: index))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Curved Path Line Shape
struct CurvedPathLine: Shape {
    let startXOffset: CGFloat
    let endXOffset: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startPoint = CGPoint(x: rect.midX + startXOffset, y: rect.minY)
        let endPoint = CGPoint(x: rect.midX + endXOffset, y: rect.maxY)
        
        path.move(to: startPoint)
        
        let control1 = CGPoint(x: startPoint.x, y: rect.midY)
        let control2 = CGPoint(x: endPoint.x, y: rect.midY)
        
        path.addCurve(to: endPoint, control1: control1, control2: control2)
        
        return path
    }
}

// MARK: - Black Hole Preview
struct BlackHolePreview: View {
    let hexColor: String
    
    var body: some View {
        SpriteView(scene: makeScene(), options: [.allowsTransparency])
            .background(Color.clear)
    }
    
    private func makeScene() -> SKScene {
        let scene = BlackHolePreviewScene(hexColor: hexColor)
        scene.size = CGSize(width: 100, height: 100)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }
}
