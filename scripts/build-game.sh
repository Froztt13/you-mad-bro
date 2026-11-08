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
rm -f loader/gamefiles/spiderbook3.swf
for f in assets/Book-*.swf; do
    if [ -f "$f" ]; then
        cp "$f" loader/gamefiles/
    fi
done
if [ -f "assets/charselect.swf" ]; then
    cp assets/charselect.swf loader/gamefiles/charselect.swf
fi

AIR_SDK_PATH="${AIR_SDK_PATH:-$HOME/AIRSDK_51.3.1}"
if [ -f "$AIR_SDK_PATH/bin/amxmlc" ]; then
    echo "[3/3] Compiling Loader.swf..."
    "$AIR_SDK_PATH/bin/amxmlc" \
        -optimize=true \
        -inline=true \
        -omit-trace-statements=true \
        -library-path+=ane/BatteryOptimizer.swc \
        -output loader/Loader.swf \
        loader/src/Main.as
fi

echo ""
echo "========================================================"
echo "GAME.SWF, LOADER.SWF, BOOK OF LORE, MAP-UI_R38.SWF & CHARSELECT.SWF BUILD SUCCESSFUL!"
echo "Output files:"
echo "  - assets/Game.swf"
echo "  - loader/Loader.swf"
echo "  - loader/gamefiles/Game.swf"
echo "  - loader/gamefiles/Map-UI_r38.swf"
echo "  - loader/gamefiles/Book-*.swf"
echo "  - loader/gamefiles/charselect.swf"
echo "========================================================"
