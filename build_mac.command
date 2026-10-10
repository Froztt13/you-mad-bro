#!/bin/bash

# Berpindah ke direktori tempat file .command berada
cd "$(dirname "$0")"

# Pastikan ~/.local/bin masuk ke PATH (untuk abcexport, rabcdasm, rabcasm, abcreplace)
export PATH="$HOME/.local/bin:$PATH"

# Konfigurasi Path & Info
AIR_SDK_PATH="$HOME/AIRSDK_51.3.1"
VERSION_PREFIX="1.1"
RUN_NUMBER="0"
VERSION="v${VERSION_PREFIX}.${RUN_NUMBER}"
CERT_NAME="mac_cert.p12"
CERT_PASS="123456"
DIST_DIR="dist"
APP_NAME="YouMadBro_Mac.app"

# Konfigurasi Resolusi (Original Logic Size, High DPI for FHD Density)
WIDTH=960
HEIGHT=550

# Deteksi Arsitektur Mac
ARCH_TYPE="armv8"
if [[ $(uname -m) == "x86_64" ]]; then
    ARCH_TYPE="x64"
fi

echo "======================================="
echo "     YouMadBro - macOS Build System    "
echo "======================================="

# 1. Build & Patch Game.swf terlebih dahulu
echo ""
echo "[Tahap 1/5] Building & Patching Game.swf..."
if [ -f "scripts/build-game.sh" ]; then
    bash scripts/build-game.sh
    if [ $? -ne 0 ]; then
        echo "ERROR: Gagal mem-build Game.swf!"
        read -p "Tekan Enter untuk keluar..."
        exit 1
    fi
else
    echo "ERROR: scripts/build-game.sh tidak ditemukan!"
    read -p "Tekan Enter untuk keluar..."
    exit 1
fi

# 2. Update Versi di Config.as & app.xml
echo ""
echo "[Tahap 2/5] Updating version & resolution..."
if [ -f "loader/src/Config.as" ]; then
    echo "Updating version to $VERSION..."
    sed -i '' "s/APP_VERSION:String = \".*\"/APP_VERSION:String = \"$VERSION\"/" loader/src/Config.as
fi

# Update Resolusi ke FHD (1920x1080)
if [ -f "loader/app.xml" ]; then
    sed -i '' "s/<versionNumber>.*<\/versionNumber>/<versionNumber>${VERSION_PREFIX}.${RUN_NUMBER}<\/versionNumber>/" loader/app.xml
    sed -i '' "s/<versionLabel>.*<\/versionLabel>/<versionLabel>${VERSION_PREFIX}.${RUN_NUMBER}<\/versionLabel>/" loader/app.xml
    sed -i '' "s/<width>.*<\/width>/<width>$WIDTH<\/width>/" loader/app.xml
    sed -i '' "s/<height>.*<\/height>/<height>$HEIGHT<\/height>/" loader/app.xml
    sed -i '' "s/<fullScreen>.*<\/fullScreen>/<fullScreen>false<\/fullScreen>/" loader/app.xml
    
    # Enable High DPI (Retina) support
    if grep -q "requestedDisplayResolution" loader/app.xml; then
        sed -i '' "s/<requestedDisplayResolution>.*<\/requestedDisplayResolution>/<requestedDisplayResolution>high<\/requestedDisplayResolution>/" loader/app.xml
    else
        sed -i '' "s/<\/initialWindow>/  <requestedDisplayResolution>high<\/requestedDisplayResolution>\\
    <\/initialWindow>/" loader/app.xml
    fi
fi

if [ -f "loader/src/Main.as" ]; then
    sed -i '' "s/width=\"[0-9]*\"/width=\"$WIDTH\"/" loader/src/Main.as
    sed -i '' "s/height=\"[0-9]*\"/height=\"$HEIGHT\"/" loader/src/Main.as
fi

