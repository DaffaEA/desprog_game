# Digital Descent 3D — Game Documentation

## 1. Overview

**Digital Descent 3D** is a first-person 3D stealth puzzle game built in Godot 4.6. The player infiltrates a compromised server facility and must complete a 5-step sequence — find a Fuse, restore power, retrieve a Network Key, reboot the server, and escape through the Exit Door — all while evading 4 patrolling security bots that chase on sight and kill on contact. There is no combat. Survival depends entirely on stealth, timing, and spatial awareness.

| Field | Value |
|-------|-------|
| Genre | First-person stealth puzzle |
| Engine | Godot 4.6 |
| Language | GDScript |
| Physics | Jolt Physics |
| Renderer | Forward+ (D3D12) |
| Target Platform | PC (Windows) |

---

## 2. Game Objective

### Win Condition (5-Step Sequence)
1. Find the **Fuse** (instant pickup)
2. Use the **Power Panel** (hold [E] 3s, requires Fuse)
3. Find the **Network Key** (instant pickup, requires Power)
4. **Reboot the Server** (hold [E] 3s, requires Power + Key)
5. Enter the **Exit Door** (unlocks when server is rebooted)
6. "YOU WIN!" screen appears

### Lose Conditions
- **Bot contact**: Any bot's KillZone touches the player → "CAUGHT!" death screen
- **Falling**: Player falls below Y = -10 → death screen

### Progression Gating
Each step requires the previous one. Items and panels show contextual prompts ("Needs Fuse", "No Power", etc.) if prerequisites aren't met.

---

## 3. Story Premise

A server facility has been compromised by a rogue system. The player is an infiltrator tasked with restoring operations. First, power must be restored using a backup fuse. Then the Network Key can be retrieved, the server rebooted, and finally the exit unlocked. Security bots patrol the facility — they were designed to protect, but now they hunt. No weapons. No backup. Get in, reboot, get out.

---

## 4. Controls

| Input | Action |
|-------|--------|
| W / A / S / D | Move forward / left / back / right |
| Mouse | Look around (captured on left-click) |
| E | Interact / Hold to interact |
| Shift | Sprint (7 → 10 speed) |
| ESC | Release mouse cursor |
| R | Restart (on win/death screens) |
| Left Click | Capture mouse (lock cursor) |

---

## 5. Gameplay Mechanics

### Movement
- Base walk speed: **7.0** units/s
- Sprint speed: **10.0** units/s
- Jump velocity: **4.5** units/s
- Gravity: engine default

### Interaction System
The player has a RayCast3D (2.5m range) from the camera head. Objects in range with `interact()` or `interact_hold()` methods become interactable.

**Two interaction types:**

| Type | Method | Examples | Behavior |
|------|--------|---------|----------|
| Instant | `interact(player)` | Fuse, Network Key | Fires immediately on E press |
| Hold | `interact_hold(player, delta)` | Power Panel, Server | Requires holding E; fills progress bar over 3s |

### Fuse Pickup
- Walk within range and press E
- Sets `GameManager.has_fuse = true`
- Fuse object is removed from the scene (`queue_free()`)
- HUD shows "Picked up Fuse!" for 2 seconds
- Status indicator updates to "Fuse: Yes"

### Power Panel
- Requires `GameManager.has_fuse == true`
- Shows prompt "Hold [E] to Activate Power" (or "Needs Fuse" if lacking)
- Progress bar fills from 0 to 100 over 3 seconds
- Releasing E resets progress to 0
- On completion: sets `GameManager.power_on = true`, emits `power_activated` signal

### Network Key Pickup
- Requires `GameManager.power_on == true` (silently fails if no power)
- Walk within range and press E
- Sets `GameManager.has_key = true`
- Key object is removed from the scene (`queue_free()`)
- HUD shows "Picked up Network Key!" for 2 seconds

### Server Reboot
- Requires `GameManager.power_on == true` AND `GameManager.has_key == true`
- Shows prompt "Hold [E] to Reboot Server" (or "No Power" / "Needs Network Key")
- Progress bar fills from 0 to 100 over 3 seconds
- Releasing E resets progress to 0
- On completion: sets `GameManager.server_on = true`, emits `server_rebooted` signal

### Exit Door
- Monitors `GameManager.server_on` every frame
- When `server_on` becomes true: disables blocker collision, mesh turns green
- When player enters DetectionZone while unlocked: emits `door_entered` signal → win screen

---

## 6. Enemy AI

Each bot uses a finite state machine with three states:

```
IDLE ←→ PATROL ←→ CHASE
```

### States

