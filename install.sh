#!/bin/bash
# Installs (or updates) the latest Pipka into /Applications.
set -euo pipefail

REPO="pelinoleg/pipka"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "↓ Downloading Pipka…"
curl -fsSL "https://github.com/$REPO/releases/latest/download/Pipka.zip" -o "$TMP/Pipka.zip"

pkill -x Pipka 2>/dev/null || true
rm -rf /Applications/Pipka.app
ditto -x -k "$TMP/Pipka.zip" /Applications
xattr -dr com.apple.quarantine /Applications/Pipka.app 2>/dev/null || true

open /Applications/Pipka.app
echo "✓ Pipka installed — look for the drop in the menu bar."
