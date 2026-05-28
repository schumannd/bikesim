# City districts, train tracks, and hill physics

**Status:** Done  
**Date:** 2026-05-28

## Summary

Replaced flat uniform grid with zoned city generation, heightmapped terrain, diagonal train corridors, landmark chunks (school/stadium/station), and bike slope gravity (coast downhill, struggle uphill).

## Key files

- `scripts/CityTerrain.gd` — height sampling, zone types, road widths
- `scripts/WorldLandmarks.gd` — trains, school, stadium, station
- `scripts/ProceduralCity.gd` — heightmap chunks, zone roads
- `scripts/BikeController.gd` — slope-assisted speed
- `scripts/BikeRig.gd` — spawn height from terrain
