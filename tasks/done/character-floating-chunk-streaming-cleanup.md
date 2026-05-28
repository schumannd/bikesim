# Character floating and chunk streaming cleanup

**Status:** Done  
**Date:** 2026-05-28

## Problem

Character still floating; prior floating/fall fixes needed cleanup.

## Fix

Replaced rider offset tweaks with bike `SeatAnchor` attachment and simplified chunk streaming to one radius-based system (removed layered look-ahead/unload logic).
