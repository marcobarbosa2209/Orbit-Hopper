//
//  GameObjects.swift
//  OrbitHopper
//
//  Created by Marco Barbosa on 07/05/2026.
//

import SpriteKit

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none: UInt32   = 0
    static let ship: UInt32   = 0b1    // 1
    static let planet: UInt32 = 0b10   // 2
    static let blackHole: UInt32 = 0b100 // 4
}

// MARK: - Parent Class
class InteractableNode: SKShapeNode {
    let radius: CGFloat
    let sequenceIndex: Int
    
    init(radius: CGFloat, sequenceIndex: Int) {
        self.radius = radius
        self.sequenceIndex = sequenceIndex
        super.init()
        
        // Base Visuals
        let circle = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        self.path = circle
        self.strokeColor = .white
        
        // Base Physics (Shared by Planets, Stations, etc.)
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius * 1.1)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.categoryBitMask = PhysicsCategory.planet
        
        self.zPosition = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Planet Node
class PlanetNode: InteractableNode {
    
    init(radius: CGFloat, speedMultiplier: CGFloat, curve: @escaping RotationCurve, imagePath: String? = nil, sequenceIndex: Int) {
            super.init(radius: radius, sequenceIndex: sequenceIndex)
        
        // 1. Visuals: Draw a circle
        let circle = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        self.path = circle
        
        // 2. Apply Texture OR Color
        if let imagePath, !imagePath.isEmpty {
            // A. Create the Crop Node
            let cropNode = SKCropNode()
            
            // B. Create the mask shape.
            let mask = SKShapeNode(circleOfRadius: radius)
            mask.fillColor = .white
            mask.strokeColor = .clear
            cropNode.maskNode = mask
            
            // C. Create the actual Earth sprite and put it INSIDE the crop node
            let sprite = SKSpriteNode(imageNamed: imagePath)
            sprite.size = CGSize(width: radius * 2, height: radius * 2)
            cropNode.addChild(sprite)
            
            // D. Add the Crop Node to the Planet
            self.addChild(cropNode)
            
        } else {
            // Fallback if no image is provided
            self.fillColor = .systemPurple
        }
        
        // 3. Calculate the Math Rotation
        var previousTime: CGFloat = 0
        
        // Half the planets have counter clockwise rotation
        let ccwRotation = CGFloat.random(in: 0...1) > 0.5
        
        // 4. Spin planet "infinitely" (~11 days)
        let dynamicSpin = SKAction.customAction(withDuration: 1_000_000.0) { node, elapsedTime in
            let dt = elapsedTime - previousTime
            previousTime = elapsedTime
            
            let currentSpeed = curve(elapsedTime) * (ccwRotation ? -1 : 1)
            node.zRotation += currentSpeed * speedMultiplier * dt
        }
        
        self.run(dynamicSpin)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Ship Node
class ShipNode: SKShapeNode {
    
    let radius: CGFloat
    
    init(radius: CGFloat) {
        self.radius = radius
        super.init()
        
        // 1. Visuals: Draw a small circle for the ship
        let circle = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        self.path = circle
        self.fillColor = .cyan
        
        // 2. Physics: Dynamic collider
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.categoryBitMask = PhysicsCategory.ship
        
        // Tell SpriteKit to notify us when Ship hits a Planet
        self.physicsBody?.contactTestBitMask = PhysicsCategory.planet
        self.physicsBody?.collisionBitMask = PhysicsCategory.none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Space Station Node
class SpaceStationNode: InteractableNode {
    
    override init(radius: CGFloat, sequenceIndex: Int) {
        super.init(radius: radius, sequenceIndex: sequenceIndex)
        self.fillColor = .systemGreen
        
        // Space stations just rotate slowly and predictably
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 6.0)
        self.run(SKAction.repeatForever(spin))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Levels Class
class Level: Codable {
    let planetAmount: Int
    let difficultyModifier: CGFloat
    let meteorChance: CGFloat
    let galaxyName: String

    init(planetAmount: Int, difficultyModifier: CGFloat, meteorChance: CGFloat, galaxyName: String) {
        self.planetAmount = planetAmount
        self.difficultyModifier = difficultyModifier
        self.meteorChance = meteorChance
        self.galaxyName = galaxyName
    }
}

// Helper struct to load levels
struct LevelLoader {
    static func loadLevels() -> [Level] {
        // 1. Locate file
        guard let url = Bundle.main.url(forResource: "Levels", withExtension: "json") else {
            print("❌ RESOURCE NOT FOUND: Make sure Levels.json is in the left sidebar and 'Copy Bundle Resources'")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let levels = try decoder.decode([Level].self, from: data)
            print("✅ SUCCESS: Loaded \(levels.count) levels.")
            return levels
        } catch let decodingError as DecodingError {
            // This will tell you exactly which comma or bracket is missing in your JSON
            print("❌ JSON DECODING ERROR: \(decodingError)")
            return []
        } catch {
            print("❌ UNKNOWN ERROR: \(error)")
            return []
        }
    }
}

// MARK: - Black Hole Node
class BlackHoleNode: SKShapeNode {
    let radius: CGFloat
    let imagePath: String = "black-hole"
    
    init(radius: CGFloat) {
        self.radius = radius
        super.init()
        
        // 1. Visuals: Draw a circle
        let circle = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        self.path = circle
        
        // self.strokeColor = .clear TODO: Remove this line further into development
        
        // 2. Apply Texture OR Color
        if !imagePath.isEmpty {
            // A. Create the Crop Node
            let cropNode = SKCropNode()
            
            // B. Create the mask shape.
            let mask = SKShapeNode(circleOfRadius: radius)
            mask.fillColor = .white
            mask.strokeColor = .clear
            cropNode.maskNode = mask
            
            // C. Create the actual Earth sprite and put it INSIDE the crop node
            let sprite = SKSpriteNode(imageNamed: imagePath)
            sprite.size = CGSize(width: radius * 2, height: radius * 2)
            cropNode.addChild(sprite)
            
            // D. Add the Crop Node to the Planet
            self.addChild(cropNode)
            
        } else {
            // Fallback if no image is provided
            self.fillColor = .systemPurple
        }
        
        
        // 2. Physics: Triggers collisions
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.categoryBitMask = PhysicsCategory.blackHole
        self.physicsBody?.contactTestBitMask = PhysicsCategory.ship
        
        // 3. Action: Slowly rotate
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 15.0)
        self.run(SKAction.repeatForever(spin))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
