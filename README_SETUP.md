# AQW Mobile Setup and Build Guide (Windows)

This guide provides step-by-step instructions for configuring the development environment and compiling **YouMadBro / AQW Mobile** into an Android APK on Windows.

---

## Prerequisites

Building this project locally requires four core components:

1. **Java Development Kit (JDK 17+)**
2. **D Compiler (DMD)**
3. **RABCDAsm** (ActionScript Bytecode Disassembler and Assembler)
4. **Adobe AIR SDK (Harman, version 51.1+)**

---

## Step 1: Install and Configure Java JDK (17+)

Java is required to run the automated patcher (`patcher/Patcher.java`), the Adobe AIR build tools, and the `keytool` utility for APK signing.

### Installation:
1. Download JDK (version 17 or newer, such as JDK 21) from [Oracle Java](https://www.oracle.com/java/technologies/downloads/) or [Adoptium Temurin](https://adoptium.net/).
2. Run the installer and complete the setup (e.g., installed to `C:\Program Files\Java\jdk-21`).

### Environment Variables:
1. Press **Windows + S**, search for `Environment Variables`, and select **Edit the system environment variables**.
2. Click **Environment Variables...**.
3. Under **System variables**:
   - Click **New...** and enter:
     - Variable name: `JAVA_HOME`
     - Variable value: `C:\Program Files\Java\jdk-21` *(adjust to your actual JDK directory)*
   - Locate the **Path** variable, select it, and click **Edit...**.
   - Click **New** and add the path to the JDK `bin` directory:
     ```text
     C:\Program Files\Java\jdk-21\bin
     ```
   - Click **OK** on all dialog boxes to save changes.

---

## Step 2: Install D Compiler (DMD)

DMD is the compiler for the D programming language, required to run or compile RABCDAsm utilities.

### Installation:
1. Visit the official [Dlang Downloads](https://dlang.org/download.html) page.
2. Download the Windows installer (for example, `dmd-2.xxx.x.exe`).
3. Run the installer and follow the on-screen instructions (default installation directory is usually `C:\D\dmd2`).
4. The installer automatically registers the `bin` / `bin64` directory to the system `Path`.

---

## Step 3: Install RABCDAsm

RABCDAsm is used to disassemble, patch bytecode, and reassemble ActionScript 3 SWF binaries.

The following executables must be accessible from your system `Path`:
- `abcexport.exe`
- `rabcdasm.exe`
- `rabcasm.exe`
- `abcreplace.exe`

### Option A: Pre-built Binaries (Recommended)
1. Download a pre-compiled Windows release of RABCDAsm (e.g., `RABCDAsm_v1.18.7z`).
2. Extract the archive into a dedicated directory, for example:
   ```text
   C:\RABCDAsm
   ```
3. Add that directory to your system **Path**:
   - Go to **Environment Variables** -> **System variables** -> **Path** -> **Edit**.
   - Click **New** and add `C:\RABCDAsm`.
   - Click **OK**.

### Option B: Build from Source
To compile directly from source using DMD:
```bash
git clone --depth 1 https://github.com/CyberShadow/RABCDAsm.git
cd RABCDAsm
dmd -run build_rabcdasm.d
```
Move the compiled `.exe` files to a folder included in your system `Path`.

---

## Step 4: Install Adobe AIR SDK (Harman 51.1+)

The Adobe AIR SDK provides the ActionScript 3 compiler (`amxmlc`) and the application packaging tool (`adt`) needed to package the Android APK.

### Installation:
1. Visit the [Harman AIR SDK Download Portal](https://airsdk.harman.com/download).
2. Download the **AIR SDK for Windows** ZIP package (e.g., `AIRSDK_Windows.zip`, version 51.1 or higher).
3. Extract the ZIP archive into a permanent path without spaces, for example:
   ```text
   C:\AIRSDK
   ```
4. Add the `bin` directory to your system **Path**:
   - Open **Environment Variables** -> **System variables** -> **Path** -> **Edit**.
   - Click **New** and add:
     ```text
     C:\AIRSDK\bin
     ```
   - Click **OK**.

---

## Step 5: Verify Environment in Terminal

Close any existing command prompt windows, open a new **Command Prompt** (`cmd.exe`), and run the verification commands below:

```cmd
:: 1. Verify Java and Keystore Tool
java -version
keytool

:: 2. Verify D Compiler
dmd --version

:: 3. Verify RABCDAsm Utilities
rabcdasm
abcexport
rabcasm
abcreplace

:: 4. Verify Adobe AIR SDK Utilities
adt -version
amxmlc -version
```

Ensure none of these commands return `'command' is not recognized as an internal or external command`.

---

## Step 6: Building the APK

Once all dependencies are installed and verified, build the Android APK.

### Method 1: Using the Automated Build Script (Recommended)

Run the automated batch script provided in the repository:

```cmd
cd C:\path\to\aqw-mobile-dev
scripts\build.bat
```

The script executes five stages automatically:
1. **[1/5] Building and Patching Game.swf**: Downloads the latest `Game.swf` from Artix servers, disassembles bytecode, applies patches from `patcher/`, and reassembles the binary.
2. **[2/5] Copying Files**: Copies patched assets (`Game.swf`, map interfaces) into `loader\gamefiles\`.
3. **[3/5] Compiling Loader**: Compiles `loader\src\Main.as` into `loader\Loader.swf` using `amxmlc` with native extension bindings (`ane/BatteryOptimizer.swc`).
4. **[4/5] Checking Keystore**: Automatically generates `keystore.jks` for APK signing if not already present.
5. **[5/5] Packaging APK**: Packages all assets and native extensions into **`YouMadBro-armv8.apk`** using `adt`.

---

### Method 2: Manual Step-by-Step Build

To execute the build process manually from the terminal:

```cmd
:: 1. Patch Game.swf
java patcher/Patcher.java

:: 2. Copy patched Game.swf to the loader directory
copy /y assets\Game.swf loader\gamefiles\Game.swf

:: 3. Compile the loader with ANE library path
amxmlc -optimize=true -inline=true -omit-trace-statements=true -library-path+=ane/BatteryOptimizer.swc -output loader/Loader.swf loader/src/Main.as

:: 4. Generate signing keystore (first-time only)
keytool -genkeypair -alias 123 -keyalg RSA -keysize 2048 -validity 10000 -keystore keystore.jks -storepass 123654 -keypass 123654 -dname "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, S=Unknown, C=US"

:: 5. Package ARMv8 (64-bit) APK with ANE extension directory
adt -package -target apk-captive-runtime -arch armv8 -storetype JKS -keystore keystore.jks -storepass 123654 -keypass 123654 YouMadBro-armv8.apk loader/app.xml -extdir ane -C loader Loader.swf icons gamefiles
```

### Target Architecture Options:
- **`armv8`**: Standard for modern 64-bit Android smartphones.
- **`armv7`**: For legacy 32-bit Android devices, replace `-arch armv8` with `-arch armv7` and name the output file accordingly.

---

## Troubleshooting

1. **`java patcher/Patcher.java` Download Failure:**
   - Ensure your device has an active internet connection. The patcher fetches the official `Game.swf` directly from Artix Entertainment CDN servers.
2. **`amxmlc` or `adt` Not Recognized:**
   - Verify that `C:\AIRSDK\bin` is listed in your system `Path`. Restart Command Prompt after updating environment variables.
3. **`keytool` Command Fails:**
   - `keytool` is packaged with the Java Development Kit (JDK), not the standalone JRE. Ensure your `JAVA_HOME` and `Path` point to the JDK `bin` directory.
4. **Locating the Built APK:**
   - The compiled package is placed in the project root directory as **`YouMadBro-armv8.apk`**, ready to be sideloaded onto an Android device.
