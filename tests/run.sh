#!/usr/bin/env sh
# Lance la suite headless. Surcharger le binaire avec GODOT=/chemin/vers/godot
set -e
GODOT="${GODOT:-godot}"
RACINE="$(cd "$(dirname "$0")/.." && pwd)"
exec "$GODOT" --headless --path "$RACINE" --script res://tests/run_tests.gd
