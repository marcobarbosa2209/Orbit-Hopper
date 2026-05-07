//
//  GameScene.swift
//  OrbitHopper
//
//  Created by Marco Barbosa on 07/05/2026.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Ship
    var ship: ShipNode!
    
    // Camera
    let cameraNode = SKCameraNode()
    
    // UI
    var scoreLabel: SKLabelNode!
    
    // Game Mode
    var director: GameModeDirector!
    
    // Object Management
    var currentInteractable: InteractableNode!
    var highestSpawnY: CGFloat = 0
    var nextInteractable: InteractableNode?
    var objectsSpawnedCount: Int = 0
    
    // Black Hole Management
    var blackHole: BlackHoleNode!
    var lastUpdateTime: TimeInterval = 0
    
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
        
        // 2.2 Setup UI
        initializeUI(camera: cameraNode, view: self.view ?? SKView())
        
        // Initialize Game Mode
        director = EndlessDirector() // or CampaignDirector() for levels
        
        // Manually spawn the very first starting planet before the spawner has a reference point.
        let startConfig = director.generateNextObject()
        
        guard let startPlanet = makeInteractable(from: startConfig!, sequenceIndex: 0) as? PlanetNode else {
            fatalError("The initial object must be a PlanetNode.")
        }
        startPlanet.position = CGPoint(x: view.bounds.minX, y: view.bounds.minY + 150)
        addChild(startPlanet)
        
        currentInteractable = startPlanet
        highestSpawnY = startPlanet.position.y
        
        // Generate the first targets
        maintainPlanetBuffer()
        
        nextInteractable = self.children
            .compactMap { $0 as? InteractableNode }
            .filter { $0.position.y > startPlanet.position.y }
            .min(by: { $0.position.y < $1.position.y })
                
        // Spawn Ship
        ship = ShipNode(radius: 10)
        attachShip(to: currentInteractable, atLocalPosition: CGPoint(x: 0, y: startPlanet.radius + ship.radius))
        
        // Spawn Black Hole
        blackHole = BlackHoleNode(radius: 800)
        blackHole.position = CGPoint(x: view.bounds.minX, y: view.bounds.minY - blackHole.radius - 200)
        addChild(blackHole)
        
        // Frame the initial camera
        updateCamera(instant: true)
    }
    
    // MARK: - Spawner Logic
    private func makeInteractable(from config: SpawnableObject, sequenceIndex: Int) -> InteractableNode {
        switch config {
        case .planet(let radius, let speedMult, let curve, let imagePath):
            return PlanetNode(radius: radius, speedMultiplier: speedMult, curve: curve, imagePath: imagePath, sequenceIndex: sequenceIndex)
        case .spaceStation(let radius):
            return SpaceStationNode(radius: radius, sequenceIndex: sequenceIndex)
        }
    }
    
    func maintainPlanetBuffer() {
        // Create a safe runway of about 1200 pixels (roughly 3-4 planets ahead of player)
        let requiredBufferY = currentInteractable.position.y + 1200
        
        // Keep spawning until the highest planet is above the required buffer
        while highestSpawnY < requiredBufferY {
            
            // If the director returns nil (e.g. Campaign mode reached the end),
            // break the loop so there's no infinite loop
            guard let _ = spawnNextObject() else {
                break
            }
        }
    }
    
    func spawnNextObject() -> InteractableNode? {
        guard let config = director.generateNextObject() else { return nil }
        
        objectsSpawnedCount += 1
        
        let newObject = makeInteractable(from: config, sequenceIndex: objectsSpawnedCount)
        
        // 1. Ask the current planet for its location
        let prevObjectX = currentInteractable.position.x
        
        // 2. Define how far we can drift horizontally from the previous point (X-Variation).
        let xVariation: CGFloat = 200
        let randomXOffset = CGFloat.random(in: -xVariation...xVariation)
        let targetX = prevObjectX + randomXOffset
        
        // 3. Define the screen width. self.size.width will work well.
        let screenWidth = self.size.width
        let minX: CGFloat = 80
        let maxX = screenWidth - randomXOffset
        
        // Ensure the final position is always within [minX, maxX]
        let finalX = max(minX, min(maxX, targetX))
        
        // Place it from 250 to 300 pixels above the highest object
        let spawnY = highestSpawnY + CGFloat.random(in: 250...300)
        
        newObject.position = CGPoint(x: finalX, y: spawnY)
        addChild(newObject)
        
        highestSpawnY = spawnY
        
        return newObject
    }
    
    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        
        // Calculate Delta Time for smooth movement regardless of FPS
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // 1. Move black whole upwards
        let currentSpeed = director.getBlackHoleSpeed()
        blackHole.position.y += currentSpeed * CGFloat(dt)
        
        // Death check
        let blackHoleTopEdge = blackHole.position.y + blackHole.radius
        
        // Safely find where the ship is in the scene, even if it's attached to a planet
        let shipScenePos = ship.parent?.convert(ship.position, to: self) ?? ship.position
        
        if shipScenePos.y < blackHoleTopEdge {
            gameOver()
            return
        }
        
        // 2. Garbage Collection: Destroy planets swallowed by the Black Hole
        let killLine = blackHole.position.y + (blackHole.radius - 100)
        
        for node in self.children {
            if let interactable = node as? InteractableNode {
                if interactable.position.y < killLine {
                    interactable.removeFromParent()
                    print("Garbage Collected: Planet \(interactable.sequenceIndex)")
                }
            }
        }
        
        // 3. Only check bounds if the ship is flying
        if ship.parent === self {
            
            let screenWidth = self.size.width
            let screenHeight = self.size.height
            
            // X-Axis bounds
            let leftEdge = currentInteractable.position.x - (screenWidth / 2) - 50
            let rightEdge = currentInteractable.position.x + (screenWidth / 2) + 50
            
            // Y-Axis bounds
            let bottomEdge = cameraNode.position.y - (screenHeight / 2) - 50
            let topEdge = cameraNode.position.y + (screenHeight / 2) + 50
            
            let isOutOfBoundsX = ship.position.x < leftEdge || ship.position.x > rightEdge
            let isOutOfBoundsY = ship.position.y < bottomEdge || ship.position.y > topEdge
            
            if isOutOfBoundsX || isOutOfBoundsY {
                gameOver()
            }
        }
    }
    
    func gameOver() {
        // 1. Pause the scene so the player doesn't keep falling/triggering collisions
        self.isPaused = true
        
        // 2. Create a brand new, fresh copy of the game scene
        let newScene = GameScene(size: self.size)
        newScene.scaleMode = self.scaleMode
        
        // 3. Restart the game with a cool cinematic fade
        let transition = SKTransition.fade(with: .black, duration: 1.0)
        self.view?.presentScene(newScene, transition: transition)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        launchShip()
    }
    
    // MARK: - Camera Control
    func updateCamera(instant: Bool = false) {
        // Calculate the ideal midpoint
        let targetY = (currentInteractable.position.y + (nextInteractable?.position.y ?? currentInteractable.position.y)) / 2
        let targetX = (currentInteractable.position.x + (nextInteractable?.position.x ?? currentInteractable.position.x)) / 2
        let idealTargetPos = CGPoint(x: targetX, y: targetY)
        
        // Stop any old camera movements
        cameraNode.removeAllActions()
        
        // If instant, set camera's position right away (first frame)
        if(instant == true) {
            cameraNode.position = idealTargetPos;
            return
        }
        
        // Create a 0.8-second movement (adjust this number to make it faster/slower)
        let moveCamera = SKAction.move(to: idealTargetPos, duration: 0.3)
        
        // This is the magic line that gives you the Cubic / Ease-In-Out feel!
        moveCamera.timingMode = .easeInEaseOut
        
        cameraNode.run(moveCamera)
    }
    
    // MARK: - Core Mechanics
    func attachShip(to interactable: InteractableNode, atLocalPosition localPos: CGPoint? = nil) {
        
        // Stop physics movement
        ship.physicsBody = nil
        ship.removeFromParent()
        
        // Add ship as a child of the planet
        interactable.addChild(ship)
        
        if let pos = localPos {
            ship.position = pos
        }
        
        // Update our tracker
        currentInteractable = interactable
    }
    
    func launchShip() {
        // Only launch if attached to a planet
        guard ship.parent is InteractableNode else { return }
        
        // 1. Get the ship's current position in the scene
        let shipScenePos = currentInteractable.convert(ship.position, to: self)
        
        // 2. Calculate launch direction
        let dx = shipScenePos.x - currentInteractable.position.x
        let dy = shipScenePos.y - currentInteractable.position.y
        let distance = sqrt(dx*dx + dy*dy)
        let direction = CGVector(dx: dx / distance, dy: dy / distance)
        
        // 3. Move ship from planet's coordinate space back to the scene's space
        ship.removeFromParent()
        
        // Set position before adding to the scene
        ship.position = shipScenePos
        
        // 4. Apply force
        self.addChild(ship)
        
        ship.physicsBody = SKPhysicsBody(circleOfRadius: ship.radius)
        ship.physicsBody?.isDynamic = true
        ship.physicsBody?.categoryBitMask = PhysicsCategory.ship
        ship.physicsBody?.contactTestBitMask = PhysicsCategory.planet
        ship.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        let launchForce: CGFloat = 8
        ship.physicsBody?.applyImpulse(CGVector(dx: direction.dx * launchForce, dy: direction.dy * launchForce))
    }
    
    // MARK: - Collision Routing
    func didBegin(_ contact: SKPhysicsContact) {
        
        let bodyA = contact.bodyA.categoryBitMask
        let bodyB = contact.bodyB.categoryBitMask
        
        // 1. Ensure the ship is involved in this collision
        let isShipInvolved = (bodyA == PhysicsCategory.ship || bodyB == PhysicsCategory.ship)
        guard isShipInvolved else { return }
        
        // 2. Identify the 'other' node that the ship collided with
        let otherNode = (bodyA == PhysicsCategory.ship) ? contact.bodyB.node : contact.bodyA.node
        let otherCategory = (bodyA == PhysicsCategory.ship) ? bodyB : bodyA
        
        // 3. Route the collision based on category or class type
        if otherCategory == PhysicsCategory.blackHole {
            handleBlackHoleCollision()
            return
        }
        
        if let planet = otherNode as? PlanetNode {
            handlePlanetCollision(planet)
        }
        else if let station = otherNode as? SpaceStationNode {
            handleStationCollision(station)
        }
        else {
            // if let meteor = otherNode as? MeteorNode {
            //     handleMeteorCollision(meteor)
            // }
        }
    }
    
    // MARK: - Specific Collision Handlers
    func handleBlackHoleCollision() {
        // The void caught the player
        gameOver()
    }
    
    func handleMeteorCollision(_ meteor: SKNode) {
        // TODO: Implement meteor logic (e.g., bounce off, take damage, or game over)
        print("Hit a meteor!")
    }
    
    func handlePlanetCollision(_ planet: PlanetNode) {
        // Don't land on the planet we are already attached to
        guard planet != currentInteractable else { return }
        
        // 1. Score point if we moved forward
        if planet.sequenceIndex > director.score {
            director.score = planet.sequenceIndex
            
            updateScoreLabel(score: director.score)
        }
        
        // Update the tracker
        nextInteractable = self.children
            .compactMap { $0 as? InteractableNode }
            .filter { $0.position.y > planet.position.y }
            .min(by: { $0.position.y < $1.position.y })
        
        // 2. Do Math to snap perfectly to the edge
        let rawLocalPos = planet.convert(ship.position, from: self)
        let angle = atan2(rawLocalPos.y, rawLocalPos.x)
        
        // 3. Calculate the perfect surface distance
        let perfectDistance = planet.radius + ship.radius
        
        // 4. Use Trig to find the exact X and Y coordinates on the edge
        let perfectLocalPos = CGPoint(
            x: cos(angle) * perfectDistance,
            y: sin(angle) * perfectDistance
        )
        
        // 5. Queue the attachment for the end of the frame
        self.run(SKAction.run {
            self.attachShip(to: planet, atLocalPosition: perfectLocalPos)
            self.maintainPlanetBuffer()
            self.updateCamera()
        })
    }
    
    func handleStationCollision(_ station: SpaceStationNode) {
        // Don't land on the station if we are already attached to it
        guard station != currentInteractable else { return }
        
        // TODO: Update station landing logic to show Win Sequence
        
        // 1. Score point if we moved forward
        if station.sequenceIndex > director.score {
            director.score = station.sequenceIndex
            scoreLabel.text = "Score: \(director.score)"
        }
        
        // Update the tracker
        nextInteractable = self.children
            .compactMap { $0 as? InteractableNode }
            .filter { $0.position.y > station.position.y }
            .min(by: { $0.position.y < $1.position.y })
        
        // 2. Do Math to snap perfectly to the edge
        let rawLocalPos = station.convert(ship.position, from: self)
        let angle = atan2(rawLocalPos.y, rawLocalPos.x)
        
        // 3. Calculate the perfect surface distance
        let perfectDistance = station.radius + ship.radius
        
        // 4. Use Trig to find the exact X and Y coordinates on the edge
        let perfectLocalPos = CGPoint(
            x: cos(angle) * perfectDistance,
            y: sin(angle) * perfectDistance
        )
        
        // 5. Queue the attachment for the end of the frame
        self.run(SKAction.run {
            self.attachShip(to: station, atLocalPosition: perfectLocalPos)
            self.maintainPlanetBuffer()
            self.updateCamera()
        })
    }
    
    // MARK: - UI functions
    func initializeUI(camera: SKCameraNode, view: SKView) {
        scoreLabel = SKLabelNode(fontNamed: "JetBrainsMono-Bold")
        scoreLabel.text = "0"
        scoreLabel.fontSize = 96
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 1
        scoreLabel.alpha = 0.2
        
        // Use 'view.bounds' so it perfectly matches user's phone screen dimensions
        let xPos = view.safeAreaInsets.left
        let yPos = view.safeAreaInsets.top + 120
        scoreLabel.position = CGPoint(x: xPos, y: yPos)
        
        // Add it to the camera
        cameraNode.addChild(scoreLabel)

        addChild(cameraNode)
    }
    
    func updateScoreLabel (score: Int) {
        scoreLabel.text = "\(score)"
    }
}
