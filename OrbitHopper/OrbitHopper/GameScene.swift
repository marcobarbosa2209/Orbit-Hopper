//
//  GameScene.swift
//  OrbitHopper
//
//  Created by Marco Barbosa on 07/05/2026.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var ship: ShipNode!
    var previousPlanet: PlanetNode?
    var currentPlanet: PlanetNode!
    let cameraNode = SKCameraNode()
    
    override func didMove(to view: SKView) {
        // 1. Setup World
        self.backgroundColor = .black
        self.physicsWorld.gravity = .zero
        self.physicsWorld.contactDelegate = self
        
        // 2. Setup Camera
        self.camera = cameraNode
        
        // 2.1 Setup Background as child of camera
        let background = SKSpriteNode(imageNamed: "StaticBackground")
        background.zPosition = -100
        cameraNode.addChild(background)

        addChild(cameraNode)
        
        // 3. Spawn Initial Planet
        currentPlanet = PlanetNode(radius: 60, imagePath: "planet-earth")
        currentPlanet.position = CGPoint(x: view.bounds.minX, y: view.bounds.minY + 100)
        addChild(currentPlanet)
        
        // 4. Spawn a Target Planet Above it
        let targetPlanet = PlanetNode(radius: 50, imagePath: "planet-mars")
        targetPlanet.position = CGPoint(x: view.bounds.minX, y: view.bounds.minY - 150)
        addChild(targetPlanet)
        
        // 5. Spawn Ship and attach to the first planet
        ship = ShipNode(radius: 10)
        attachShip(to: currentPlanet, atLocalPosition: CGPoint(x: 0, y: 70))
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Make camera smoothly follow the ship
        cameraNode.position.y = ship.parent === self ? ship.position.y : currentPlanet.position.y
    
        // 1. Only check bounds if the ship is flying
        if ship.parent === self {
            
            let screenWidth = self.size.width
            
            let leftEdge = currentPlanet.position.x - (screenWidth / 2) - 50
            let rightEdge = currentPlanet.position.x + (screenWidth / 2) + 50
            
            if(ship.position.x < leftEdge || ship.position.x > rightEdge) {
                
                // Calculate the Y distance of the planet to spawn the ship on the edge
                let resetDistance = currentPlanet.radius + ship.radius
                
                // Teleport back to the exact planet it just launched from
                attachShip(to: currentPlanet, atLocalPosition: CGPoint(x: 0, y: resetDistance))
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        launchShip()
    }
    
    // MARK: - Core Mechanics
    func attachShip(to planet: PlanetNode, atLocalPosition localPos: CGPoint? = nil) {
        // Stop physics movement
        ship.physicsBody?.velocity = .zero
        ship.removeFromParent()
        
        // Add ship as a CHILD of the planet.
        planet.addChild(ship)
        
        if let pos = localPos {
            ship.position = pos
        }
        
        // Update our tracker
        currentPlanet = planet
    }
    
    func launchShip() {
        // Only launch if attached to a planet
        guard ship.parent is PlanetNode else { return }
        
        // 1. Get the ship's current position in the scene
        let shipScenePos = currentPlanet.convert(ship.position, to: self)
        
        // 2. Calculate launch direction
        let dx = shipScenePos.x - currentPlanet.position.x
        let dy = shipScenePos.y - currentPlanet.position.y
        let distance = sqrt(dx*dx + dy*dy)
        let direction = CGVector(dx: dx / distance, dy: dy / distance)
        
        // 3. Move ship from planet's coordinate space back to the scene's space
        ship.removeFromParent()
        self.addChild(ship)
        ship.position = shipScenePos
        
        // 4. Apply force 
        let launchForce: CGFloat = 8
        ship.physicsBody?.applyImpulse(CGVector(dx: direction.dx * launchForce, dy: direction.dy * launchForce))
        
        previousPlanet = currentPlanet
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Figure out which body is the ship and which is the planet
        let bodyA = contact.bodyA.categoryBitMask
        let bodyB = contact.bodyB.categoryBitMask
        
        let planetNode: PlanetNode?
        
        if bodyA == PhysicsCategory.ship && bodyB == PhysicsCategory.planet {
            planetNode = contact.bodyB.node as? PlanetNode
        } else if bodyB == PhysicsCategory.ship && bodyA == PhysicsCategory.planet {
            planetNode = contact.bodyA.node as? PlanetNode
        } else { return }
        
        // If we hit a new planet, attach to it
        if let newPlanet = planetNode, newPlanet != currentPlanet {
            
            // 1. Get the raw local position (which might be overlapping or messy)
            let rawLocalPos = newPlanet.convert(ship.position, from: self)
            
            // 2. Find the exact angle of the ship from the planet's center using atan2
            let angle = atan2(rawLocalPos.y, rawLocalPos.x)
            
            // 3. Calculate the perfect surface distance
            let perfectDistance = newPlanet.radius + ship.radius
            
            // 4. Use Trig to find the exact X and Y coordinates on the edge
            let perfectLocalPos = CGPoint(
                x: cos(angle) * perfectDistance,
                y: sin(angle) * perfectDistance
            )
            
            // 5. Queue the attachment for the end of the frame
            self.run(SKAction.run {
                self.attachShip(to: newPlanet, atLocalPosition: perfectLocalPos)
            })
        }
    }
}

