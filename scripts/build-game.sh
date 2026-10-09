#!/bin/bash

# Move to the project root directory
cd "$(dirname "$0")/.."

set -e

echo "[1/2] Building and patching Game.swf..."
java patcher/Patcher.java

echo "[2/2] Copying patched game into loader..."
mkdir -p loader/gamefiles
cp assets/Game.swf loader/gamefiles/Game.swf
if [ -f "assets/Map-UI_r38.swf" ]; then
    cp assets/Map-UI_r38.swf loader/gamefiles/Map-UI_r38.swf
fi
rm -f loader/gamefiles/world-map.swf
if [ -f "assets/spiderbook3.swf" ]; then
    cp assets/spiderbook3.swf loader/gamefiles/spiderbook3.swf
fi
if [ -f "assets/charselect.swf" ]; then
    cp assets/charselect.swf loader/gamefiles/charselect.swf
fi

echo ""
echo "========================================================"
echo "GAME.SWF, SPIDERBOOK3.SWF, MAP-UI_R38.SWF & CHARSELECT.SWF BUILD SUCCESSFUL!"
echo "Output files:"
echo "  - assets/Game.swf"
echo "  - loader/gamefiles/Game.swf"
echo "  - loader/gamefiles/Map-UI_r38.swf"
echo "  - loader/gamefiles/spiderbook3.swf"
echo "  - loader/gamefiles/charselect.swf"
echo "========================================================"
