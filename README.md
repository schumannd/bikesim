# BikeSim

Godot 4 prototype: build bikes, ride an open city, complete quests. Gameplay and controls are documented in [GAME.md](GAME.md).

## Requirements

- [Godot 4.x](https://godotengine.org/) (4.6+ used in CI)
- Export templates (only for desktop builds)

## Run locally

1. Clone the repository.
2. Open the project folder in Godot.
3. Main scene is `res://scenes/Main.tscn` (set in `project.godot`).
4. Press **Play** (F5).

From the terminal (with `godot` on your `PATH`):

```bash
godot --path . res://scenes/Main.tscn
```

## Project structure

| Path | Purpose |
|------|---------|
| `scenes/` | Main scenes (`Main`, menus, ride, garage, character editor) |
| `scripts/` | Gameplay and UI |
| `systems/` | Autoloads (`GameState`, `SaveSystem`, `Settings`, `BackgroundMusic`, `SoundEffects`) |
| `resources/` | Config resources (`BikeConfig`, `CharacterConfig`) |
| `tasks/` | One markdown file per bug/feature; completed work in `tasks/done/` |
| `export_presets.cfg` | Desktop export presets |

## Export (desktop)

1. Install export templates for your Godot version (**Editor → Manage Export Templates**).
2. Review presets in `export_presets.cfg`.
3. Export targets:
   - Windows: `build/windows/BikeSim.exe`
   - Linux: `build/linux/BikeSim.x86_64`
   - macOS: `build/macos/BikeSim.zip`

## Tests

**UI smoke test** (headless, ~30s):

```bash
./scripts/ci/run_ui_smoke_test.sh
```

Override timeout: `UI_SMOKE_TIMEOUT_SECONDS=45 ./scripts/ci/run_ui_smoke_test.sh`

Covers: main menu → new game → character editor → ride → garage → character menu → settings → back.

**CI:** `.github/workflows/ui-smoke-test.yml` runs the same test on push and pull request.

## Contributing

1. Track work in `tasks/` — one file per item; move finished items to `tasks/done/`.
2. Run `./scripts/ci/run_ui_smoke_test.sh` before opening a PR.
3. Keep changes focused; match existing code style in nearby files.
4. Agents: see [AGENTS.md](AGENTS.md) for commit and push expectations.
