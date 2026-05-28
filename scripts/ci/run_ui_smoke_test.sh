#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if ! command -v godot >/dev/null 2>&1; then
  echo "godot not found on PATH"
  exit 1
fi

TIMEOUT_SECONDS="${UI_SMOKE_TIMEOUT_SECONDS:-30}"
RUN_CMD=(godot --headless --path "$ROOT_DIR" --script "res://tests/ui_smoke_test.gd")

echo "Running UI smoke test with ${TIMEOUT_SECONDS}s timeout..."

if command -v timeout >/dev/null 2>&1; then
  timeout --foreground "${TIMEOUT_SECONDS}" "${RUN_CMD[@]}"
elif command -v gtimeout >/dev/null 2>&1; then
  gtimeout --foreground "${TIMEOUT_SECONDS}" "${RUN_CMD[@]}"
else
  # Portable fallback when timeout/gtimeout is unavailable.
  perl -e 'alarm shift @ARGV; exec @ARGV' "$TIMEOUT_SECONDS" "${RUN_CMD[@]}"
fi
