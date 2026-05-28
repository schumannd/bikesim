# Bike/rider floating after anchor cleanup

**Status:** Done  
**Date:** 2026-05-28

## Problem

Rider and bike still visually floating after anchor cleanup.

## Fix

Consolidated placement into `scripts/BikeRig.gd` (single surface `y=0`, one rider mount, one fall reset). Removed per-frame snap/align hacks from `RideScene.gd`.