# 3. Compile Loader (ActionScript)
echo ""
echo "[Tahap 3/5] Compiling Loader.swf (Optimized)..."
"$AIR_SDK_PATH/bin/amxmlc" \
    -optimize=true \
    -inline=true \
    -omit-trace-statements=true \
    -library-path+=ane/BatteryOptimizer.swc \
    -output loader/Loader.swf \
    loader/src/Main.as

if [ $? -ne 0 ]; then
    echo "ERROR: Gagal meng-compile Loader.swf"
    read -p "Tekan Enter untuk keluar..."
    exit 1
fi

# 4. Buat Sertifikat Self-Signed jika belum ada
if [ ! -f "$CERT_NAME" ]; then
    echo "Membuat sertifikat self-signed (2048-RSA)..."
    "$AIR_SDK_PATH/bin/adt" -certificate -cn SelfSigned 2048-RSA "$CERT_NAME" "$CERT_PASS"
fi

# 5. Packaging
echo ""
echo "[Tahap 4/5] Packaging file temporary .air..."
# Buat descriptor sementara khusus macOS tanpa tag <extensions>
# (karena target format .air adalah desktop runtime yang tidak mendukung native extensions Android)
APP_XML_MAC="loader/app_mac_temp.xml"
sed '/<extensions>/,/<\/extensions>/d' loader/app.xml > "$APP_XML_MAC"

"$AIR_SDK_PATH/bin/adt" -package \
    -storetype pkcs12 \
    -keystore "$CERT_NAME" \
    -storepass "$CERT_PASS" \
    "temp_package.air" \
    "$APP_XML_MAC" \
    -C loader Loader.swf icons gamefiles

AIR_STATUS=$?
rm -f "$APP_XML_MAC"

if [ $AIR_STATUS -ne 0 ]; then
    echo "ERROR: Gagal membuat file .air"
    read -p "Tekan Enter untuk keluar..."
    exit 1
fi

echo ""
echo "[Tahap 5/5] Mengonversi .air menjadi .app ($ARCH_TYPE) di folder $DIST_DIR..."
mkdir -p "$DIST_DIR"
rm -rf "$DIST_DIR/$APP_NAME"

"$AIR_SDK_PATH/bin/adt" -package \
    -target bundle \
    -arch $ARCH_TYPE \
    "$DIST_DIR/$APP_NAME" \
    "temp_package.air"

if [ $? -eq 0 ]; then
    rm -f "temp_package.air"

    echo "Menambahkan izin folder macOS (Documents, Downloads, Desktop)..."
    PLIST="$DIST_DIR/$APP_NAME/Contents/Info.plist"
    if [ -f "$PLIST" ]; then
        /usr/libexec/PlistBuddy -c "Add :NSDocumentsFolderUsageDescription string 'YouMadBro requires access to your Documents folder to load and save bot scripts and accounts.'" "$PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :NSDocumentsFolderUsageDescription 'YouMadBro requires access to your Documents folder to load and save bot scripts and accounts.'" "$PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :NSDownloadsFolderUsageDescription string 'YouMadBro requires access to your Downloads folder to load bot scripts.'" "$PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :NSDownloadsFolderUsageDescription 'YouMadBro requires access to your Downloads folder to load bot scripts.'" "$PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :NSDesktopFolderUsageDescription string 'YouMadBro requires access to your Desktop folder to load bot scripts.'" "$PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :NSDesktopFolderUsageDescription 'YouMadBro requires access to your Desktop folder to load bot scripts.'" "$PLIST" 2>/dev/null || true
    fi
    
    echo "Menghapus batasan sistem (Fixing Damaged App Error)..."
    xattr -cr "$DIST_DIR/$APP_NAME"
    
    echo "Re-signing .app bundle (Fixing macOS TCC & Designated Requirement)..."
    codesign --force --deep --sign - "$DIST_DIR/$APP_NAME"

    echo ""
    echo "======================================="
    echo "BUILD BERHASIL!"
    echo "Output: $DIST_DIR/$APP_NAME"
    echo "======================================="
else
    echo "BUILD GAGAL saat membuat .app bundle!"
fi

echo ""
read -p "Tekan [Enter] untuk menutup jendela ini..."
