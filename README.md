# BikeSim

PC-first 3D bicycle building and riding simulator prototype in Godot 4.

## MVP Implemented

- Ride a bike in a 3D open area with keyboard/controller controls.
- Garage customization for frame, wheels, handlebars, and paint color.
- Character customization for outfit, hair style, and colors.
- Save/load for bike + character setup (`user://savegame.json`).
- Tutorial mission steps and checkpoint progression in riding scene.
- Minimap placeholder panel with live rider marker.
- Scene flow: ride <-> garage <-> character customization.

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

## Next Expansion (Post-MVP)

- Quest system and progression.
- NPC interaction/dialogue.
- House interior enter/exit flow.
- In-house phone minigame.