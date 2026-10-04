#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
APP="build/Display Sleep.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O Sources/*.swift -o "$APP/Contents/MacOS/DisplaySleep"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built $APP"
