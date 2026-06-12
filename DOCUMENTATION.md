# Digital Descent 3D — Game Documentation

## 1. Overview

**Digital Descent 3D** is a first-person 3D stealth game built in Godot 4.6. The player infiltrates a compromised server facility, locates a Network Key, and reboots a central server — all while evading 4 patrolling security bots that chase on sight and kill on contact. There is no combat. Survival depends entirely on stealth, timing, and spatial awareness.

| Field | Value |
|-------|-------|
| Genre | First-person stealth |
| Engine | Godot 4.6 |
| Language | GDScript |
| Physics | Jolt Physics |
| Renderer | Forward+ (D3D12) |
| Target Platform | PC (Windows) |

---

## 2. Game Objective

### Win Condition
1. Find the **Network Key** (instant pickup)
2. Navigate to the **Server** terminal
3. **Hold [E] for 3 seconds** to reboot the server
4. "YOU WIN!" screen appears

### Lose Conditions
- **Bot contact**: Any bot's KillZone touches the player → "CAUGHT!" death screen
- **Falling**: Player falls below Y = -10 → death screen

---

## 3. Story Premise

A server facility has been compromised by a rogue system. The player is an infiltrator tasked with restoring operations by locating a Network Key and rebooting the central server. Security bots patrol the facility — they were designed to protect, but now they hunt. No weapons. No backup. Get in, reboot, get out.

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

| Type | Method | Example | Behavior |
|------|--------|---------|----------|
| Instant | `interact(player)` | Network Key | Fires immediately on E press |
| Hold | `interact_hold(player, delta)` | Server | Requires holding E; fills progress bar over 3s |

### Network Key Pickup
- Walk within range and press E
- Sets `player.has_network_key = true`
- Key object is removed from the scene (`queue_free()`)
- HUD shows "Picked up Network Key!" for 2 seconds
- Key indicator updates to "Key: Yes"

### Server Reboot
- Requires `has_network_key == true`
- Shows prompt "Hold [E] to Reboot Server" (or "Needs Network Key" if lacking the key)
- Progress bar fills from 0 to 100 over 3 seconds
- Releasing E resets progress to 0
- On completion: emits `server_rebooted` signal → win screen

---

## 6. Enemy AI

Each bot uses a finite state machine with two states:

```
PATROL ←→ CHASE
```

### States

| State | Speed | Color | Behavior |
|-------|-------|-------|----------|
| PATROL | 3.0 units/s | Red | Wanders randomly within `patrol_radius` (20 units) |
| CHASE | 6.0 units/s | Yellow | Pathfinds directly to player's current position |

### Detection
- **DetectionZone** (Area3D): When the player enters → switch to CHASE, store player reference
- **DetectionZone exit**: When the player leaves → switch to PATROL, pick new random patrol point
- **KillZone** (Area3D): When the player enters → trigger death screen

### Navigation
- Each bot has a `NavigationAgent3D` for pathfinding on the level's navmesh
- In PATROL: picks random direction × patrol_radius as target
- In CHASE: continuously updates target to player's global position
- Bots rotate to face their movement direction

### Visual Feedback
- **Red** mesh = patrolling (safe to sneak around)
- **Yellow** mesh = chasing (player is detected, run)
- Material is duplicated per-instance to allow independent colors

---

## 7. Level Design

### Arena Layout

```
        N
   ┌────────────┐
   │    SERVER   │  ← NE corner (~19.7, 0.6, 19.9)
   │  ┌──┐      │
   │  │  │      │
   │  └──┐      │
   │     └──┐   │
   │   walls │  │
   │  ┌──┐   │  │
   │  │  │   │  │
   │  └──┘   │  │
   │     KEY  │  ← SW corner (~-17.3, 0.2, -21.2)
   └────────────┘
        S
   ↑ Player spawns here (~0.6, 1.4, 22.2)
```

### Key Details

| Element | Position | Notes |
|---------|----------|-------|
| Player Spawn | (~0.6, 1.4, 22.2) | South side |
| Network Key | (~-17.3, 0.2, -21.2) | SW corner |
| Server | (~19.7, 0.6, 19.9) | NE corner |
| Arena Size | 50 × 50 units | Bounded area |
| Walls | CSG boxes | Provide cover from bots |
| Bots | 4 instances | Spread across arena |
| NavMesh | Region3D | Covers walkable floor |

### Design Rationale
- **Key and Server are on opposite corners** — forces the player to traverse the entire arena
- **4 bots** provide coverage that makes a straight-line path impossible
- **CSG walls** create sightline breaks and hiding spots essential for stealth
- **Open spawn in the south** gives the player a safe starting area to orient

---

## 8. Core Game Loop