| State | Speed | Color | Behavior |
|-------|-------|-------|----------|
| IDLE | 0 units/s | Gray (0.5, 0.5, 0.5) | Pauses at patrol point for `idle_time` (3s default) |
| PATROL | 3.0 units/s | Red | Walks between fixed waypoints, ping-pongs A→B→C→D→C→B |
| CHASE | 6.0 units/s | Yellow | Pathfinds directly to player's current position |

### Patrol Waypoints
- Each bot has an `@export var patrol_points: Array[Vector3]` set in the editor
- Bots ping-pong through points: forward to end, then reverse to start
- If `patrol_points` is empty, falls back to random wandering (20-unit radius)
- Bot pauses 3 seconds (IDLE) at each waypoint before moving to next

### Detection
- **DetectionZone** (Area3D): When the player enters → switch to CHASE, store player reference
- **DetectionZone exit**: When the player leaves → switch to PATROL, resume current waypoint
- **KillZone** (Area3D): When the player enters → trigger death screen

### Navigation
- Each bot has a `NavigationAgent3D` for pathfinding on the level's navmesh
- In PATROL: follows fixed waypoint array, ping-ponging
- In CHASE: continuously updates target to player's global position
- Bots rotate to face their movement direction

### Visual Feedback
- **Gray** mesh = idle (bot is paused at a waypoint)
- **Red** mesh = patrolling (bot is moving between waypoints)
- **Yellow** mesh = chasing (player is detected, run)
- Material is duplicated per-instance to allow independent colors

---

## 7. Level Design

### Arena Layout

```
              N
     ┌──────────────────┐
     │    SERVER   EXIT  │  ← NE: Server (~19.7, 0.6, 19.9)
     │                  │     E:  ExitDoor (~24, 1.25, 0)
     │  ┌──┐      ┌──┐  │
     │  │  │      │  │  │
     │  └──┘      └──┘  │
     │                  │
POWER │                  │  FUSE
PANEL │                  │  ← SE: Fuse (~20, 0.5, -20)
← W:  │                  │
(-24, │                  │
 1,0) │                  │
     │  ┌──┐      ┌──┐  │
     │  │  │      │  │  │
     │  └──┘      └──┘  │
     │                  │
     │     KEY          │  ← SW: NetworkKey (~-17.3, 0.2, -21.2)
     └──────────────────┘
              S
     ↑ Player spawns here (~0.6, 1.4, 22.2)
```

### Element Positions

| Element | Position | Interaction | Notes |
|---------|----------|-------------|-------|
| Player Spawn | (~0.6, 1.4, 22.2) | — | South side |
| Fuse | (~20, 0.5, -20) | Instant pickup | SE corner |
| Power Panel | (~-24, 1.0, 0) | Hold 3s, needs Fuse | West wall |
| Network Key | (~-17.3, 0.2, -21.2) | Instant pickup, needs Power | SW corner |
| Server | (~19.7, 0.6, 19.9) | Hold 3s, needs Power + Key | NE corner |
| Exit Door | (~24, 1.25, 0) | Enter when unlocked | East wall |
| Arena Size | 50 × 50 units | — | Bounded area |
| NavMesh | Region3D | — | Covers walkable floor |

### Bot Patrol Points

| Bot | Area | Patrol Points (x, z) |
|-----|------|----------------------|
| Bot 1 | NE | (20,-5), (20,5), (15,10), (10,5) |
| Bot 2 | Center | (0,7), (-8,7), (-8,-2), (0,-2) |
| Bot 3 | SE | (8,-18), (18,-18), (18,-8), (8,-8) |
| Bot 4 | NW | (-18,18), (-18,8), (-10,8), (-10,18) |

### Design Rationale
- **5-step sequence spans the entire arena** — Fuse (SE) → Power (W) → Key (SW) → Server (NE) → Exit (E)
- **4 bots with fixed waypoints** cover different quadrants, making every crossing dangerous
- **CSG walls** create sightline breaks and hiding spots essential for stealth
- **IDLE pauses** at waypoints give windows of opportunity for the player to sneak past
- **Exit Door on the east wall** requires a final crossing after the server reboot in the NE corner

---

## 8. Core Game Loop

```
┌──────────────────────────────────────────────────────┐
│                       START                           │
│                  Player spawns (south)                │
│                       │                              │
│                       ▼                              │
│            Navigate to Fuse (SE corner)               │
│                 Press [E] to pick up                  │
│                       │                              │
│                       ▼                              │
│            Navigate to Power Panel (W wall)           │
│            Hold [E] 3s → Power ON                    │
│                       │                              │
│                       ▼                              │
│            Navigate to Network Key (SW corner)        │
│            Press [E] to pick up (needs power)         │
│                       │                              │
│                       ▼                              │
│            Navigate to Server (NE corner)             │
│            Hold [E] 3s → Server rebooted             │
│                       │                              │
│                       ▼                              │
│            Navigate to Exit Door (E wall)             │
│            Enter unlocked door → YOU WIN!             │
│                       │                              │
│              ┌────────┴────────┐                      │
│              ▼                 ▼                      │
│         YOU WIN!          Bot contact                │
│         Timer stops       or fall off map            │
│              │                 │                      │
│              ▼                 ▼                      │
│          Press R          CAUGHT!                     │
│          to restart     Auto-reload (2s)              │
│              │                 │                      │
│              └────────┬────────┘                      │
│                       ▼                              │
│               Press [R] to Restart                    │
└──────────────────────────────────────────────────────┘
```

