//
//  GameScene.swift
//  OrbitHopper
//
//  Created by Marco Barbosa on 07/05/2026.
//

import SpriteKit

struct StarData {
    let node: SKSpriteNode
    let parallaxSpeed: CGFloat
}

var backgroundStars: [StarData] = []
var lastCameraY: CGFloat = 0

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Ship
    var ship: ShipNode!
    
    // Camera
    let cameraNode = SKCameraNode()
    
    // UI
    var scoreLabel: SKLabelNode!
    var progressContainer: SKShapeNode!
    var modeTitleLabel: SKLabelNode!
    var progressBarBG: SKShapeNode!
    var progressBarFill: SKShapeNode!
    var progressTextLabel: SKLabelNode!
    var distanceContainer: SKNode!
    var distanceLabel: SKLabelNode!
    var isTrackerVisible: Bool = true
    var lastDisplayedDistance: Int = -1
    
    let themeColor = UIColor(red: 0.45, green: 0.95, blue: 0.90, alpha: 1.0)
    
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
        initializeStars(view: view)
        
        // Initialize Game Mode
        director = CampaignDirector(levelIndex: 1)
        // director = EndlessDirector()
        
        // 2.2 Setup UI
        initializeUI(camera: cameraNode, view: self.view ?? SKView())
        
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
        ship = ShipNode(radius: 20)
        attachShip(to: currentInteractable, atLocalPosition: CGPoint(x: 0, y: startPlanet.colliderRadius + ship.radius))
        
        // Spawn Black Hole
        blackHole = BlackHoleNode(radius: 800)
        blackHole.position = CGPoint(x: view.bounds.minX, y: view.bounds.minY - blackHole.radius - 200)
        addChild(blackHole)
        
        // Frame the initial camera
        updateCamera(instant: true)
        
        lastCameraY = cameraNode.position.y
    }
    
    // MARK: - Spawner Logic
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
    
    // MARK: - Meteor System
    func trySpawnMeteor() {
        let chance = director.getMeteorChance()
        let roll = CGFloat.random(in: 0.0...1.0)
        
        // 1. Did the meteor trigger?
        guard roll <= chance else { return }
        guard let next = nextInteractable else { return }
        guard let current = currentInteractable else { return }
        
        // 2. Calculate the exact midpoint between planets
        let midY = (current.position.y + next.position.y) / 2
        
        // 3. Decide if it flies Left-to-Right or Right-to-Left
        let goRight = Bool.random()
        let screenWidth = self.size.width
        
        // Use the camera's X position to find the true edges of the screen
        let leftEdge = cameraNode.position.x - (screenWidth / 2) - 100
        let rightEdge = cameraNode.position.x + (screenWidth / 2) + 100
        
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
        
        let visibleLeftEdge = cameraNode.position.x - (screenWidth / 2)
        let visibleRightEdge = cameraNode.position.x + (screenWidth / 2)
        
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
    
    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        
        // Calculate Delta Time for smooth movement regardless of FPS
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Star paralax effect
        let dy = cameraNode.position.y - lastCameraY
        lastCameraY = cameraNode.position.y
        
        let screenHeight = self.size.height
        let screenWidth = self.size.width
        
        for starData in backgroundStars {
            // Push the star down based on its specific depth speed
            starData.node.position.y -= dy * starData.parallaxSpeed
            
            // If the star falls completely off the bottom of the screen, wrap it to the top!
            // We add 20 pixels of buffer so it doesn't pop in visibly.
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
        
        // 1. Move black whole upwards
        let currentSpeed = director.getBlackHoleSpeed()
        blackHole.position.y += currentSpeed * CGFloat(dt)
        
        // Death check
        let blackHoleTopEdge = blackHole.position.y + blackHole.radius
        
        // Safely find where the ship is in the scene, even if it's attached to a planet
        let shipScenePos = ship.parent?.convert(ship.position, to: self) ?? ship.position
        
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
                        return
                    }
                    
                    interactable.name = "dying" // Mark as dying
                                        
                    // Stop it from spinning and colliding
                    interactable.physicsBody = nil
                    interactable.removeAllActions()
                    
                    // Create the suck in animation
                    let suckIn = SKAction.group([
                        SKAction.move(to: blackHole.position, duration: 3),
                        SKAction.scale(to: 0.0, duration: 3),
                        SKAction.fadeOut(withDuration: 3)
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
            
            if isOutOfBoundsX || isOutOfBoundsY {
                gameOver()
            }
            
            if let velocity = ship.physicsBody?.velocity, velocity.dx != 0 || velocity.dy != 0 {
                let velocityAngle = atan2(velocity.dy, velocity.dx)
                ship.zRotation = velocityAngle - (.pi / 2)
            }
        }
    }
    
    func gameOver() {
        
        // Save local file
        if director is EndlessDirector {
            SaveManager.saveHighScore(newScore: director.score)
        }
        
        // 1. Pause the scene so the player doesn't keep falling/triggering collisions
        self.isPaused = true
        
        // 2. Create a brand new, fresh copy of the game scene
        let newScene = GameScene(size: self.size)
        newScene.scaleMode = self.scaleMode
        
        self.view?.isUserInteractionEnabled = true
        
        // 3. Restart the game with a cool cinematic fade
        let transition = SKTransition.fade(with: .black, duration: 1.0)
        self.view?.presentScene(newScene, transition: transition)
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
        
        // Action D: Hide HUD
        let hideHUD = SKAction.run {
            self.scoreLabel.run(SKAction.fadeOut(withDuration: 0.3))
            self.distanceContainer.run(SKAction.fadeOut(withDuration: 0.3))
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
            hideHUD,
            showUI
        ])
        
        self.run(cinematicSequence)
    }
    
    
    // MARK: - Death Animations
    func triggerBlackHoleDeath() {
        // Prevent this from running multiple times
        guard ship.name != "dying" else { return }
        ship.name = "dying"
        
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
        
        // 4. Game over after action
        let finishGameOver = SKAction.run {
            self.gameOver()
        }
        
        // Run "sequence"
        ship.run(suckIn)
        
        let wait = SKAction.wait(forDuration: 1.5)
        ship.run(SKAction.sequence([wait, finishGameOver]))
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
        let perfectDistance = planet.colliderRadius + ship.radius
        
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
            self.trySpawnMeteor()
        })
    }
    
    func handleStationCollision(_ station: SpaceStationNode) {
        // Don't land on the station if we are already attached to it
        guard station != currentInteractable else { return }
        
        // TODO: Update station landing logic to show Win Sequence
        
        // 1. Score point if we moved forward
        if station.sequenceIndex > director.score {
            director.score = station.sequenceIndex
            
            updateScoreLabel(score: director.score)
        }
        
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
        })
    }
    
    // MARK: - UI functions
    func initializeUI(camera: SKCameraNode, view: SKView) {
        // Score label
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
        let yPos = view.safeAreaInsets.top - 20
        scoreLabel.position = CGPoint(x: xPos, y: yPos)
        
        // Add it to the camera
        cameraNode.addChild(scoreLabel)

        addChild(cameraNode)
        
        // Progress Container
        // 1. Define how big the dark background panel should be
        let panelWidth: CGFloat = view.window?.screen.bounds.width ?? view.bounds.width
        let panelHeight: CGFloat = 160
        let panelRect = CGRect(x: -panelWidth/2, y: -panelHeight/2, width: panelWidth, height: panelHeight)
        
        // 2. Initialize it as a rounded shape node!
        progressContainer = SKShapeNode(rect: panelRect)
        
        // 3. Apply 70% opacity black background
        progressContainer.fillColor = .black.withAlphaComponent(0.7)
        progressContainer.strokeColor = .clear
        progressContainer.zPosition = 100
        
        let bottomBorder = SKSpriteNode(color: themeColor.withAlphaComponent(0.4), size: CGSize(width: panelWidth, height: 1))
        bottomBorder.position = CGPoint(x: 0, y: -panelHeight / 2)
        progressContainer.addChild(bottomBorder)
        
        // Position it at the top of the screen
        let topY = (view.bounds.height / 2) - (panelHeight / 2)
        progressContainer.position = CGPoint(x: 0, y: topY)
        camera.addChild(progressContainer)
        
        let topPadding = progressContainer.bounds.midY - 40;
        
        // Layout Constants
        let gap: CGFloat = 10
        let barWidth: CGFloat = 280
        let barHeight: CGFloat = 12
        let cornerRadius: CGFloat = 6
        
        let groupCenterY: CGFloat = topPadding + 20
        
        // Title Label
        modeTitleLabel = SKLabelNode(fontNamed: "JetBrainsMono-ExtraBold")
        if director is EndlessDirector {
            modeTitleLabel.text = "ENDLESS MODE // HI-SCORE"
        } else if let campaign = director as? CampaignDirector,
                  let level = campaign.currentLevel {
            let levelNumber = String(format: "%03d", campaign.currentLevelIndex + 1)
            modeTitleLabel.text = "\(level.galaxyName.uppercased()) // LEVEL \(levelNumber)"
        }
        modeTitleLabel.fontSize = 18
        modeTitleLabel.fontColor = themeColor
        modeTitleLabel.verticalAlignmentMode = .center
        modeTitleLabel.position = CGPoint(x: 0, y: groupCenterY + (barHeight / 2) + gap + (modeTitleLabel.fontSize / 2))
        progressContainer.addChild(modeTitleLabel)
        
        let bgRect = CGRect(x: -barWidth/2, y: -barHeight/2, width: barWidth, height: barHeight)
        progressBarBG = SKShapeNode(rect: bgRect, cornerRadius: cornerRadius)
        progressBarBG.strokeColor = themeColor
        progressBarBG.lineWidth = 2
        progressBarBG.fillColor = UIColor(red: 0.102, green: 0.137, blue: 0.145, alpha: 1.0)
        progressBarBG.position = CGPoint(x: 0, y: groupCenterY)
        progressContainer.addChild(progressBarBG)
        
        // 3. Progress Bar Fill
        // Position this at the far left edge of the background so it grows to the right
        progressBarFill = SKShapeNode()
        progressBarFill.fillColor = themeColor
        progressBarFill.strokeColor = .clear
        progressBarFill.position = CGPoint(x: -barWidth/2, y: groupCenterY - (barHeight / 2))
        progressContainer.addChild(progressBarFill)
        
        // 4. Progress Text Label ("60% Progress")
        progressTextLabel = SKLabelNode(fontNamed: "Orbitron-Bold")
        progressTextLabel.text = "0% Progress"
        progressTextLabel.fontSize = 16
        progressTextLabel.fontColor = themeColor
        progressTextLabel.position = CGPoint(x: 0, y: groupCenterY - (barHeight / 2) - gap - (progressTextLabel.fontSize))
        progressContainer.addChild(progressTextLabel)
        
        // Call this once to set the initial visual state
        updateProgress()
        
        // Black Hole distance
        distanceContainer = SKNode()
        distanceContainer.zPosition = 100
        
        // 1. The Distance Label
        distanceLabel = SKLabelNode(fontNamed: "JetBrainsMono-Bold")
        distanceLabel.text = "250km"
        distanceLabel.fontSize = 24
        distanceLabel.fontColor = themeColor
        distanceLabel.verticalAlignmentMode = .center
        distanceContainer.addChild(distanceLabel)
        
        // 2. Draw the Downward Arrow using a Path (later update to use SVG)
        let arrowPath = CGMutablePath()
        arrowPath.move(to: CGPoint(x: 0, y: 10))
        arrowPath.addLine(to: CGPoint(x: 0, y: -15))
        arrowPath.move(to: CGPoint(x: -10, y: -5))
        arrowPath.addLine(to: CGPoint(x: 0, y: -15))
        arrowPath.addLine(to: CGPoint(x: 10, y: -5))
        
        let arrowIcon = SKShapeNode(path: arrowPath)
        arrowIcon.strokeColor = themeColor
        arrowIcon.lineWidth = 4
        arrowIcon.lineCap = .round
        arrowIcon.lineJoin = .round
        
        // Gap of 15px below the text
        arrowIcon.position = CGPoint(x: 0, y: -15 - (distanceLabel.fontSize / 2))
        distanceContainer.addChild(arrowIcon)
        
        // 3. Position the container at the bottom center
        let bottomY = -(view.bounds.height / 2) + view.safeAreaInsets.bottom + 60
        distanceContainer.position = CGPoint(x: 0, y: bottomY)
        
        camera.addChild(distanceContainer)
    }
    
    func updateScoreLabel (score: Int) {
        scoreLabel.text = "\(score)"
    }
    
    func updateProgress() {
        // Safely exit if the director hasn't been loaded yet
        guard let director = director else { return }
        
        let currentScore = director.score
        var clampedPercent: CGFloat = 0.0
        var statusText = ""
        
        // 1. Calculate Logic Based on Game Mode
        if let campaign = director as? CampaignDirector {
            // Campaign Mode Logic
            // Get the target amount, default to 1 to avoid crashes if level is missing
            let targetScore = campaign.currentLevel?.planets.count ?? 1
            let percent = CGFloat(currentScore) / CGFloat(targetScore)
            clampedPercent = max(0.0, min(1.0, percent))
            
            let displayPercent = Int(clampedPercent * 100)
            statusText = "\(displayPercent)% Progress"
            
        } else if director is EndlessDirector {
            // Endless Mode Logic
            let highScore = SaveManager.getHighScore()
            
            if currentScore > highScore {
                // Surpassed High Score, bar is 100% full.
                clampedPercent = 1.0
                statusText = "NEW HI-SCORE: \(currentScore)!"
                
                // Change the bar color to gold/yellow when player breaks the record
                progressBarFill.fillColor = .systemYellow
                progressBarBG.strokeColor = .systemYellow
                progressTextLabel.fontColor = .systemYellow
                
            } else {
                // Chasing the High Score.
                // max(highScore, 1) to prevent dividing by zero on their very first game
                let target = max(highScore, 1)
                let percent = CGFloat(currentScore) / CGFloat(target)
                clampedPercent = max(0.0, min(1.0, percent))
                
                statusText = "Chasing Record: \(highScore)"
            }
        }
        
        // 2. Draw the Fill Bar
        let barWidth: CGFloat = 280
        let barHeight: CGFloat = 12
        let cornerRadius: CGFloat = 6
        
        let fillWidth = barWidth * clampedPercent
        
        if fillWidth > 0 {
            let fillRect = CGRect(x: 0, y: 0, width: fillWidth, height: barHeight)
            progressBarFill.path = CGPath(roundedRect: fillRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            progressBarFill.isHidden = false
        } else {
            progressBarFill.isHidden = true
        }
        
        // 3. Update the Text
        progressTextLabel.text = statusText
    }
    
    func updateBlackHoleDistance() {
        guard let blackHole = blackHole else { return }
        
        // 1. Calculate the exact distance
        let playerPos = currentInteractable.position
        let blackHoleTopEdge = blackHole.position.y + blackHole.radius
        
        // Ensure distance doesn't drop below 0
        let rawDistance = max(0, playerPos.y - blackHoleTopEdge)
        
        let displayDistance = Int(rawDistance)
                
        // Only update the actual text node if the number changed
        if displayDistance != lastDisplayedDistance {
            
            // Only shows differences of 10 km
            let steppedDistance = (displayDistance / 10) * 10
            distanceLabel.text = "\(steppedDistance)km"
            
            lastDisplayedDistance = displayDistance
        }
        
        // 2. Fading Logic
        // Define how close the void gets before the UI vanishes
        let fadeThreshold: CGFloat = 250
        
        if rawDistance < fadeThreshold && isTrackerVisible {
            // hide if it's too close
            isTrackerVisible = false
            distanceContainer.removeAllActions()
            distanceContainer.run(SKAction.fadeOut(withDuration: 0.3))
            
        } else if rawDistance >= fadeThreshold && !isTrackerVisible {
            // show again if it's safe
            isTrackerVisible = true
            distanceContainer.removeAllActions()
            distanceContainer.run(SKAction.fadeIn(withDuration: 0.3))
        }
    }
    
    // MARK: - Starfield Generation
    func initializeStars(view: SKView) {
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        
        // 1. Pre-render 3 glow textures to save CPU power
        let baseRadius: CGFloat = 2.0
        let whiteGlow = SKTexture.planetGlow(planetRadius: baseRadius, color: .white, radiusSize: 4.0)
        let greyGlow = SKTexture.planetGlow(planetRadius: baseRadius, color: UIColor(hex: "#4B90E2") ?? .gray, radiusSize: 4.0)
        
        // Weight the array so white stars are much more common
        let textures = [whiteGlow, whiteGlow, whiteGlow, greyGlow, greyGlow]
        
        // 2. Generate 150 stars
        for _ in 0..<150 {
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
            let starTexture = whiteGlow
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