```
┌─────────────────────────────────────────────────┐
│                   START                          │
│              Player spawns (south)               │
│                    │                             │
│                    ▼                             │
│         Navigate to Network Key (SW)             │
│              Press [E] to pick up                │
│                    │                             │
│                    ▼                             │
│         Sneak / Sprint to Server (NE)            │
│         Evade 4 patrolling bots                  │
│                    │                             │
│           ┌────────┴────────┐                    │
│           ▼                 ▼                    │
│      Hold [E] 3s        Bot contact             │
│      Progress bar        or fall off map         │
│           │                 │                    │
│           ▼                 ▼                    │
│       YOU WIN!          CAUGHT!                  │
│      Timer stops      Auto-reload (2s)           │
│           │                 │                    │
│           └────────┬────────┘                    │
│                    ▼                             │
│            Press [R] to Restart                  │
└─────────────────────────────────────────────────┘
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
| InteractPrompt | Label | Bottom-center, white 20px | Shows contextual prompt (pickup, hold, needs key) |
| InteractBar | ProgressBar | Bottom-center | Visible only while holding E on server; fills 0→100 |
| TimerLabel | Label | Top-right | MM:SS elapsed time; stops on game over |
| KeyLabel | Label | Top-left | "Key: No" / "Key: Yes"; updates on pickup |
| WinLabel | Label | Center, green 64px | "YOU WIN!" — shown on server reboot |
| DeathLabel | Label | Center, red 64px | "CAUGHT!" — shown on bot kill or fall |
| RestartLabel | Label | Below win/death | "Press R to Restart" — visible on game over |

### HUD State Machine

| State | Visible | Hidden |
|-------|---------|--------|
| Playing | Timer, Key, Prompt (conditional), Bar (conditional) | Win, Death, Restart |
| Win | Timer (frozen), Key, Win, Restart | Prompt, Bar, Death |
| Death | Timer (frozen), Key, Death | Prompt, Bar, Win, Restart (auto-reloads after 2s) |

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
| Collision | CharacterBody3D (player/bots), StaticBody3D (key/server/walls) |
| Detection | Area3D with `body_entered`/`body_exited` signals |

### Project Configuration
- Input mappings: `move_forward`, `move_left`, `move_right`, `move_back`, `interact`, `sprint`
- Global group: `player` — used by bots to identify the player body
- Main scene: `main.tscn`

---

## 11. Architecture & Signals

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
├── Server (StaticBody3D)
├── NetworkKey (StaticBody3D)
├── NavigationRegion3D (navmesh)
├── CSG walls × N (CSGBox3D)
├── DirectionalLight3D
├── WorldEnvironment
└── CanvasLayer (HUD)
    ├── InteractPrompt (Label)
    ├── InteractBar (ProgressBar)
    ├── TimerLabel (Label)
    ├── KeyLabel (Label)
    ├── WinLabel (Label)
    ├── DeathLabel (Label)
    └── RestartLabel (Label)
```

### Signal Flow

```
Server.server_rebooted ──────→ CanvasLayer.show_win_screen()
                                    │
                                    ├── game_over = true
                                    ├── WinLabel.visible = true
                                    ├── RestartLabel.visible = true
                                    └── get_tree().paused = true

Bot.DetectionZone.body_entered → Bot._on_detection_zone_body_entered()
                                    │
                                    ├── player = body
                                    ├── current_state = CHASE
                                    └── mesh color = YELLOW

Bot.DetectionZone.body_exited → Bot._on_detection_zone_body_exited()
                                    │
                                    ├── current_state = PATROL
                                    ├── mesh color = RED
                                    └── set_new_patrol_point()

Bot.KillZone.body_entered ────→ CanvasLayer.show_death_screen()
                                    │
                                    ├── game_over = true
                                    ├── DeathLabel.visible = true
                                    └── auto-reload after 2s

Player RayCast3D ──→ interact() or interact_hold()
                        │
                        ├── Key: player.has_network_key = true → CanvasLayer.update_key_status(true)
                        └── Server: fills ProgressBar → emits server_rebooted

Player Y < -10 ──────→ CanvasLayer.show_death_screen()
```

---

## 12. File Structure

```
desprog_game/
├── project.godot              # Engine config: inputs, physics, renderer
├── main.tscn                  # Main level scene: arena, bots, key, server, navmesh, HUD
├── icon.svg                   # Project icon
│
├── addons/
│   └── proto_controller/
│       ├── proto_controller.gd    # FPS controller + interaction system + fall detection
│       └── proto_controller.tscn  # Player scene: body, camera, head RayCast3D
│
├── bot/
│   ├── bot.gd                 # AI: PATROL/CHASE FSM, nav agent, color feedback
│   └── bot.tscn               # Bot scene: capsule mesh, DetectionZone, KillZone, NavigationAgent3D
│
├── Server/
│   ├── Server.gd              # Hold-to-interact (3s), requires key, emits server_rebooted
│   └── Server.tscn            # Server scene: StaticBody3D box
│
├── Key/
│   ├── NetworkKey.gd          # Instant pickup, sets player.has_network_key, removes self
│   └── NetworkKey.tscn        # Key scene: small box StaticBody3D
│
└── UI/
    ├── control.gd             # CanvasLayer: timer, key status, win/death/restart screens
    └── control.tscn           # HUD layout: prompt, progress bar, timer, key indicator, overlays
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
