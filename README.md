# BikeSim

3D bicycle building and riding simulator prototype in Godot 4.


## Controls (Default)

- `W/S`: accelerate / reverse
- `A/D`: steer
- `Space`: brake
- `R`: quick reset to latest spawn/checkpoint
- `E`: interact (start quest at golden marker)
- `G`: open garage
- `C`: open character customization

## Quest

- Ride to the **golden mist** quest giver (NPC) and press **E** to start.
- Follow the **blue checkpoints**; a large arrow points to the next one.
- The **checkered finish** checkpoint completes the quest and pays **$2.00**.
- You start with **$0.20** (shown top-right).

## World

The open city includes procedural sidewalks, road markings, street furniture (trees, lamps, benches, signs), lit building windows, and NPCs that **stand**, **walk**, or **ride bikes** along paths near the player.

Each save seeds a **secret purple wizard tower** in one distant chunk (check the minimap for a purple marker). Ride into the tower entrance to open the appearance editor again.

## Character

- **New Game** opens a full character editor (3D preview) before the first ride.
- Press **C** while riding to edit your character anytime.
- The **wizard tower** also opens the same editor when you enter it.

## Main Menu

On launch you get a main menu with:

- **New Game** — starts a fresh save in the first empty slot (or slot 1 if all slots are full)
- **Continue (3 slots)** — load an existing save; hover a slot to preview bike + rider
- **Settings** — frame rate limit and quality preset
- **Quit**

## Project Structure

- `scenes/`: main scenes (`Main`, `MainMenuScene`, `RideScene`, `GarageScene`, `CharacterCustomizationScene`, `SettingsScene`)
- `scripts/`: gameplay and UI scripts
- `systems/`: autoload singletons (`GameState`, `SaveSystem`, `Settings`, `BackgroundMusic`)
- `resources/`: saved config resources (`BikeConfig`, `CharacterConfig`)
- `export_presets.cfg`: desktop export setup (Windows/Linux/macOS)

## Run

1. Open the project in Godot 4.x.
2. Ensure main scene is `res://scenes/Main.tscn` (already configured).
3. Press Play.

## PC Build Pipeline

1. In Godot, install export templates for your engine version.
2. Verify export presets from `export_presets.cfg`.
3. Export desktop targets:
   - Windows: `build/windows/BikeSim.exe`
   - Linux: `build/linux/BikeSim.x86_64`
   - macOS: `build/macos/BikeSim.zip`

## Automated UI Test Pipeline

- Local smoke test:
  - `./scripts/ci/run_ui_smoke_test.sh`
  - Default timeout is `30s` (override with `UI_SMOKE_TIMEOUT_SECONDS=45`).
- What it validates:
  - Game launches through `Main.tscn`
  - Main menu loads; new game opens the character editor then the ride scene
  - Garage menu opens and returns to ride scene
  - Character customization menu opens and returns to ride scene
  - Settings opens and returns to the main menu
- CI:
  - GitHub Actions workflow at `.github/workflows/ui-smoke-test.yml` runs the same smoke test on push and pull request.

## Next Expansion (Post-MVP)

- Quest system and progression.
- NPC interaction/dialogue.
- House interior enter/exit flow.
- In-house phone minigame.