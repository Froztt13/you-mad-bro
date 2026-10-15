#!/bin/bash

# Change directory to script location
cd "$(dirname "$0")"

# 1. Enforce Java 17 (Required for Adobe AIR on macOS)
if /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 17)
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "Using Java: $(java -version 2>&1 | head -n 1)"
else
    echo "Error: JDK 17 not found. Please run 'brew install openjdk@17'"
    read -p "Press [Enter] to exit..."
    exit 1
fi

# 2. Configure Paths & Info
AIR_SDK_PATH="$HOME/AIRSDK_51.3.1"
VERSION_PREFIX="1.1"
RUN_NUMBER="0"
VERSION="v${VERSION_PREFIX}.${RUN_NUMBER}"
ARCH="armv8"
DIST_DIR="dist"
OUTPUT_APK="${DIST_DIR}/YouMadBro_${ARCH}-${VERSION_PREFIX}.${RUN_NUMBER}.apk"

echo "--- Starting YouMadBro Build ($ARCH) ---"

# 3. Update version in Config.as & app.xml
sed -i '' "s/APP_VERSION:String = \".*\"/APP_VERSION:String = \"$VERSION\"/" loader/src/Config.as
sed -i '' "s/<versionNumber>.*<\/versionNumber>/<versionNumber>${VERSION_PREFIX}.${RUN_NUMBER}<\/versionNumber>/" loader/app.xml
sed -i '' "s/<versionLabel>.*<\/versionLabel>/<versionLabel>${VERSION_PREFIX}.${RUN_NUMBER}<\/versionLabel>/" loader/app.xml
sed -i '' "s/<fullScreen>.*<\/fullScreen>/<fullScreen>true<\/fullScreen>/" loader/app.xml
if grep -q "requestedDisplayResolution" loader/app.xml; then
    sed -i '' "s/<requestedDisplayResolution>.*<\/requestedDisplayResolution>/<requestedDisplayResolution>standard<\/requestedDisplayResolution>/" loader/app.xml
else
    sed -i '' "s/<\/initialWindow>/  <requestedDisplayResolution>standard<\/requestedDisplayResolution>\\
  <\/initialWindow>/" loader/app.xml
fi

# 4. Compile Loader (ActionScript)
if [ ! -f "ane/com.aqw.battery.ane" ] || [ ! -f "ane/BatteryOptimizer.swc" ]; then
    echo "Building ANE dependency..."
    bash scripts/build-ane.sh
fi

echo "Compiling Loader.swf (Optimized)..."
$AIR_SDK_PATH/bin/amxmlc \
    -optimize=true \
    -inline=true \
    -omit-trace-statements=true \
    -library-path+=ane/BatteryOptimizer.swc \
    -output loader/Loader.swf \
    loader/src/Main.as

# 5. Package APK
echo "Packaging APK to $OUTPUT_APK..."
mkdir -p "$DIST_DIR"
$AIR_SDK_PATH/bin/adt -package \
    -target apk-captive-runtime \
    -arch $ARCH \
    -storetype JKS \
    -keystore keystore.jks \
    -storepass "123654" \
    -keypass "123654" \
    -alias "123" \
    "$OUTPUT_APK" \
    loader/app.xml \
    -extdir ane \
    -C loader Loader.swf icons gamefiles

if [ $? -eq 0 ]; then
    echo "---------------------------------------"
    echo "Build Success: $OUTPUT_APK"
    echo "---------------------------------------"
else
    echo "---------------------------------------"
    echo "Build Failed!"
    echo "---------------------------------------"
fi

# Keep terminal window open when launched via double-click
read -p "Press [Enter] to exit..."