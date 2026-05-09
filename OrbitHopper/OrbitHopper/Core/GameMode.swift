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
    case planet(radius: CGFloat, colliderRadius: CGFloat = -1, speedMultiplier: CGFloat, curve: RotationCurve, imagePath: String?, hexColor: String? = nil)
    case spaceStation(radius: CGFloat)
    // case meteor(radius: CGFloat, speed: CGVector)
}

// 4. The Blueprint for Game Modes
protocol GameModeDirector {
    var score: Int { get set }
    var planetsCleared: Int { get set }
    func generateNextObject() -> SpawnableObject?
    func getBlackHoleSpeed() -> CGFloat
    func getMeteorChance() -> CGFloat
}

// 5. Endless Mode Logic
class EndlessDirector: GameModeDirector {
    var score = 0
    var spawnCount = 0
    var planetsCleared = 0
    
    var allPlanetsPool: [PlanetConfig] = []
    var lastPlanet: PlanetConfig?
    
    init() {
        // Load all levels from the JSON
        let levels = LevelLoader.loadLevels()
        
        // flatMap to take all the arrays of planets inside the levels and squash them into one array
        self.allPlanetsPool = levels.flatMap { $0.planets }
        
        // In case the JSON fails to load, give it one default planet so it doesn't crash
        if self.allPlanetsPool.isEmpty {
            self.allPlanetsPool = [PlanetConfig(imageUrl: "planet-earth", radius: 40, colliderRadius: nil, hexColor: "#4B90E2")]
        }
    }
    
    func generateNextObject() -> SpawnableObject? {
        let constantChance = max(0.0, 1.0 - (CGFloat(score) * 0.025))
        let roll = CGFloat.random(in: 0.0...1.0)
        
        let curve: RotationCurve
        if roll <= constantChance {
            // constant rotation
            curve = CurveFactory.generateConstant(speed: 1.0)
        } else {
            // wave rotation
            curve = CurveFactory.generateRandomWave()
        }
        
        self.spawnCount += 1
        
        // Make sure we don't spawn the same planet twice
        var randomPlanet: PlanetConfig
        
        while true {
            randomPlanet = allPlanetsPool.randomElement()!
            
            if lastPlanet == nil || randomPlanet.imageUrl != lastPlanet!.imageUrl {
                lastPlanet = randomPlanet
                break
            } else {
                continue
            }
        }
                
        // Spawn planets from Levels.JSON data
        return .planet(radius: randomPlanet.radius,
                       colliderRadius: randomPlanet.effectiveColliderRadius,
                       speedMultiplier: 1.0,
                       curve: curve,
                       imagePath: randomPlanet.imageUrl,
                       hexColor: randomPlanet.hexColor)
    }
    
    func getBlackHoleSpeed() -> CGFloat {
        let initialSpeed: CGFloat = 30.0
        return initialSpeed + (CGFloat(planetsCleared) * 2.0)
    }
    
    func getMeteorChance() -> CGFloat {
        // Starts at 10% (0.1). Goes up by 1% (0.01) per score. Capped at 50% (0.5).
        let calculatedChance = 0.1 + (CGFloat(planetsCleared) * 0.01)
        return min(calculatedChance, 0.5)
    }
}

// 6. Campaign Mode Logic
class CampaignDirector: GameModeDirector {
    var score = 0
    var spawnCount = 0
    var planetsCleared = 0
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
        guard let level = currentLevel else { return nil }
        
        // Use the difficulty modifier from the JSON to make planets spin faster
        let difficulty = currentLevel?.difficultyModifier ?? 1.0
        
        // Rotation calculation
        let constantChance = max(0.0, 2.0 - difficulty)
        let roll = CGFloat.random(in: 0.0...1.0)
        
        let curve: RotationCurve
        if roll <= constantChance {
            curve = CurveFactory.generateConstant(speed: 1.0)
        } else {
            curve = CurveFactory.generateRandomWave()
        }
        
        // 1. Check if all the planets in the array have been spawned
        if self.spawnCount >= level.planets.count {
            
            // If we've already spawned the station, stop spawning
            if self.spawnCount >= level.planets.count + 1 {
                return nil
            }
            
            self.spawnCount += 1
            return .spaceStation(radius: 80)
        }
        
        // 2. Get the planet from JSON data
        let planetData = level.planets[self.spawnCount]
        
        self.spawnCount += 1
        
        // 3. Spawn it using the precise data from the JSON
        return .planet(radius: planetData.radius,
                       colliderRadius: planetData.effectiveColliderRadius,
                       speedMultiplier: difficulty,
                       curve: curve,
                       imagePath: planetData.imageUrl,
                       hexColor: planetData.hexColor)
    }
    
    func getBlackHoleSpeed() -> CGFloat {
        let initialSpeed: CGFloat = 30.0
        let difficulty = currentLevel?.difficultyModifier ?? 1.0
                
        // Multiplier: scales up by 5 per point, accelerated by difficulty
        let calculatedSpeed = initialSpeed + (CGFloat(planetsCleared) * 5.0 * difficulty)
        
        let maxSpeedCap = initialSpeed * 3.0 // Never go faster than 3x starting speed
        
        // Use min to cap the speed
        return min(calculatedSpeed, maxSpeedCap)
    }
    
    func getMeteorChance() -> CGFloat {
        return currentLevel?.meteorChance ?? 0.0
    }
}
