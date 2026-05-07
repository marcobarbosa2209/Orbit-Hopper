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
    
    init(radius: CGFloat) {
        self.radius = radius
        super.init()
        
        // 1. Visuals: Draw a circle
        let circle = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        self.path = circle
        self.fillColor = .systemPurple
        self.strokeColor = .white
        
        // 2. Physics: Add a static collider
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.categoryBitMask = PhysicsCategory.planet
        
        // 3. Action: Make it spin forever (Unity: Update -> transform.Rotate)
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
