#!/bin/bash

# Change directory to script location
cd "$(dirname "$0")"

# 1. Ensure Java 17 is used if available
if /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 17)
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# 2. Configure Adobe AIR SDK
AIR_SDK_PATH="${AIR_SDK_PATH:-$HOME/AIRSDK_51.3.1}"
if [ ! -d "$AIR_SDK_PATH" ]; then
    echo "ERROR: Adobe AIR SDK not found at $AIR_SDK_PATH"
    read -p "Press [Enter] to exit..."
    exit 1
fi
export PATH="$AIR_SDK_PATH/bin:$PATH"

echo "======================================="
echo "      YouMadBro - Run ADL & Logs       "
echo "======================================="

# 3. Compile Loader.swf
echo "Compiling Loader.swf..."
"$AIR_SDK_PATH/bin/amxmlc" \
    -optimize=true \
    -inline=true \
    -omit-trace-statements=true \
    -library-path+=ane/BatteryOptimizer.swc \
    -output loader/Loader.swf \
    loader/src/Main.as
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to compile Loader.swf!"
    read -p "Press [Enter] to exit..."
    exit 1
fi

# 4. Prepare temporary descriptor for ADL on macOS
# (Strip Android <extensions> to avoid ADL 'Not supported native extensions profile' error)
APP_XML_TMP="loader/app_adl_temp.xml"
sed '/<extensions>/,/<\/extensions>/d' loader/app.xml > "$APP_XML_TMP"
sed -i '' "s/<fullScreen>.*<\/fullScreen>/<fullScreen>false<\/fullScreen>/" "$APP_XML_TMP"
sed -i '' "s/<requestedDisplayResolution>.*<\/requestedDisplayResolution>/<requestedDisplayResolution>high<\/requestedDisplayResolution>/" "$APP_XML_TMP"

# Ensure temporary file is cleaned up on script exit or interrupt
trap "rm -f '$APP_XML_TMP'" EXIT INT TERM

echo "Running application via ADL..."
echo "---------------------------------------"
echo ""

"$AIR_SDK_PATH/bin/adl" "$APP_XML_TMP" loader 2>&1 | tee adl_output.log
EXIT_CODE=${PIPESTATUS[0]}

rm -f "$APP_XML_TMP"

echo ""
echo "---------------------------------------"
echo "Application closed (Exit Code: $EXIT_CODE)."
echo "Session log also saved to: adl_output.log"
read -p "Press [Enter] to close this window..."
