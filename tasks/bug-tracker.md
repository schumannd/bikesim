# Bug Tracker

Tracks issues reported in chat and their fix status.

## 2026-05-28

- [x] Wheels were oriented perpendicular to driving direction.
  - Fix: corrected tire/rim orientation in `scripts/BikeVisualBuilder.gd`.
  - Commit: `20294d5`

- [x] Rider looked floating on bike.
  - Fix: adjusted rider pose and mount offset.
  - Commit: `98104bf`

- [x] Rider/buildings collision issues and temporary anti-fall hacks to remove.
  - Fix: added building colliders and removed temporary fall-map checks.
  - Commit: `2ed5899`

- [x] Bike and rider pedaling/gameplay feedback.
  - Fix: added visible pedals, pedaling animation, rolling friction, and physical garage location gate.
  - Commit: `a0df744`

- [x] Bike floating above ground (ride + garage preview).
  - Fix: lowered bike spawn/reset height in ride scene and corrected garage preview bike pivot height.

- [x] Character still floating + cleanup requested for prior floating/fall fixes.
  - Fix: replaced rider offset tweaks with bike `SeatAnchor` attachment and simplified chunk streaming to one clean radius-based system (removed layered look-ahead/unload logic).

- [x] Rider and bike still visually floating after anchor cleanup.
  - Fix: consolidated placement into `scripts/BikeRig.gd` (single surface `y=0`, one rider mount, one fall reset). Removed per-frame snap/align hacks from `RideScene.gd`.
