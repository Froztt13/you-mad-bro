#!/bin/bash
set -e

cd "$(dirname "$0")/.."

export JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || echo "$JAVA_HOME")
export PATH="$JAVA_HOME/bin:$PATH"

AIR_SDK_PATH="${AIR_SDK_PATH:-$HOME/AIRSDK_51.3.1}"
ANDROID_JAR="${ANDROID_JAR:-/Users/d/Library/Android/sdk/platforms/android-34/android.jar}"
FRE_JAR="$AIR_SDK_PATH/lib/android/FlashRuntimeExtensions.jar"
RUNTIME_JAR="$AIR_SDK_PATH/lib/android/lib/runtimeClasses.jar"

echo "=== Building Battery Optimizer ANE ==="

mkdir -p ane-src/build/classes
javac -source 1.8 -target 1.8 \
    -cp "$ANDROID_JAR:$FRE_JAR:$RUNTIME_JAR" \
    -d ane-src/build/classes \
    ane-src/android/src/com/aqw/battery/*.java

jar cvf ane-src/build/battery-ane.jar -C ane-src/build/classes com

"$AIR_SDK_PATH/bin/compc" \
    -source-path ane-src/as3/src \
    -include-classes com.aqw.battery.BatteryOptimizer \
    -output ane-src/build/BatteryOptimizer.swc

unzip -p ane-src/build/BatteryOptimizer.swc library.swf > ane-src/build/library.swf

mkdir -p ane-src/build/Android-ARM64
cp ane-src/build/library.swf ane-src/build/Android-ARM64/
cp ane-src/build/battery-ane.jar ane-src/build/Android-ARM64/

mkdir -p ane-src/build/Android-ARM
cp ane-src/build/library.swf ane-src/build/Android-ARM/
cp ane-src/build/battery-ane.jar ane-src/build/Android-ARM/

mkdir -p ane-src/build/default
cp ane-src/build/library.swf ane-src/build/default/

mkdir -p ane
cp ane-src/build/BatteryOptimizer.swc ane/BatteryOptimizer.swc

"$AIR_SDK_PATH/bin/adt" -package \
    -target ane ane/com.aqw.battery.ane ane-src/extension.xml \
    -swc ane/BatteryOptimizer.swc \
    -platform Android-ARM64 -C ane-src/build/Android-ARM64 . \
    -platform Android-ARM -C ane-src/build/Android-ARM . \
    -platform default -C ane-src/build/default .

echo "=== ANE Build Success: ane/com.aqw.battery.ane ==="
