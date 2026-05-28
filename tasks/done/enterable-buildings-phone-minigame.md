# Enterable buildings, living room, and phone minigame

**Status:** Done  
**Date:** 2026-05-28

## Summary

Some city buildings have a golden door marker. Enter to visit a generated living room with NPCs, dialogue, and a phone sliding-stone minigame (mouse-driven credit card, 2D physics).

## Implementation

- `ProceduralCity.gd` — one enterable building per chunk, `HouseEntrance` zone
- `HouseInteriorScene` + `LivingRoomBuilder` + `InteriorNPC`
- `PhoneMinigame.gd` — RigidBody2D stones, card pushes with friction/gravity
- `GameState.begin_house_visit` / `queue_house_exit` — return to door outside
