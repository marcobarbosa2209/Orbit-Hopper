//
//  GameScene.swift
//  OrbitHopper
//
//  Created by Marco Barbosa on 07/05/2026.
//

import SpriteKit
import Combine


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var gameState: GameState?
    
    // 1. Ship and player properties
    var ship: ShipNode!
    
    // 2. Camera states and framing
    let cameraNode = SKCameraNode()
    enum CameraState { case framingPlanets, followingShip, staticDeath }
    var cameraState: CameraState = .framingPlanets
    
    // 3. Combo and scoring logic
    var scoreMultiplier: Int = 1
    var comboEndTime: TimeInterval = 0
    
    // 4. Background and parallax elements
    var backgroundStars: [StarData] = []
    var lastCameraY: CGFloat = 0
    var nebulaNode: SKSpriteNode!
    
    struct StarData {
        let node: SKSpriteNode
        let parallaxSpeed: CGFloat
    }
    
    let themeColor = UIColor(red: 0.45, green: 0.95, blue: 0.90, alpha: 1.0)
    
    // 5. Reactive observers
    var cancellables = Set<AnyCancellable>()
    
    // 6. Game Mode management
    var director: GameModeDirector!
    
    // 7. Object and spawn management
    var currentInteractable: InteractableNode!
    var highestSpawnY: CGFloat = 0
    var highestSpawnX: CGFloat = 0
    var nextInteractable: InteractableNode?
    var objectsSpawnedCount: Int = 0
    
    // 8. Black Hole tracking
    var blackHole: BlackHoleNode!
    var lastUpdateTime: TimeInterval = 0
    
    override func didMove(to view: SKView) {
        
        // 1. Setup physics world
        self.backgroundColor = .black
        self.physicsWorld.gravity = .zero
        self.physicsWorld.contactDelegate = self
        
        // 2. Configure camera node
        self.camera = cameraNode
        self.addChild(cameraNode)
        
        // 3. Initialize background stars and nebula
        initializeStars(view: view)
        
        // 4. Setup nebula background shader
        nebulaNode = SKSpriteNode(color: .black, size: self.size)
        let nebulaShader = SKShader(fileNamed: "Nebula.fsh")
        let cameraOffsetUniform = SKUniform(name: "u_camera_offset", vectorFloat2: SIMD2<Float>(0, 0))
        nebulaShader.uniforms = [cameraOffsetUniform]
        
        nebulaNode.shader = nebulaShader
        nebulaNode.zPosition = -105
        cameraNode.addChild(nebulaNode)
        
        // 5. Initialize Game Mode (Campaign or Endless)
        director = EndlessDirector()
        
        // 6. Update level title for the UI
        if let campaign = director as? CampaignDirector, let level = campaign.currentLevel {
                let levelNumber = String(format: "%03d", campaign.currentLevelIndex + 1)
                gameState?.levelTitle = "\(level.galaxyName.uppercased()) // LEVEL \(levelNumber)"
            } else {
                gameState?.levelTitle = "ENDLESS MODE // HI-SCORE"
            }
        
        // 7. Spawn initial starting planet
        let startConfig = director.generateNextObject()
        guard let startPlanet = makeInteractable(from: startConfig!, sequenceIndex: 0) as? PlanetNode else {
            fatalError("The initial object must be a PlanetNode.")
        }
        startPlanet.position = CGPoint(x: view.bounds.minX, y: view.bounds.minY + 150)
        addChild(startPlanet)
        
        currentInteractable = startPlanet
        highestSpawnY = startPlanet.position.y
        highestSpawnX = startPlanet.position.x
        
        // 8. Maintain initial planet runway
        maintainPlanetBuffer()
        nextInteractable = self.children
            .compactMap { $0 as? InteractableNode }
            .filter { $0.position.y > startPlanet.position.y }
            .min(by: { $0.position.y < $1.position.y })
                
        // 9. Spawn ship and attach to starting planet
        ship = ShipNode(radius: 20)
        attachShip(to: currentInteractable, atLocalPosition: CGPoint(x: 0, y: startPlanet.colliderRadius + ship.radius))
        
        // 10. Spawn Black Hole at the bottom
        blackHole = BlackHoleNode(radius: 600)
        blackHole.position = CGPoint(x: view.bounds.minX, y: view.bounds.minY - blackHole.radius - 200)
        addChild(blackHole)
        
        // 11. Initial camera alignment
        updateCamera(instant: true)
        lastCameraY = cameraNode.position.y
        
        // 12. Listen for resurrection requests
        gameState?.$triggerResurrection
            .receive(on: RunLoop.main)
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.gameState?.triggerResurrection = false
                self.resurrectPlayer()
            }
            .store(in: &cancellables)
    }
    
    // 1. Spawner Logic
    private func makeInteractable(from config: SpawnableObject, sequenceIndex: Int) -> InteractableNode {
        switch config {
        case .planet(let radius, let colliderRadius, let speedMult, let curve, let imagePath, let hexColor):
            return PlanetNode(radius: radius, speedMultiplier: speedMult, colliderRadius: colliderRadius, curve: curve, imagePath: imagePath, hexColor: hexColor, sequenceIndex: sequenceIndex)
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
        
        // 1. Define how far the spawn can drift horizontally from the previous spawn point.
        let xVariation: CGFloat = 180
        let randomXOffset = CGFloat.random(in: -xVariation...xVariation)
         
        // 2. Add the offset to the last spawned X coordinate
        let finalX = highestSpawnX + randomXOffset
        
        // 3. Place it from 250 to 300 pixels above the highest object
        let spawnY = highestSpawnY + CGFloat.random(in: 250...300)
        
        newObject.position = CGPoint(x: finalX, y: spawnY)
        addChild(newObject)
        
        // 4. Update the highest trackers so the next planet in the loop builds off this one
        highestSpawnY = spawnY
        highestSpawnX = finalX
        
        return newObject
    }
    
    // 2. Meteor System
    func trySpawnMeteor() {
        let chance = director.getMeteorChance()
        let roll = CGFloat.random(in: 0.0...1.0)
        
        // 1. Did the meteor trigger?
        guard roll <= chance else { return }
        guard let next = nextInteractable else { return }
        guard let current = currentInteractable else { return }
        
        // 2. Calculate the exact midpoint between planets
        let midY = (current.position.y + next.position.y) / 2
        let midX = (current.position.x + next.position.x) / 2
        
        // 3. Decide if it flies Left-to-Right or Right-to-Left
        let goRight = Bool.random()
        let screenWidth = self.size.width
        
        // Use the camera's X position to find the true edges of the screen
        let leftEdge = midX - (screenWidth / 2) - 150
        let rightEdge = midX + (screenWidth / 2) + 150
        
        let startX: CGFloat = goRight ? leftEdge : rightEdge
        let endX:   CGFloat = goRight ? rightEdge : leftEdge
        
        // Add a slight angle by varying the Y randomly
        let startY = midY + CGFloat.random(in: -40...40)
        let endY = midY + CGFloat.random(in: -40...40)
        
        let startPoint = CGPoint(x: startX, y: startY)
        let endPoint = CGPoint(x: endX, y: endY)
        
        // Visuals
        // 4. Draw the Warning Path (A dashed red line)
        let path = CGMutablePath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        
        let lineNode = SKShapeNode()
        // Convert to dashed line
        lineNode.path = path.copy(dashingWithPhase: 0, lengths: [15, 10])
        lineNode.strokeColor = themeColor
        lineNode.lineWidth = 2
        lineNode.zPosition = 5
        self.addChild(lineNode)
        
        // 5. The Flashing Alert Icon
        let alertIcon = SKSpriteNode(imageNamed: "meteor-alert")
        alertIcon.size = CGSize(width: 40, height: 40)
        
        let visibleLeftEdge = midX - (screenWidth / 2)
        let visibleRightEdge = midX + (screenWidth / 2)
        
        let padding: CGFloat = 16 + (alertIcon.size.width / 2)
        
        let iconX = goRight ? (visibleLeftEdge + padding) : (visibleRightEdge - padding)
                
        alertIcon.position = CGPoint(x: iconX, y: startY)
        alertIcon.zPosition = 100
        self.addChild(alertIcon)
        
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.2),
            SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        ])
        alertIcon.run(SKAction.repeatForever(pulse))
        
        // Launch sequence
        // 6. Wait X seconds, destroy UI, and launch the Meteor
        let secondsToAppear = CGFloat.random(in:1.0...3.0)
        let waitSequence = SKAction.wait(forDuration: secondsToAppear)
        
        let fireMeteor = SKAction.run {
            lineNode.removeFromParent()
            alertIcon.removeFromParent()
            
            let radius = CGFloat.random(in: 15...30)
            let meteor = MeteorNode(radius: radius, imagePath: "meteor")
            meteor.position = startPoint
            
            self.addChild(meteor)
            
            // Fly across the screen at random speed
            let meteorSpeed = CGFloat.random(in:0.5...1.5)
            let fly = SKAction.move(to: endPoint, duration: meteorSpeed)
            let cleanup = SKAction.removeFromParent()
            
            meteor.run(SKAction.sequence([fly, cleanup]))
        }
        
        self.run(SKAction.sequence([waitSequence, fireMeteor]))
    }
    
    // 3. Game Loop
    override func update(_ currentTime: TimeInterval) {
        
        // Calculate Delta Time for smooth movement regardless of FPS
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Combo Decay Check
        if scoreMultiplier > 1 && currentTime > comboEndTime {
            scoreMultiplier = 1
            DispatchQueue.main.async { self.gameState?.scoreMultiplier = 1 }
        }
        
        // Dynamic Camera Follow
        if cameraState == .followingShip {
            let followSpeed: CGFloat = 4.0
            cameraNode.position.x += (ship.position.x - cameraNode.position.x) * followSpeed * CGFloat(dt)
            cameraNode.position.y += (ship.position.y - cameraNode.position.y) * followSpeed * CGFloat(dt)
        }
        
        // Star paralax effect
        let dy = cameraNode.position.y - lastCameraY
        lastCameraY = cameraNode.position.y
        
        let screenHeight = self.size.height
        let screenWidth = self.size.width
        
        for starData in backgroundStars {
            // Push the star down based on its specific depth speed
            starData.node.position.y -= dy * starData.parallaxSpeed
            
            // If the star falls completely off the bottom of the screen, warp it to the top
            // Add 20 pixels of buffer so it doesn't pop in visibly
            if starData.node.position.y < -screenHeight / 2 - 20 {
                starData.node.position.y += screenHeight + 40
                
                // Randomize its X coordinate so the background pattern changes infinitely
                starData.node.position.x = CGFloat.random(in: -screenWidth/2...screenWidth/2)
                
            } else if starData.node.position.y > screenHeight / 2 + 20 {
                // Failsafe: if the player somehow moves downwards
                starData.node.position.y -= screenHeight + 40
                starData.node.position.x = CGFloat.random(in: -screenWidth/2...screenWidth/2)
            }
        }
        
        if let shader = nebulaNode.shader, let offsetUniform = shader.uniformNamed("u_camera_offset") {
            // Read the current offset
            var currentOffset = offsetUniform.vectorFloat2Value
            
            // Push the nebula gas down very slightly
            currentOffset.y += Float(dy) * 0.0001
            
            // Send the updated math back to the GPU
            offsetUniform.vectorFloat2Value = currentOffset
        }
        
        // 1. Move black whole upwards
        let currentSpeed = director.getBlackHoleSpeed()
        blackHole.position.y += currentSpeed * CGFloat(dt)
        
        // Safely find where the ship is in the scene, even if it's attached to a planet
        let shipScenePos = ship.parent?.convert(ship.position, to: self) ?? ship.position
        
        let targetX: CGFloat
        if ship.parent is InteractableNode {
            // If attached to a planet, track the planet's center so the black hole doesn't wobble
            targetX = currentInteractable.position.x
        } else {
            // If flying, track the ship itself
            targetX = shipScenePos.x
        }
        
        // Calculate the distance on the X-axis
        let xDifference = targetX - blackHole.position.x
        
        let followSpeed: CGFloat = 1.5
        
        // Apply smooth Lerp movement
        blackHole.position.x += xDifference * followSpeed * CGFloat(dt)
        
        // Death check
        let blackHoleTopEdge = blackHole.position.y + blackHole.radius
        
        if shipScenePos.y < blackHoleTopEdge {
            triggerBlackHoleDeath()
        }
        
        updateBlackHoleDistance()
        
        // 2. Garbage Collection: Destroy planets swallowed by the Black Hole
        let killLine = blackHole.position.y + (blackHole.radius - 100)
        
        for node in self.children {
            if let interactable = node as? InteractableNode {
                if interactable.position.y < killLine {
                    if(interactable.name == "dying") {
                        continue
                    }
                    
                    interactable.name = "dying" // Mark as dying
                                        
                    // Stop it from spinning and colliding
                    interactable.physicsBody = nil
                    interactable.removeAllActions()
                    
                    // Create the suck in animation
                    let suckIn = SKAction.group([
                        SKAction.move(to: blackHole.position, duration: 3),
                        SKAction.scale(to: 0.0, duration: 3),
                    ])
                    let remove = SKAction.removeFromParent()
                    
                    interactable.run(SKAction.sequence([suckIn, remove]))
                    print("Planet destroyed")
                }
            }
        }
        
        // 3. Only check bounds if the ship is flying
        if ship.parent === self && ship.name != "dying" {
            
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
            
            if (isOutOfBoundsX || isOutOfBoundsY) && self.cameraState != .followingShip {
                gameOver()
            }
            
            if let velocity = ship.physicsBody?.velocity, velocity.dx != 0 || velocity.dy != 0 {
                let velocityAngle = atan2(velocity.dy, velocity.dx)
                ship.zRotation = velocityAngle - (.pi / 2)
            }
        }
    }
    
    func gameOver() {
        // Prevent duplicate calls
        guard ship.name != "dying" else { return }
        ship.name = "dying"
        
        // Save local file
        if director is EndlessDirector {
            SaveManager.saveHighScore(newScore: director.score)
        }
        
        // Stop the ship so it doesn't keep triggering collisions
        ship.physicsBody = nil
        ship.removeAllActions()
        
        // Pause the scene and show the Game Over overlay (with the ad button)
        self.isPaused = true
        self.gameState?.currentMenu = .gameOver
    }
    
    func resurrectPlayer() {
        // 1. Reset the ship's state
        ship.name = "ship"
        ship.removeAllActions()
        ship.setScale(1.0)
        ship.alpha = 1.0
        
        // 2. Push the black hole  down to give players a huge head start
        blackHole.position.y -= 1200
        updateBlackHoleDistance()
        
        // 3. Put the ship back onto the last planet they were on
        if let safePlanet = currentInteractable {
            attachShip(to: safePlanet, atLocalPosition: CGPoint(x: 0, y: safePlanet.colliderRadius + ship.radius))
        }
        
        // 4. Clean up meteors so they don't instantly die again
        for node in self.children where node is MeteorNode {
            node.removeFromParent()
        }
        
        // 5. Unpause and resume
        self.isPaused = false
        self.cameraState = .framingPlanets
        self.updateCamera(instant: true)
        self.gameState?.currentMenu = .playing
    }
    
    func levelComplete(station: SpaceStationNode) {
        // 1. Disable user touches so they can't launch during the cinematic
        self.view?.isUserInteractionEnabled = false
        
        // 2. Save Progress (advance to the next level)
        if let campaign = director as? CampaignDirector {
            SaveManager.saveLevelProgress(levelIndex: campaign.currentLevelIndex + 1)
        }
        
        // Winning cutscene
        // Action A: Fade out the ship
        let hideShip = SKAction.run {
            self.ship.run(SKAction.fadeOut(withDuration: 0.5))
        }
        
        // Action B: Smoothly brake the station's rotation
        let brakeStation = SKAction.run {
            station.removeAllActions() // kills the infinite spin
            
            // Add a short easing rotation so it doesn't stop unnaturally fast
            let brakeSpin = SKAction.rotate(byAngle: .pi / 4, duration: 1.0)
            brakeSpin.timingMode = .easeOut
            station.run(brakeSpin)
        }
        
        // Action C: Accelerate the station off the top of the screen
        let blastOff = SKAction.run {
            // Move it exactly 1 screen height upwards
            let moveUp = SKAction.moveBy(x: 0, y: self.size.height + 200, duration: 1.2)
            // .easeIn makes it start slow and accelerate very fast
            moveUp.timingMode = .easeIn
            station.run(moveUp)
        }
        
        // Action E: Pop up the "LEVEL COMPLETE" UI
        let showUI = SKAction.run {
            let winLabel = SKLabelNode(fontNamed: "JetBrainsMono-ExtraBold")
            winLabel.text = "LEVEL COMPLETE"
            winLabel.fontSize = 32
            winLabel.fontColor = self.themeColor
            winLabel.position = CGPoint(x: 0, y: 0)
            
            // Start it tiny and invisible
            winLabel.alpha = 0
            winLabel.setScale(0.5)
            self.cameraNode.addChild(winLabel)
            
            // Pop it in
            let popIn = SKAction.group([
                SKAction.fadeIn(withDuration: 0.5),
                SKAction.scale(to: 1.2, duration: 0.5)
            ])
            popIn.timingMode = .easeOut
            winLabel.run(popIn)
        }
        
        // Run the sequence
        let waitShort = SKAction.wait(forDuration: 0.5)
        let waitLong = SKAction.wait(forDuration: 1.0)
        
        let cinematicSequence = SKAction.sequence([
            hideShip,
            brakeStation,
            waitLong,      // Wait for the station to fully stop
            blastOff,
            waitShort,     // Wait for the station to get some speed before showing text
            showUI
        ])
        
        self.run(cinematicSequence)
    }
    
    
    // MARK: - Death Animations
    func triggerBlackHoleDeath() {
        // Prevent this from running multiple times
        guard ship.name != "dying" else { return }
        ship.name = "dying"
        
        // Save local file
        if director is EndlessDirector {
            SaveManager.saveHighScore(newScore: director.score)
        }
        
        // 1. Move the ship to the main scene if it's currently spinning on a planet
        if ship.parent != self {
            let scenePos = ship.parent?.convert(ship.position, to: self) ?? ship.position
            ship.removeFromParent()
            ship.position = scenePos
            self.addChild(ship)
        }
        
        // 2. Stop physics and interactions
        ship.physicsBody = nil
        ship.removeAllActions()
        
        // 3. The "Suck In" Animation
        let suckIn = SKAction.group([
            SKAction.move(to: blackHole.position, duration: 3),
            SKAction.scale(to: 0.0, duration: 3),
            SKAction.fadeOut(withDuration: 3),
            SKAction.rotate(byAngle: .pi * 4, duration: 3)
        ])
        
        // 4. Show the Game Over UI instead of instantly restarting
        let showGameOverMenu = SKAction.run {
            self.isPaused = true
            self.gameState?.currentMenu = .gameOver
        }
        
        ship.run(suckIn)
        let wait = SKAction.wait(forDuration: 1.5)
        ship.run(SKAction.sequence([wait, showGameOverMenu]))
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        launchShip()
    }
    
    // 4. Camera Control
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
    
    // 5. Core Mechanics
    func attachShip(to interactable: InteractableNode, atLocalPosition localPos: CGPoint? = nil) {
        
        // Stop physics movement
        ship.physicsBody = nil
        ship.removeFromParent()
        
        // Add ship as a child of the planet
        interactable.addChild(ship)
        
        if let pos = localPos {
            ship.position = pos
            
            let angle = atan2(pos.y, pos.x)
            
            // Subtract 90 degrees so the rocket points up
            ship.zRotation = angle - (.pi / 2)
        }
        
        // Update tracker
        updateProgress()
        
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
        ship.physicsBody?.contactTestBitMask = PhysicsCategory.planet | PhysicsCategory.meteor | PhysicsCategory.blackHole
        
        let launchAngle = atan2(direction.dy, direction.dx)
        ship.zRotation = launchAngle - (.pi / 2)
        
        let launchForce: CGFloat = 8
        ship.physicsBody?.applyImpulse(CGVector(dx: direction.dx * launchForce, dy: direction.dy * launchForce))
    
        // Thicker raycast
        var willHitSomething = false
        
        // 1. Calculate a vector perpendicular to flight direction
        let perpDx = -direction.dy
        let perpDy = direction.dx
        
        let radius = ship.radius
        
        // 2. Calculate start points for the 3 rays (Center, Left Wing, Right Wing)
        let centerStart = shipScenePos
        let leftStart = CGPoint(x: shipScenePos.x + (perpDx * radius), y: shipScenePos.y + (perpDy * radius))
        let rightStart = CGPoint(x: shipScenePos.x - (perpDx * radius), y: shipScenePos.y - (perpDy * radius))
        
        // 3. Calculate end points 3000 pixels away
        let rayLength: CGFloat = 3000
        let centerEnd = CGPoint(x: centerStart.x + direction.dx * rayLength, y: centerStart.y + direction.dy * rayLength)
        let leftEnd = CGPoint(x: leftStart.x + direction.dx * rayLength, y: leftStart.y + direction.dy * rayLength)
        let rightEnd = CGPoint(x: rightStart.x + direction.dx * rayLength, y: rightStart.y + direction.dy * rayLength)
        
        // 4. Helper function to cast a ray as to not repeat the physics code 3 times
        let castRay: (CGPoint, CGPoint) -> Void = { start, end in
            // If one of the previous rays already hit something, skip this one
            guard !willHitSomething else { return }
            
            self.physicsWorld.enumerateBodies(alongRayStart: start, end: end) { body, point, normal, stop in
                if body.categoryBitMask == PhysicsCategory.planet ||
                   body.categoryBitMask == PhysicsCategory.meteor ||
                   body.categoryBitMask == PhysicsCategory.blackHole {
                    
                    willHitSomething = true
                    stop.pointee = true // Found a target, stop search
                }
            }
        }
        
        // 5. Fire the 3 lasers
        castRay(centerStart, centerEnd)
        castRay(leftStart, leftEnd)
        castRay(rightStart, rightEnd)
        
        if willHitSomething {
            // Ship is on target, smoothly follow it
            cameraState = .followingShip
        } else {
            // Ship is going to miss entirely. Lock the camera so the player flies out of bounds and dies
            cameraState = .staticDeath
            cameraNode.removeAllActions()
            
            // Smoothly accelerate to death speed
            if let currentVelocity = ship.physicsBody?.velocity {
                
                let deathSpeedMultiplier: CGFloat = 4.0
                let targetVelocity = CGVector(
                    dx: currentVelocity.dx * deathSpeedMultiplier,
                    dy: currentVelocity.dy * deathSpeedMultiplier
                )
                
                // How long it takes to reach maximum speed
                let accelerationTime: TimeInterval = 0.5
                
                let smoothAccelerate = SKAction.customAction(withDuration: accelerationTime) { node, elapsedTime in
                    guard let physicsBody = node.physicsBody else { return }
                    
                    let percent = CGFloat(elapsedTime / accelerationTime)
                    
                    // Lerp the velocity: Start + (Difference * Percent)
                    let newDx = currentVelocity.dx + (targetVelocity.dx - currentVelocity.dx) * percent
                    let newDy = currentVelocity.dy + (targetVelocity.dy - currentVelocity.dy) * percent
                    
                    physicsBody.velocity = CGVector(dx: newDx, dy: newDy)
                }
                
                // Run the smooth acceleration on the ship
                ship.run(smoothAccelerate)
            }
        }
    }
    
    // 6. Collision Routing
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
        else if let meteor = otherNode as? MeteorNode {
            handleMeteorCollision(meteor)
        }
    }
    
    // MARK: - Specific Collision Handlers
    func handleBlackHoleCollision() {
        // The void caught the player
        triggerBlackHoleDeath()
    }
    
    func handleMeteorCollision(_ meteor: SKNode) {
        gameOver()
    }
    
    func handlePlanetCollision(_ planet: PlanetNode) {
        // Don't land on the planet we are already attached to
        guard planet != currentInteractable else { return }
        
        // 1. Score & Combo Logic
        if planet.sequenceIndex > director.planetsCleared {
            
            // Check if player skipped planet
            let skippedPlanets = planet.sequenceIndex - currentInteractable.sequenceIndex - 1
            if skippedPlanets > 0 {
                // Double the multiplier for every planet skipped! (2x, 4x, 8x...)
                scoreMultiplier *= (2 * skippedPlanets)
                // Give them 10 seconds to keep the combo going
                comboEndTime = lastUpdateTime + 10.0
                gameState?.scoreMultiplier = scoreMultiplier
            }
            
            // Calculate distance traveled and multiply it for big numbers
            let distanceTraveled = max(0, planet.position.y - currentInteractable.position.y)
            let basePoints = Int(distanceTraveled) * 10
            let totalPoints = basePoints * scoreMultiplier
            
            director.score += totalPoints
            director.planetsCleared = planet.sequenceIndex
            gameState?.score = director.score
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
        let perfectDistance = planet.colliderRadius + ship.radius
        
        // 4. Use Trig to find the exact X and Y coordinates on the edge
        let perfectLocalPos = CGPoint(
            x: cos(angle) * perfectDistance,
            y: sin(angle) * perfectDistance
        )
        
        self.cameraState = .framingPlanets
        
        // 5. Queue the attachment for the end of the frame
        self.run(SKAction.run {
            self.attachShip(to: planet, atLocalPosition: perfectLocalPos)
            self.maintainPlanetBuffer()
            self.updateCamera()
            self.trySpawnMeteor()
        })
    }
    
    func handleStationCollision(_ station: SpaceStationNode) {
        // Don't land on the station if we are already attached to it
        guard station != currentInteractable else { return }
        
        // 1. Score point if we moved forward
        if station.sequenceIndex > director.planetsCleared {
            // Give player a last few score points
            director.score += Int((CGFloat.random(in: 7500...12500) * CGFloat(scoreMultiplier)).rounded())
            director.planetsCleared = station.sequenceIndex
            gameState?.score = director.score
        }
        
        nextInteractable = nil
        
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
            self.levelComplete(station: station)
            
            self.cameraState = .framingPlanets
            self.updateCamera()
        })
    }
        
    func updateProgress() {
        guard let director = director else { return }
        
        let currentScore = director.planetsCleared
        var clampedPercent: CGFloat = 0.0
        
        if let campaign = director as? CampaignDirector {
            let targetScore = campaign.currentLevel?.planets.count ?? 1
            let percent = CGFloat(currentScore) / CGFloat(targetScore)
            clampedPercent = max(0.0, min(1.0, percent))
            
        } else if director is EndlessDirector {
            let highScore = SaveManager.getHighScore()
            let target = max(highScore, 1)
            let percent = CGFloat(director.score) / CGFloat(target)
            clampedPercent = percent
        }
        
        // Push the new percentage to SwiftUI
        gameState?.progress = clampedPercent
    }
    
    func updateBlackHoleDistance() {
        guard let blackHole = blackHole else { return }
        
        let playerPos: CGPoint
        if ship.parent is InteractableNode {
            // If attached to a planet, track the planet's position so distance doesn't wobble
            playerPos = currentInteractable.position
        } else {
            // If flying, track the ship itself
            playerPos = ship.position
        }
        
        let blackHoleTopEdge = blackHole.position.y + blackHole.radius
        let rawDistance = max(0, playerPos.y - blackHoleTopEdge)
                
        // Only shows differences of 10 km
        let steppedDistance = (Int(rawDistance) / 10) * 10
        
        // Send to SwiftUI
        gameState?.distanceToBlackHole = steppedDistance
    }
    
    // MARK: - Starfield Generation
    func initializeStars(view: SKView) {
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        
        // 1. Pre-render 3 glow textures to save CPU power
        let baseRadius: CGFloat = 1.0
        let whiteGlow = SKTexture.planetGlow(planetRadius: baseRadius, color: .white, radiusSize: 2.0)
        let greyGlow = SKTexture.planetGlow(planetRadius: baseRadius, color: .gray, radiusSize: 2.0)
        
        // Weight the array so white stars are much more common
        let textures = [whiteGlow, whiteGlow, whiteGlow, greyGlow, greyGlow]
        
        // 2. Generate 50 stars
        for _ in 0..<50 {
            let depthRoll = CGFloat.random(in: 0...1)
            let scale: CGFloat
            let parallaxSpeed: CGFloat
            let maxAlpha: CGFloat
            
            // Organize into 3 depth layers
            if depthRoll < 0.5 {
                // Back layer: Tiny, dim, moves very slow
                scale = CGFloat.random(in: 0.3...0.6)
                parallaxSpeed = 0.15
                maxAlpha = CGFloat.random(in: 0.2...0.5)
            } else if depthRoll < 0.85 {
                // Mid layer: Medium size, medium speed
                scale = CGFloat.random(in: 0.6...1.0)
                parallaxSpeed = 0.4
                maxAlpha = CGFloat.random(in: 0.4...0.7)
            } else {
                // Front layer: Big, bright, moves fast
                scale = CGFloat.random(in: 1.0...1.5)
                parallaxSpeed = 0.8
                maxAlpha = CGFloat.random(in: 0.7...1.0)
            }
            
            // 3. Create the star node
            let starTexture = textures.randomElement()!
            let star = SKSpriteNode(texture: starTexture)
            star.setScale(scale)
            
            // Random position inside the camera bounds
            let randomX = CGFloat.random(in: -screenWidth/2...screenWidth/2)
            let randomY = CGFloat.random(in: -screenHeight/2...screenHeight/2)
            star.position = CGPoint(x: randomX, y: randomY)
            star.zPosition = -100 + scale // Ensure bigger stars render on top of smaller ones
            star.alpha = maxAlpha
            
            // 4. Add blinking animation
            let blinkDuration = TimeInterval.random(in: 1.0...4.0)
            let fadeOut = SKAction.fadeAlpha(to: maxAlpha * 0.1, duration: blinkDuration)
            let fadeIn = SKAction.fadeAlpha(to: maxAlpha, duration: blinkDuration)
            
            // Randomize the start time so they don't all blink in unison
            let startDelay = SKAction.wait(forDuration: TimeInterval.random(in: 0...2.0))
            let blinkSequence = SKAction.sequence([fadeOut, fadeIn])
            
            star.run(SKAction.sequence([startDelay, SKAction.repeatForever(blinkSequence)]))
            
            // Add to camera so we can control their offset mathematically
            cameraNode.addChild(star)
            backgroundStars.append(StarData(node: star, parallaxSpeed: parallaxSpeed))
        }
    }
}
