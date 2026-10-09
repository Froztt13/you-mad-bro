#!/bin/bash

# Berpindah ke direktori tempat file .command berada
cd "$(dirname "$0")"

echo "======================================="
echo "     YouMadBro - Android Build & Run   "
echo "======================================="

# 1. Paksa menggunakan Java 17 (Penting untuk Adobe AIR di macOS)
if /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 17)
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "[1/5] Java: $(java -version 2>&1 | head -n 1)"
else
    echo "ERROR: JDK 17 tidak ditemukan. Silakan jalankan 'brew install openjdk@17'"
    read -p "Tekan [Enter] untuk keluar..."
    exit 1
fi

# 2. Cek ADB & Device Terkoneksi
echo "[2/5] Memeriksa koneksi ADB..."
if ! command -v adb >/dev/null 2>&1; then
    # Cek Android SDK platform-tools default jika adb belum di PATH
    if [ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
        export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
    fi
fi

if ! command -v adb >/dev/null 2>&1; then
    echo "ERROR: 'adb' tidak ditemukan di PATH. Pastikan Android SDK platform-tools terinstall."
    read -p "Tekan [Enter] untuk keluar..."
    exit 1
fi

DEVICE_COUNT=$(adb devices | grep -v "List of devices" | grep -v "^$" | grep "device$" | wc -l | tr -d ' ')
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "ERROR: Tidak ada device Android yang terdeteksi via ADB."
    echo "Pastikan:"
    echo " - HP terhubung via kabel USB / WiFi debugging."
    echo " - USB Debugging telah diaktifkan di Opsi Pengembang (Developer Options)."
    echo " - Izin otorisasi debugging telah disetujui di layar HP."
    read -p "Tekan [Enter] untuk keluar..."
    exit 1
fi

DEVICE_MODEL=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')
echo "Device terdeteksi: $DEVICE_MODEL ($DEVICE_COUNT device aktif)"

# 3. Konfigurasi Path & Info
AIR_SDK_PATH="$HOME/AIRSDK_51.3.1"
VERSION_PREFIX="1.0"
RUN_NUMBER="0"
VERSION="v${VERSION_PREFIX}.${RUN_NUMBER}"
ARCH="armv8"
DIST_DIR="dist"
OUTPUT_APK="${DIST_DIR}/YouMadBro_${ARCH}-${VERSION_PREFIX}.${RUN_NUMBER}.apk"
PACKAGE_NAME="air.com.aqw.mobile.mod"
ACTIVITY_NAME="air.com.aqw.mobile.mod.AIRAppEntry"

# Update Versi di Config.as & app.xml
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

# 4. Kompilasi Loader.swf
echo ""
echo "[3/5] Mengompilasi Loader.swf (Optimized)..."
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
    echo "ERROR: Kompilasi Loader.swf gagal!"
    read -p "Tekan [Enter] untuk keluar..."
    exit 1
fi

# 5. Packaging APK
echo ""
echo "[4/5] Packaging APK ke $OUTPUT_APK..."
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
    echo "ERROR: Packaging APK gagal!"
    read -p "Tekan [Enter] untuk keluar..."
    exit 1
fi

# 6. Install & Run ke Device via ADB
echo ""
echo "[5/5] Menginstall & Menjalankan di $DEVICE_MODEL..."
adb install -r "$OUTPUT_APK"
if [ $? -ne 0 ]; then
    echo "ERROR: Gagal menginstall APK ke device!"
    read -p "Tekan [Enter] untuk keluar..."
    exit 1
fi

echo "Menghentikan instance lama..."
adb shell am force-stop "$PACKAGE_NAME"

echo "Menjalankan aplikasi..."
adb shell am start -n "$PACKAGE_NAME/$ACTIVITY_NAME"

echo ""
echo "======================================="
echo "   Aplikasi Berhasil Dijalankan!       "
echo "======================================="
echo "APK Terpasang: $OUTPUT_APK"
echo "Device: $DEVICE_MODEL"
echo ""

read -p "Tekan [Enter] untuk keluar..."
