# BikeSim — Player Guide

3D bicycle building and riding simulator. Customize your bike and rider, explore a procedural city, complete quests, and visit the garage.

## Controls

| Key | Action |
|-----|--------|
| `W` / `S` | Accelerate / reverse |
| `A` / `D` | Steer |
| `Space` | Brake |
| `R` | Quick reset to latest spawn |
| `E` | Interact (quest, apartment door) |
| `G` | Open garage |
| `C` | Open character customization |

Main menu: **W/S** or **↑/↓** to navigate, **Enter** to select.

## Main Menu

- **New Game** — fresh save in the first empty slot (or slot 1 if all are full)
- **Continue (3 slots)** — load a save; hover or highlight a slot to preview bike + rider (empty slots cannot be loaded)
- **Settings** — frame rate limit and quality preset
- **Quit**

## Character

- **New Game** opens the character editor (3D preview) before the first ride.
- Press **C** while riding to edit your character anytime.
- The **wizard tower** opens the same editor when you enter it.

## Garage

Press **G** while riding to customize frame, wheels, parts, and per-part paint. Leave the garage to return to the world.

## Quest

- Ride to the **golden mist** quest giver (NPC) and press **E** to start.
- Follow **blue checkpoints**; a large arrow points to the next one.
- The **checkered finish** checkpoint completes the quest and pays **$2.00**.
- You start with **$0.20** (shown top-right).

## World

The city is **hilly** — you roll faster downhill and slow down when climbing.

Districts include **highways** (wide roads on the main axes), **big streets**, **small streets**, **suburbs**, **parks**, **schools**, **stadiums**, and **train stations**. **Diagonal train tracks** cut across the map with gravel beds and rails.

Sidewalks, street furniture, lit windows, and NPCs fill the streets. Each save places a **secret purple wizard tower** in one distant chunk (purple minimap marker).

## Apartments

Many chunks have one building with a **golden door** (ride into the doorway or press **E** at the door).

Inside you get a generated **living room** with a few NPCs:

| Key | Action |
|-----|--------|
| `W` / `S` or `↑` / `↓` | Select who to talk to |
| `E` | Next dialogue line |
| `P` | Focus on the phone (stone-sliding minigame) |
| `Esc` | Leave apartment (or exit minigame back to room) |

**Phone minigame:** stones sit on a virtual phone screen. Move the **credit card** with your **mouse** and push every stone past the **left edge** (friction + gravity apply). Press **Esc** to return to the room.

## Planned

- Deeper NPC dialogue trees
- House interior enter/exit polish (map markers)
