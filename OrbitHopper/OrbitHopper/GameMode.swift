//
//  GameMode.swift
//  OrbitHopper
//
//  Created by Marco Barbosa on 07/05/2026.
//

import SpriteKit

// 1. Define the Math Function signature
typealias RotationCurve = (_ elapsedTime: CGFloat) -> CGFloat

// 2. A Factory to generate random or static math formulas for the planets
struct CurveFactory {
    
    // Returns a standard, constant rotation speed
    static func generateConstant(speed: CGFloat) -> RotationCurve {
        return { _ in return speed }
    }
    
    // Returns a dynamic sine wave that speeds up, slows down, and reverses
    static func generateRandomWave() -> RotationCurve {
        let baseSpeed = CGFloat.random(in: 0.5...1.5)
        let amplitude = CGFloat.random(in: 0.5...2.5)
        let frequency = CGFloat.random(in: 1.0...4.0)
        
        return { time in
            return baseSpeed + (sin(time * frequency) * amplitude)
        }
    }
}

// 3. The exact object to spawn
enum SpawnableObject {
    case planet(radius: CGFloat, speedMultiplier: CGFloat, curve: RotationCurve, imagePath: String?)
    case spaceStation(radius: CGFloat)
    // case meteor(radius: CGFloat, speed: CGVector)
}

// 4. The Blueprint for Game Modes
protocol GameModeDirector {
    var score: Int { get set }
    func generateNextObject() -> SpawnableObject?
    func getBlackHoleSpeed() -> CGFloat
    func getMeteorChance() -> CGFloat
}

// 5. Endless Mode Logic
class EndlessDirector: GameModeDirector {
    var score = 0
    var spawnCount = 0
    let possibleTextures = ["planet-earth", "planet-mars"]
    
    func generateNextObject() -> SpawnableObject? {
        let randomRadius = CGFloat.random(in: 40...70)
        let randomImage = possibleTextures.randomElement()
        
        let curve: RotationCurve
        
        // First 3 planets are easy and constant. After that, generate random planets
        if self.spawnCount < 3 {
            curve = CurveFactory.generateConstant(speed: 1.0)
        } else {
            curve = CurveFactory.generateRandomWave()
        }
        
        self.spawnCount += 1
        
        return .planet(radius: randomRadius,
                       speedMultiplier: 1.0,
                       curve: curve,
                       imagePath: randomImage)
    }
    
    func getBlackHoleSpeed() -> CGFloat {
        let initialSpeed: CGFloat = 30.0
        
        return initialSpeed + (CGFloat(score) * 2.0)
    }
    
    func getMeteorChance() -> CGFloat {
        // Starts at 10% (0.1). Goes up by 1% (0.01) per score. Capped at 50% (0.5).
        let calculatedChance = 0.1 + (CGFloat(score) * 0.01)
        return min(calculatedChance, 0.5)
    }
}

// 6. Campaign Mode Logic
class CampaignDirector: GameModeDirector {
    var score = 0
    var spawnCount = 0
    let levels: [Level]
    var currentLevelIndex: Int
    
    let possibleTextures = ["planet-earth", "planet-mars"]
    
    init(levelIndex: Int = 0) {
        self.levels = LevelLoader.loadLevels()
        self.currentLevelIndex = levelIndex
    }
    
    var currentLevel: Level? {
        guard currentLevelIndex < levels.count else { return nil }
        return levels[currentLevelIndex]
    }

    func generateNextObject() -> SpawnableObject? {
        let randomRadius = CGFloat.random(in: 40...70)
        let randomImage = possibleTextures.randomElement()
        
        // Use the difficulty modifier from the JSON to make planets spin faster
        let difficulty = currentLevel?.difficultyModifier ?? 1.0
        let curve = CurveFactory.generateRandomWave()
        
        // If score hits planetAmount, the next spawn should be a SpaceStation (Level End)
        if let level = currentLevel, self.spawnCount >= level.planetAmount {
            
            if self.spawnCount >= level.planetAmount + 1 {
                return nil
            }
            
            self.spawnCount += 1
            return .spaceStation(radius: 80)
        }
        
        self.spawnCount += 1
        
        return .planet(radius: randomRadius,
                       speedMultiplier: difficulty,
                       curve: curve,
                       imagePath: randomImage)
    }
    
    func getBlackHoleSpeed() -> CGFloat {
        let initialSpeed: CGFloat = 30.0
        let difficulty = currentLevel?.difficultyModifier ?? 1.0
                
        // Multiplier: scales up by 5 per point, accelerated by difficulty
        let calculatedSpeed = initialSpeed + (CGFloat(score) * 5.0 * difficulty)
        
        let maxSpeedCap = initialSpeed * 3.0 // Never go faster than 3x starting speed
        
        // Use min to cap the speed
        return min(calculatedSpeed, maxSpeedCap)
    }
    
    func getMeteorChance() -> CGFloat {
        return currentLevel?.meteorChance ?? 0.0
    }
}
