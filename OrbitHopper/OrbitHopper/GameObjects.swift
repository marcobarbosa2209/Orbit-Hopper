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
}

// MARK: - Planet Node
class PlanetNode: SKShapeNode {
    
    let radius: CGFloat
    let imagePath: String?
    
    init(radius: CGFloat, imagePath: String? = nil) {
        self.radius = radius
        self.imagePath = imagePath
        super.init()
        
        // 1. Visuals: Draw a circle
        let circle = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        self.path = circle
        
        // 2. Apply Texture OR Color
        if let path = imagePath {
            // A. Create the Crop Node
            let cropNode = SKCropNode()
            
            // B. Create the mask shape.
            let mask = SKShapeNode(circleOfRadius: radius)
            mask.fillColor = .white
            mask.strokeColor = .clear
            cropNode.maskNode = mask
            
            // C. Create the actual Earth sprite and put it INSIDE the crop node
            let sprite = SKSpriteNode(imageNamed: path)
            sprite.size = CGSize(width: radius * 2, height: radius * 2)
            cropNode.addChild(sprite)
            
            // D. Add the Crop Node to the Planet
            self.addChild(cropNode)
            
        } else {
            // Fallback if no image is provided
            self.fillColor = .systemPurple
        }
        
        // 3. Physics: Add a static collider
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.categoryBitMask = PhysicsCategory.planet
        
        // 4. Action: Make it spin forever
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 4.0)
        self.run(SKAction.repeatForever(spin))
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
