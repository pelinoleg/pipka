#!/bin/bash
# Installs (or updates) the latest Pipka into /Applications.
set -euo pipefail

REPO="pelinoleg/pipka"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Ask the API for the newest tag — the /latest/download redirect can lag behind for a few minutes.
TAG=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
echo "↓ Downloading Pipka $TAG…"
curl -fsSL "https://github.com/$REPO/releases/download/$TAG/Pipka.zip" -o "$TMP/Pipka.zip"

pkill -x Pipka 2>/dev/null || true
rm -rf /Applications/Pipka.app
ditto -x -k "$TMP/Pipka.zip" /Applications
xattr -dr com.apple.quarantine /Applications/Pipka.app 2>/dev/null || true

open /Applications/Pipka.app
echo "✓ Pipka $TAG installed — look for the drop in the menu bar."
