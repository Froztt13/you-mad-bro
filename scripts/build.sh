#!/bin/bash

# Move to the project root directory
cd "$(dirname "$0")/.."

KEYSTORE_NAME="keystore.jks"
STOREPASS="yourpass"
ALIAS="myalias"

set -e

echo "[1/5] Building and patching Game.swf..."
java patcher/Patcher.java

echo "[2/5] Copying patched game into loader..."
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

echo "[3/5] Compiling the loader..."
if [ ! -f "ane/com.aqw.battery.ane" ] || [ ! -f "ane/BatteryOptimizer.swc" ]; then
    bash scripts/build-ane.sh
fi
amxmlc -optimize=true -inline=true -omit-trace-statements=true -library-path+=ane/BatteryOptimizer.swc -output loader/Loader.swf loader/src/Main.as 

echo "[4/5] Checking keystore..."
if [ ! -f "$KEYSTORE_NAME" ]; then 
    echo "Generating new keystore..."
    keytool -genkeypair -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
      -keystore "$KEYSTORE_NAME" -storepass "$STOREPASS" -keypass "$STOREPASS" \
      -dname "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, S=Unknown, C=US"
else
    echo "Keystore already exists, skipping." [cite: 2]
fi

echo "[5/5] Packaging the APK..."
adt -package -target apk-captive-runtime -arch armv8 \
  -storetype JKS -keystore "$KEYSTORE_NAME" -storepass "$STOREPASS" -keypass "$STOREPASS" \
  YouMadBro-armv8.apk loader/app.xml \
  -extdir ane \
  -C loader Loader.swf icons gamefiles 

echo ""
echo "BUILD SUCCESSFUL!" [cite: 3]