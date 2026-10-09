#!/bin/bash

# Berpindah ke direktori tempat file .command berada
cd "$(dirname "$0")"

# 1. Pastikan Java 17 digunakan jika ada
if /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 17)
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# 2. Konfigurasi Adobe AIR SDK
AIR_SDK_PATH="${AIR_SDK_PATH:-$HOME/AIRSDK_51.3.1}"
if [ ! -d "$AIR_SDK_PATH" ]; then
    echo "ERROR: Adobe AIR SDK tidak ditemukan di $AIR_SDK_PATH"
    read -p "Tekan [Enter] untuk keluar..."
    exit 1
fi
export PATH="$AIR_SDK_PATH/bin:$PATH"

echo "======================================="
echo "   YouMadBro - Run ADL & Logs   "
echo "======================================="

# 3. Kompilasi Loader.swf jika belum ada
if [ ! -f "loader/Loader.swf" ]; then
    echo "Loader.swf belum ditemukan, mengompilasi..."
    "$AIR_SDK_PATH/bin/amxmlc" \
        -optimize=true \
        -inline=true \
        -omit-trace-statements=true \
        -library-path+=ane/BatteryOptimizer.swc \
        -output loader/Loader.swf \
        loader/src/Main.as
    if [ $? -ne 0 ]; then
        echo "ERROR: Gagal mengompilasi Loader.swf!"
        read -p "Tekan [Enter] untuk keluar..."
        exit 1
    fi
fi

# 4. Siapkan deskriptor sementara khusus ADL di macOS
# (Hilangkan <extensions> Android agar ADL tidak error 'Not supported native extensions profile')
APP_XML_TMP="loader/app_adl_temp.xml"
sed '/<extensions>/,/<\/extensions>/d' loader/app.xml > "$APP_XML_TMP"
sed -i '' "s/<fullScreen>.*<\/fullScreen>/<fullScreen>false<\/fullScreen>/" "$APP_XML_TMP"
sed -i '' "s/<requestedDisplayResolution>.*<\/requestedDisplayResolution>/<requestedDisplayResolution>high<\/requestedDisplayResolution>/" "$APP_XML_TMP"

# Pastikan file temporary dibersihkan saat script keluar atau di-Ctrl+C
trap "rm -f '$APP_XML_TMP'" EXIT INT TERM

echo "Menjalankan aplikasi melalui ADL..."
echo "Semua log game, error, dan network trace akan muncul di bawah ini secara live."
echo "Tekan Ctrl+C di terminal ini untuk menghentikan aplikasi."
echo "---------------------------------------"
echo ""

"$AIR_SDK_PATH/bin/adl" "$APP_XML_TMP" loader 2>&1 | tee adl_output.log
EXIT_CODE=${PIPESTATUS[0]}

rm -f "$APP_XML_TMP"

echo ""
echo "---------------------------------------"
echo "Aplikasi telah ditutup (Exit Code: $EXIT_CODE)."
echo "Log sesi ini juga tersimpan di: adl_output.log"
read -p "Tekan [Enter] untuk menutup jendela ini..."
