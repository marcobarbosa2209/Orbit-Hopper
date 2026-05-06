# Orbit Hopper - Game Design Document

## 1. Game Concept & Story
You control a sleek spaceship escaping a galaxy-consuming cosmic void (a black hole). You navigate by launching from rotating planets. The game features two primary modes: a Campaign mode where you escape distinct galaxies to reach a Space Station, and an Endless mode where you survive as long as possible against escalating chaos.

## 2. Core Gameplay Loop
1. **Wait & Aim:** The ship is attached to a rotating planet. The player must time their jump based on the planet's rotation.
2. **Action:** Single screen tap. The ship detaches and shoots straight forward.
3. **Resolution:**
   - **Success:** Ship hits the next planet and attaches to it.
   - **Failure (The Void):** The player waits too long, and the creeping Black Hole at the bottom of the screen consumes them.
   - **Failure (Deep Space/Hazard):** The ship misses a planet and flies off-screen, or collides with a crossing meteor.

## 3. Mechanics & Hazards
- **Dynamic Black Hole:** Slowly creeps up the screen from the bottom. Speeds up aggressively if the player stays on a single planet for too long (e.g., > 3 seconds), forcing quick decisions.
- **Math-Driven Planet Rotation:** Planets don't just spin at a constant rate. Using mathematical functions (like sine waves), planets can dynamically speed up, slow down, or reverse direction, making timing unpredictable.
- **Meteor Showers:** High-speed projectiles that fly across the screen. They are heavily telegraphed with a flashing `!` warning icon and a faint trajectory line 1.5 seconds before they appear.

## 4. Game Modes
### A. Campaign Mode
- **Structure:** 5 to 10 distinct "Galaxies" (Levels).
- **Generation:** Procedural placement, but fixed difficulty parameters per level.
  - *Example:* Level 1 (15 jumps, slow constant rotation, no meteors). Level 5 (40 jumps, erratic sine-wave rotation, frequent meteors).
- **Goal:** Reach the final "Space Station Hub" at the top to clear the galaxy and warp to the next level.

### B. Endless Mode
- **Structure:** Infinite procedural generation.
- **Progression:** Difficulty scales dynamically based on the current score (planets hopped).
  - *Phase 1 (0-20):* Slow rotation, no hazards.
  - *Phase 2 (21-50):* Math-based rotations begin.
  - *Phase 3 (51-100):* Meteors start spawning; void speed increases.
  - *Phase 4 (100+):* Maximum chaos, reversing planets, dual meteor spawns.

## 5. UI & Screens
1. **Main Menu:** Title, High Scores, "Campaign" Node map, "Endless" Play Button, Settings.
2. **Active HUD:** Large transparent score in the background, active warning indicators (meteors), faint trajectory lines.
3. **Level Complete Overlay:** Space Station warp cinematic, "Galaxy Cleared," Next Level button.
4. **Game Over Overlay:** "Consumed by the Void" or "Lost in Space," final score, Quick Restart / Home buttons.

## 6. MVP Scope (4-Week Schedule)
- **Week 1: Core Input & Physics.** Set up Xcode. Build ship jumping, attaching to static planets, and basic infinite camera tracking upward.
- **Week 2: Danger & Math.** Implement the Black Hole "kill line" and the mathematical rotation functions (sine waves) for planets in the update loop.
- **Week 3: Hazards & Game Modes.** Implement the `GameMode` enum. Build the Endless spawner, the Campaign level logic (Space Station goal), and the Meteor warning/projectile system.
- **Week 4: UI & Polish.** Build the Main Menu, End-state overlays, and `UserDefaults` to save Campaign progress and Endless High Scores. Add particles (rocket trail).