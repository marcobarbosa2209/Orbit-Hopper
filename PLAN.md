### 1. Game Idea: "Orbit Hopper"
You control a tiny spaceship currently orbiting a small planet. The planet is rotating. You must tap the screen at the exact right moment to launch your ship to the next planet above you. If you miss and fly off into deep space, it's Game Over. 

### 2. Core Gameplay Loop
1.⁠ ⁠*Wait & Aim:* The player's ship is attached to a rotating planet.
2.⁠ ⁠*Action:* The player taps the screen. The ship detaches and shoots straight forward.
3.⁠ ⁠*Resolution:* * *Success:* The ship hits the next planet, attaches to it, and begins rotating with it. The score goes up by 1. The camera pans up.
    * *Failure:* The ship misses the planet and flies off-screen. Game Over.
4.⁠ ⁠*Repeat:* The game spawns new planets indefinitely, getting slightly faster or smaller as the score increases.

### 3. Player Actions
•⁠  ⁠*Single Tap:* Tap anywhere on the screen. There are no directional controls or joysticks. The entire game relies on *timing*. 

### 4. Progression System
•⁠  ⁠*In-Game Difficulty:* As the score increases, planets spawn with varying sizes, rotate at faster speeds, or alternate between clockwise and counter-clockwise rotation.
•⁠  ⁠*Meta-Progression:* A local High Score tracker. (No complex cloud saves, just beating your own personal best).

### 5. UI Screens
Keep it to exactly two scenes to avoid overly complex transition logic:
1.⁠ ⁠*Main Menu / Game Over Overlay:* * Title text ("Orbit Hopper").
   * "Tap to Start" text.
   * High Score display.
   * (Note: You can overlay this UI directly on top of the paused game scene to save time, rather than building an entirely separate ⁠ SKScene ⁠).
2.⁠ ⁠*Active Game HUD:*
   * A large, slightly transparent Score number at the top center of the screen.

---

### 6. Technical Breakdown (SpriteKit)
Here are the specific SpriteKit tools you will use:
•⁠  ⁠*⁠ SKSpriteNode ⁠:* Used for the Ship, Planets, and a starry background.
•⁠  ⁠*⁠ SKPhysicsBody ⁠:* * The Ship will have a dynamic physics body. 
  * The Planets will have static (non-moving) physics bodies.
  * You will use ⁠ contactTestBitMask ⁠ to detect when the Ship touches a Planet.
•⁠  ⁠*⁠ SKPhysicsJointFixed ⁠ or Parenting:* When the ship hits a planet, you either create a physics joint to pin them together, or simply remove the ship from the scene and add it as a ⁠ child ⁠ of the planet so it inherits the rotation automatically.
•⁠  ⁠*⁠ SKAction ⁠:* * ⁠ SKAction.rotate(byAngle:duration:) ⁠ to make the planets spin indefinitely.
  * ⁠ SKAction.moveTo(...) ⁠ to pan the camera up when a successful jump happens.
•⁠  ⁠*⁠ SKCameraNode ⁠:* Placed in the scene to follow the player upward.
•⁠  ⁠*⁠ UserDefaults ⁠:* To save and load the player's high score.

---

### 7. MVP Scope (4-Week Schedule)
•⁠  ⁠*Week 1: Basics & Physics.* Set up the Xcode project. Create simple colored circles for the ship and planets (no fancy art yet). Implement the tap gesture to apply an impulse (⁠ applyImpulse ⁠) to the ship's physics body.
•⁠  ⁠*Week 2: The Core Loop.* Implement ⁠ SKPhysicsContactDelegate ⁠. When the ship touches a planet, stop its movement and attach it. Make the planets rotate. 
•⁠  ⁠*Week 3: Endless Spawning & Camera.* Make the camera follow the ship upwards. Write a function that spawns a new planet above the highest one, and deletes planets that fall below the bottom of the screen (to save memory).
•⁠  ⁠*Week 4: Game Loop & Polish.* Add the Score counter. Implement the Game Over state (detect when the ship goes off-screen). Add a simple menu overlay. Save the high score using ⁠ UserDefaults ⁠.

---

### 8. Stretch Goals (If you finish early)
•⁠  ⁠*Visuals:* Replace the colored circles with actual ⁠ .png ⁠ space sprites.
•⁠  ⁠*Juice:* Add an ⁠ SKEmitterNode ⁠ to the back of the ship to create a particle trail (rocket exhaust) when it jumps.
•⁠  ⁠*Audio:* Add a simple "jump" sound effect (⁠ SKAction.playSoundFileNamed ⁠) and a background music track.