### Timing
- Timer starts on spawn, counts up in MM:SS format
- Timer stops on win or death
- Timer is visible top-right at all times

---

## 9. UI / HUD

All UI elements are in a `CanvasLayer` node (`UI/control.tscn`) that persists across game states.

| Element | Type | Position | Behavior |
|---------|------|----------|----------|
| InteractPrompt | Label | Bottom-center, white 20px | Shows contextual prompt (pickup, hold, needs item) |
| InteractBar | ProgressBar | Bottom-center | Visible only while holding E; fills 0→100 |
| TimerLabel | Label | Top-right | MM:SS elapsed time; stops on game over |
| StatusFuse | Label | Top-left, y:10-35 | "Fuse: No" / "Fuse: Yes" |
| StatusPower | Label | Top-left, y:30-55 | "Power: No" / "Power: Yes" |
| StatusKey | Label | Top-left, y:50-75 | "Key: No" / "Key: Yes" |
| StatusServer | Label | Top-left, y:70-95 | "Server: No" / "Server: Yes" |
| WinLabel | Label | Center, green 64px | "YOU WIN!" — shown on door entry |
| DeathLabel | Label | Center, red 64px | "CAUGHT!" — shown on bot kill or fall |
| RestartLabel | Label | Below win/death | "Press R to Restart" — visible on game over |

### HUD State Machine

| State | Visible | Hidden |
|-------|---------|--------|
| Playing | Timer, Status (×4), Prompt (conditional), Bar (conditional) | Win, Death, Restart |
| Win | Timer (frozen), Status (×4), Win, Restart | Prompt, Bar, Death |
| Death | Timer (frozen), Status (×4), Death | Prompt, Bar, Win, Restart (auto-reloads after 2s) |

---

## 10. Technical Specifications

| Component | Detail |
|-----------|--------|
| Engine | Godot 4.6 |
| Scripting | GDScript |
| Physics Engine | Jolt Physics (via Godot addon) |
| Rendering | Forward+ pipeline, D3D12 driver |
| Player Controller | ProtoController v1.1 (Brackeys, CC0) — modified with interaction system |
| AI Navigation | NavigationAgent3D + NavigationRegion3D navmesh |
| Collision | CharacterBody3D (player/bots), StaticBody3D (items/panels/door/walls) |
| Detection | Area3D with `body_entered`/`body_exited` signals |
| State Management | GameManager autoload (singleton) |

### Project Configuration
- **Autoload**: `GameManager` → `res://game_manager.gd`
- Input mappings: `move_forward`, `move_left`, `move_right`, `move_back`, `interact`, `sprint`
- Global group: `player` — used by bots to identify the player body
- Main scene: `main.tscn`

---

## 11. Architecture & Signals

### GameManager (Autoload Singleton)

```
game_manager.gd (extends Node)
├── has_fuse: bool = false
├── power_on: bool = false
├── has_key: bool = false
├── server_on: bool = false
├── game_over: bool = false
└── reset() → sets all to false
```

### Node Hierarchy (main.tscn)

```
Root (Node3D)
├── ProtoController (CharacterBody3D) ─── "player" group
│   ├── Head (Node3D)
│   │   ├── Camera3D
│   │   └── RayCast3D (2.5m range)
│   └── Collider (CollisionShape3D)
├── Bot × 4 (CharacterBody3D)
│   ├── MeshInstance3D (capsule)
│   ├── DetectionZone (Area3D + CollisionShape3D)
│   ├── KillZone (Area3D + CollisionShape3D)
│   └── NavigationAgent3D
├── Fuse (StaticBody3D)              ← NEW
├── PowerPanel (StaticBody3D)        ← NEW
├── Server (StaticBody3D)
├── NetworkKey (StaticBody3D)
├── ExitDoor (StaticBody3D)          ← NEW
│   ├── MeshInstance3D (door)
│   ├── BlockerCollision (CollisionShape3D)
│   └── DetectionZone (Area3D)
├── NavigationRegion3D (navmesh)
├── CSG walls × N (CSGBox3D)
├── DirectionalLight3D
├── WorldEnvironment
└── CanvasLayer (HUD)
    ├── InteractPrompt (Label)
    ├── InteractBar (ProgressBar)
    ├── TimerLabel (Label)
    ├── StatusFuse (Label)
    ├── StatusPower (Label)
    ├── StatusKey (Label)
    ├── StatusServer (Label)
    ├── WinLabel (Label)
    ├── DeathLabel (Label)
    └── RestartLabel (Label)
```

