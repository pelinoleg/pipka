#!/bin/bash
# Builds a universal Pipka.app and dist/Pipka.zip
set -euo pipefail
cd "$(dirname "$0")"

VERSION="${VERSION:-$(git describe --tags --abbrev=0 2>/dev/null || echo v0.0.0)}"
VERSION="${VERSION#v}"

swift build -c release --arch arm64 --arch x86_64

APP=dist/Pipka.app
rm -rf dist
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/apple/Products/Release/Pipka "$APP/Contents/MacOS/Pipka"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
sed "s/__VERSION__/$VERSION/g" Resources/Info.plist > "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"

(cd dist && ditto -c -k --keepParent Pipka.app Pipka.zip)
echo "Built $APP ($VERSION)"
