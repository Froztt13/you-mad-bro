#!/bin/bash

# Change directory to script location
cd "$(dirname "$0")"

echo "======================================="
echo "     YouMadBro - Android Build & Run   "
echo "======================================="

# 1. Enforce Java 17 (Required for Adobe AIR on macOS)
if /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 17)
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "[1/5] Java: $(java -version 2>&1 | head -n 1)"
else
    echo "ERROR: JDK 17 not found. Please run 'brew install openjdk@17'"
    read -p "Press [Enter] to exit..."
    exit 1
fi

# 2. Check ADB & Connected Devices
echo "[2/5] Checking ADB connection..."
if ! command -v adb >/dev/null 2>&1; then
    # Check default Android SDK platform-tools if adb is not in PATH
    if [ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
        export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
    fi
fi

if ! command -v adb >/dev/null 2>&1; then
    echo "ERROR: 'adb' not found in PATH. Make sure Android SDK platform-tools is installed."
    read -p "Press [Enter] to exit..."
    exit 1
fi

DEVICE_COUNT=$(adb devices | grep -v "List of devices" | grep -v "^$" | grep "device$" | wc -l | tr -d ' ')
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "ERROR: No Android devices detected via ADB."
    echo "Please ensure:"
    echo " - Device is connected via USB cable or wireless debugging."
    echo " - USB Debugging is enabled in Developer Options."
    echo " - Debugging authorization prompt has been accepted on the device."
    read -p "Press [Enter] to exit..."
    exit 1
fi

DEVICE_MODEL=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')
echo "Device detected: $DEVICE_MODEL ($DEVICE_COUNT active device(s))"

# 3. Configure Paths & Info
AIR_SDK_PATH="$HOME/AIRSDK_51.3.1"
VERSION_PREFIX="1.1"
RUN_NUMBER="0"
VERSION="v${VERSION_PREFIX}.${RUN_NUMBER}"
ARCH="armv8"
DIST_DIR="dist"
OUTPUT_APK="${DIST_DIR}/YouMadBro_${ARCH}-${VERSION_PREFIX}.${RUN_NUMBER}.apk"
PACKAGE_NAME="air.com.aqw.mobile.mod"
ACTIVITY_NAME="air.com.aqw.mobile.mod.AIRAppEntry"

# Update version in Config.as & app.xml
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

# 4. Compile Loader.swf
echo ""
echo "[3/5] Compiling Loader.swf (Optimized)..."
if [ ! -f "ane/com.aqw.battery.ane" ] || [ ! -f "ane/BatteryOptimizer.swc" ]; then
    echo "Building ANE dependency..."
    bash scripts/build-ane.sh
fi

"$AIR_SDK_PATH/bin/amxmlc" \
    -optimize=true \
    -inline=true \
    -omit-trace-statements=true \
    -library-path+=ane/BatteryOptimizer.swc \
    -output loader/Loader.swf \
    loader/src/Main.as

if [ $? -ne 0 ]; then
    echo "ERROR: Loader.swf compilation failed!"
    read -p "Press [Enter] to exit..."
    exit 1
fi

# 5. Package APK
echo ""
echo "[4/5] Packaging APK to $OUTPUT_APK..."
mkdir -p "$DIST_DIR"
"$AIR_SDK_PATH/bin/adt" -package \
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

if [ $? -ne 0 ]; then
    echo "ERROR: Packaging APK failed!"
    read -p "Press [Enter] to exit..."
    exit 1
fi

# 6. Install & Run on Device via ADB
echo ""
echo "[5/5] Installing & Running on $DEVICE_MODEL..."
adb install -r "$OUTPUT_APK"
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install APK on device!"
    read -p "Press [Enter] to exit..."
    exit 1
fi

echo "Stopping existing instance..."
adb shell am force-stop "$PACKAGE_NAME"

echo "Launching application..."
adb shell am start -n "$PACKAGE_NAME/$ACTIVITY_NAME"

echo ""
echo "======================================="
echo "   Application Launched Successfully!  "
echo "======================================="
echo "Installed APK: $OUTPUT_APK"
echo "Device: $DEVICE_MODEL"
echo ""

read -p "Press [Enter] to exit..."
