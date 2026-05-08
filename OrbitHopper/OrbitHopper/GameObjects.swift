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
    static let meteor: UInt32 = 0b1000 // 8
}

// MARK: - Parent Class
class InteractableNode: SKShapeNode {
    let radius: CGFloat
    let sequenceIndex: Int
    let colliderRadius: CGFloat
    
    init(radius: CGFloat, sequenceIndex: Int, colliderRadius: CGFloat = -1) {
        self.radius = radius
        self.sequenceIndex = sequenceIndex
        self.colliderRadius = colliderRadius
        super.init()
        
        // Base Visuals
        let circle = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        self.path = circle
        self.strokeColor = .white
        
        // Base Physics (Shared by Planets, Stations, etc.)
        self.physicsBody = SKPhysicsBody(circleOfRadius: colliderRadius > 0 ? colliderRadius : radius * 1.1)
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
    
    init(radius: CGFloat, speedMultiplier: CGFloat, colliderRadius: CGFloat, curve: @escaping RotationCurve, imagePath: String? = nil, hexColor: String? = nil, sequenceIndex: Int) {
            super.init(radius: radius, sequenceIndex: sequenceIndex, colliderRadius: colliderRadius)
        
        // 1. Visuals: Draw a circle
        let circle = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        self.path = circle
        self.strokeColor = .clear
        
        // 1.1 Add glow effect
        if let hexString = hexColor, let color = UIColor(hex: hexString) {
            let glowTexture = SKTexture.planetGlow(planetRadius: radius, color: color)
            let glowNode = SKSpriteNode(texture: glowTexture)
            glowNode.zPosition = -1
            self.addChild(glowNode)
        }
        
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

// MARK: - Level Data Models
struct PlanetConfig: Codable {
    let imageUrl: String
    let radius: CGFloat
    let colliderRadius: CGFloat?
    let hexColor: String?
    
    // default to the visual radius if colliderRadius is missing
    var effectiveColliderRadius: CGFloat {
        return colliderRadius ?? radius
    }
}

// MARK: - Ship Node
class ShipNode: SKShapeNode {
    
    let radius: CGFloat
    
    init(radius: CGFloat) {
        self.radius = radius
        super.init()
        
        // 1. Visuals: Draw a small circle for the ship
        self.strokeColor = .clear
        let sprite = SKSpriteNode(imageNamed: "rocket")
        sprite.size = CGSize(width: radius * 2, height: radius * 2)
        self.addChild(sprite)
        
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
    
    override init(radius: CGFloat, sequenceIndex: Int, colliderRadius: CGFloat = -1) {
        super.init(radius: radius, sequenceIndex: sequenceIndex)
        self.strokeColor = .clear
        let sprite = SKSpriteNode(imageNamed: "space-station")
        sprite.size = CGSize(width: radius * 2, height: radius * 2)
        self.addChild(sprite)
        
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
    let difficultyModifier: CGFloat
    let meteorChance: CGFloat
    let galaxyName: String
    let planets: [PlanetConfig]

    init(difficultyModifier: CGFloat, meteorChance: CGFloat, galaxyName: String, planets: [PlanetConfig]) {
        self.planets = planets
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
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let levels = try decoder.decode([Level].self, from: data)
            print("Loaded \(levels.count) levels.")
            return levels
        } catch let decodingError as DecodingError {
            // This will tell you exactly which comma or bracket is missing in your JSON
            print("JSON DECODING ERROR: \(decodingError)")
            return []
        } catch {
            print("UNKNOWN ERROR: \(error)")
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
        
        self.strokeColor = .clear
        
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
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius * 0.8)
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

// MARK: - Meteor Node
class MeteorNode: SKShapeNode {
    
    init(radius: CGFloat, imagePath: String = "meteor") {
        super.init()
        
        // 1. Visuals
        let circle = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        self.path = circle
        self.strokeColor = .clear
        self.zPosition = 15
        
        // 1.1 Add glow effect
        let glowTexture = SKTexture.planetGlow(planetRadius: radius, color: UIColor(hex: "#A8A8A8") ?? .white)
        let glowNode = SKSpriteNode(texture: glowTexture)
        glowNode.zPosition = -1
        self.addChild(glowNode)
    
        
        // Apply Texture
        let cropNode = SKCropNode()
        let mask = SKShapeNode(circleOfRadius: radius)
        mask.fillColor = .white
        mask.strokeColor = .clear
        cropNode.maskNode = mask
        
        let sprite = SKSpriteNode(imageNamed: imagePath)
        sprite.size = CGSize(width: radius * 2, height: radius * 2)
        cropNode.addChild(sprite)
        self.addChild(cropNode)
    
        
        // 2. Physics - Meteor doesn't get pushed, but detects the ship
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.categoryBitMask = PhysicsCategory.meteor
        self.physicsBody?.contactTestBitMask = PhysicsCategory.ship
        
        // 3. Spin forever
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 1.0)
        self.run(SKAction.repeatForever(spin))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Core Graphics & Color Helpers
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        guard hexSanitized.count == 6 else { return nil }
        self.init(red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgb & 0x0000FF) / 255.0,
                  alpha: 1.0)
    }
}

extension SKTexture {
    static func planetGlow(planetRadius: CGFloat, color: UIColor, radiusSize: CGFloat = 1.2) -> SKTexture {
        // Total radius is 1.1x the planet's radius
        let glowRadius = planetRadius * radiusSize
        let size = CGSize(width: glowRadius * 2, height: glowRadius * 2)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return SKTexture() }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let centerColor = color.withAlphaComponent(0.5).cgColor
        let edgeColor = color.withAlphaComponent(0.0).cgColor
        
        // Math to calculate the gradient
        let planetEdgeLocation = CGFloat(1.0 / radiusSize)
        
        let locations: [CGFloat] = [0.0, planetEdgeLocation, 1.0]
        let colors = [centerColor, centerColor, edgeColor] as CFArray
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return SKTexture() }
        
        let center = CGPoint(x: glowRadius, y: glowRadius)
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: glowRadius, options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image!)
    }
}
