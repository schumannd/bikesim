# BikeSim

3D bicycle building and riding simulator prototype in Godot 4.


## Controls (Default)

- `W/S`: accelerate / reverse
- `A/D`: steer
- `Space`: brake
- `R`: quick reset to latest spawn/checkpoint
- `G`: open garage
- `C`: open character customization

## Project Structure

- `scenes/`: main scenes (`Main`, `RideScene`, `GarageScene`, `CharacterCustomizationScene`)
- `scripts/`: gameplay and UI scripts
- `systems/`: autoload singletons (`GameState`, `SaveSystem`, `Settings`)
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
  - Initial ride screen is loaded
  - Garage menu opens and returns to ride scene
  - Character customization menu opens and returns to ride scene
- CI:
  - GitHub Actions workflow at `.github/workflows/ui-smoke-test.yml` runs the same smoke test on push and pull request.

## Next Expansion (Post-MVP)

- Quest system and progression.
- NPC interaction/dialogue.
- House interior enter/exit flow.
- In-house phone minigame.