### Signal Flow

```
Fuse.interact() ─────────────→ GameManager.has_fuse = true
                                   └── HUD: "Fuse: Yes"

PowerPanel.power_activated ──→ GameManager.power_on = true
                                   └── HUD: "Power: Yes"

NetworkKey.interact() ───────→ GameManager.has_key = true
                              │       (requires GameManager.power_on)
                              └── HUD: "Key: Yes"

Server.server_rebooted ──────→ GameManager.server_on = true
                              │       (requires power_on AND has_key)
                              └── HUD: "Server: Yes"

GameManager.server_on ───────→ ExitDoor.unlock()
                                   ├── BlockerCollision.disabled = true
                                   └── Mesh color → green

ExitDoor.door_entered ───────→ CanvasLayer.show_win_screen()
                                   ├── game_over = true
                                   ├── WinLabel.visible = true
                                   ├── RestartLabel.visible = true
                                   └── get_tree().paused = true

Bot.DetectionZone.body_entered → Bot._on_detection_zone_body_entered()
                                   ├── player = body
                                   ├── current_state = CHASE
                                   └── mesh color = YELLOW

Bot.DetectionZone.body_exited → Bot._on_detection_zone_body_exited()
                                   ├── current_state = PATROL
                                   ├── mesh color = RED
                                   └── resume current waypoint

Bot.KillZone.body_entered ───→ CanvasLayer.show_death_screen()
                                   ├── game_over = true
                                   ├── DeathLabel.visible = true
                                   └── auto-reload after 2s

Player RayCast3D ──→ interact() or interact_hold()
                        ├── Fuse: GameManager.has_fuse = true
                        ├── Key: GameManager.has_key = true (if power_on)
                        ├── PowerPanel: fills ProgressBar → GameManager.power_on
                        └── Server: fills ProgressBar → GameManager.server_on

Player Y < -10 ──────→ CanvasLayer.show_death_screen()

Restart (R key) ────→ GameManager.reset() → reload scene
```

---

## 12. File Structure

```
desprog_game/
├── project.godot              # Engine config: inputs, autoload, physics, renderer
├── game_manager.gd            # Autoload singleton: game state (has_fuse, power_on, has_key, server_on)
├── main.tscn                  # Main level scene: arena, bots, items, panels, door, navmesh, HUD
├── icon.svg                   # Project icon
│
├── addons/
│   └── proto_controller/
│       ├── proto_controller.gd    # FPS controller + interaction system + fall detection
│       └── proto_controller.tscn  # Player scene: body, camera, head RayCast3D
│
├── bot/
│   ├── bot.gd                 # AI: IDLE/PATROL/CHASE FSM, fixed waypoints, color feedback
│   └── bot.tscn               # Bot scene: capsule mesh, DetectionZone, KillZone, NavigationAgent3D
│
├── Server/
│   ├── Server.gd              # Hold-to-interact (3s), requires power+key, sets server_on
│   └── Server.tscn            # Server scene: StaticBody3D box
│
├── Key/
│   ├── NetworkKey.gd          # Instant pickup, requires power_on, sets has_key
│   └── NetworkKey.tscn        # Key scene: small box StaticBody3D
│
├── Fuse/
│   ├── Fuse.gd                # Instant pickup, sets has_fuse
│   └── Fuse.tscn              # Fuse scene: small box StaticBody3D
│
├── PowerPanel/
│   ├── PowerPanel.gd          # Hold-to-interact (3s), requires fuse, sets power_on
│   └── PowerPanel.tscn        # Panel scene: wall-mounted StaticBody3D
│
├── ExitDoor/
│   ├── ExitDoor.gd            # Monitors server_on, unlocks door, emits door_entered
│   └── ExitDoor.tscn          # Door scene: StaticBody3D with blocker + detection zone
│
└── UI/
    ├── control.gd             # CanvasLayer: timer, 4 status labels, win/death/restart screens
    └── control.tscn           # HUD layout: prompt, progress bar, timer, status, overlays
```

---

## 13. Credits

| Asset / Component | Author | License |
|-------------------|--------|---------|
| ProtoController v1.1 | Brackeys | CC0 (Public Domain) |
| Godot Engine | Juan Linietsky, Ariel Manzur & contributors | MIT |
| Jolt Physics | Jorrit Rouwe | MIT |

---

*Digital Descent 3D — Semester 6, DPG Course*
