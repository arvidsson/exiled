# Exiled: Project Architecture

## Core Architectural Pillars

The project follows a decoupled, event-driven architecture using Godot 4 features to ensure scalability and maintainability.

### 1. Global Signal Bus (`Events.gd`)
A centralized hub for game-wide communication. Systems emit signals here, and others (like UI or audio) listen for them. This avoids tight coupling between gameplay logic and visual/auditory feedback.
- **Key Signals:** `hp_changed`, `xp_changed`, `ammo_changed`, `stamina_changed`, `levelup`, `skill_used`.

### 2. Singleton-First Infrastructure (Autoloads)
Core utilities are globally accessible through specialized singletons:
- **`Events`**: The global signal bus.
- **`Data`**: A registry for all critical resources (Scenes, AudioStreams, FX) using `uid://` for robust referencing.
- **`Globals`**: Shared enums like `CollisionLayer` and `Skill` slots.
- **`Pools`**: A generic object pooling system for high-volume entities (mobs, projectiles, pickups).
- **`Audio`**: Manages spatialized SFX and music playback.

### 3. Data-Driven Design
Enemies and items are defined primarily through **Resources**:
- **`MobData`**: A custom resource type defining stats like health, speed, attack range, and associated scenes. It also contains an array of `MobSkill` resources.
- **`Mob.gd`**: A base class for all enemies that implements shared behaviors (movement with separation avoidance, health management, damage logic, and pooling integration).

### 4. Mob Skill System
Mob behaviors are modularized through the `MobSkill` resource system:
- **`MobSkill` (Base)**: Defines the interface for skills, including `cooldown` management, `can_use()` checks, and the `_execute()` logic.
- **Implementations**:
    - `MeleeAttackMobSkill`: Handles short-range attacks, spawning a `Slash` effect after an animation.
    - `RangedAttackMobSkill`: Fires projectiles towards the player.
- **Execution Flow**:
    1. During `_ready()`, `Mob.gd` duplicates skills from its `MobData` to ensure unique cooldown state.
    2. In `_physics_process()`, specific mob scripts (e.g., `warrior.gd`) call `process_skills(delta)` to update cooldowns.
    3. The mob iterates through its skills; the first one to return `true` for `can_use()` is triggered via `use()`.
    4. Skills typically play an animation on the mob and use callbacks to trigger the actual effect (spawning bullets/slashes) at the right moment.

### 5. Performance Optimization: Object Pooling
To prevent frame stutters during high-action sequences, the project aggressively uses object pooling for:
- **Mobs**: Managed via `MobContainer` in the main level.
- **Projectiles**: Bullets, slashes, and mob bullets are pooled.
- **Pickups**: XP orbs and ammo boxes are pooled.
- **Registration**: Pools are registered and cleared in `main.gd` upon level load.

## Key Systems

### Player System (`Player.gd`)
Manages player state (HP, XP, Ammo, Stamina) and complex input logic (movement, rolling with i-frames, and multiple skill types). It synchronizes its state by emitting events to the global bus rather than updating UI directly.

### Enemy Spawning (`EnemySpawner.gd`)
Handles a progressive difficulty ramp. It calculates spawn intervals and wave sizes based on elapsed time (`ramp_duration_sec`). Spawning occurs on a ring just outside the player's viewport, clamped to the level boundaries.

### UI Architecture
UI components (e.g., `hp_label.tscn`, `xp_bar.tscn`) are isolated and self-sufficient. They connect to `Events` signals on `_ready()` to update their visuals, making them easy to swap or modify without touching gameplay code.

### Collision Layers
Defined in `Globals.CollisionLayer`:
- `WORLD` (1): Static geometry.
- `PLAYER` (2): Player body.
- `MOB` (4): Enemy bodies.
- `PLAYER_ATTACK` (8): Bullets/Slashes from player.
- `MOB_ATTACK` (16): Projectiles from enemies.

## Development Workflow
- **Adding an Enemy:** Create a new `MobData` resource, assign its sprite/scene, and add it to the `EnemySpawner` or `Data` registry.
- **Adding a Sound:** Register the `AudioStream` in `Data.gd` and call `Audio.play_sfx()`.
- **UI Changes:** Modify the specific UI scene; logic remains tied to the `Events` bus.
