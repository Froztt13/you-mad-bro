# YouMadBro — AdventureQuest Worlds (AQW) Mobile & Desktop Client

<p align="center">
  <img src="loader/icons/icon-512x512.png" alt="YouMadBro Logo" width="128" height="128">
</p>

<p align="center">
  <b>Custom client for AdventureQuest Worlds (AQW) targeting Android and macOS.</b><br>
  Equipped with a responsive touch joystick, in-game utility menus, an integrated automation bot engine, and native Android OS integration via an Adobe Native Extension (ANE).
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20macOS%20%7C%20Windows-blue" alt="Platforms">
  <img src="https://img.shields.io/badge/Runtime-Adobe%20AIR%2051.1%2B-red" alt="Adobe AIR">
  <img src="https://img.shields.io/badge/Language-ActionScript%203%20%7C%20Java-orange" alt="Languages">
  <img src="https://img.shields.io/badge/Architecture-ARM64%20(armv8)%20%7C%20ARMv7%20%7C%20Desktop-green" alt="Architectures">
</p>

---

## Key Features

---

### 1. Bot Engine & Visual Script Builder
* **Visual Script Builder**: Construct automated command sequences directly inside the client without manual scripting:
  - **Kill Monster**: Target monsters by name (`*` for any monster), with modes for *Kill Once*, *Kill Count*, or *Kill for Item Drop*.
  - **Join Map**: Automated travel between designated map rooms and instances.
  - **Cell & Pad Jump**: Precise movement across internal cell frames and pads.
  - **Quest Handler**: Automated quest acceptance (*Accept*) and turn-in (*Complete*).
  - **Delay / Wait**: Configurable intervals between actions to prevent server-side rate limits and desyncs.
  - **Bank Transfer**: Automated item movement between Inventory and Bank.
* **Looping & Combat Safety**:
  - Uncapped continuous loop mode (*Bot Repeat*).
  - *Leave Combat on Stop/Pause* safety toggle to automatically disengage targets and drop auto-attacks when stopping.
* **Item Drops Whitelist**: Define whitelisted item drops; the engine automatically claims matching loot while ignoring clutter.
* **Script Import & Export**: Save and load bot routines using standardized `.json` format for backup and sharing.

---

### 2. Background Botting & Keep-Alive Service (Android ANE)
* **Foreground Service**: Runs automated botting uninterrupted in the background, even when the screen is powered off or the application is minimized.
* **Partial WakeLock & WifiLock**: Prevents Android OS Doze mode from killing CPU execution or dropping SmartFoxServer (SFS) socket connections.
* **Battery Optimization Exemption**: In-app shortcut to request unrestricted battery optimization directly via native Android system settings.

---

### 3. Picture-in-Picture (PiP) Mode
* **Floating Game Mini-Window**: Keeps the live AQW game viewport rendering in a movable floating window over other applications (e.g., YouTube, WhatsApp, browser).
* **Auto-Enter PiP (Android 12+)**: Seamlessly transitions into Picture-in-Picture mode when pressing Home or swiping up while a bot script is active.
* **Dedicated In-App Trigger**: Instant access via the `[PiP]` button on the Bot Manager header and the Gear (Settings) menu.

---

### 4. Native Push Notifications
Native system status bar notifications for critical game events:
* **Bot Completed**: Alert dispatched upon finishing all scripted commands.
* **Item Obtained**: Notification sent when a whitelisted rare drop is collected.
* **Disconnect Alert**: Instant warning when the connection to the game server is lost.

---

### 5. Quick Account Manager
* **Multi-Account Storage**: Securely save multiple AQW accounts locally on your device.
* **1-Tap Quick Switch**: Switch characters and auto-login with a single tap without retyping credentials.
* **Password Visibility Toggle**: Option to reveal or mask stored passwords.
* **SAF Account Import**: Import account rosters directly from `accounts.json` via the native document picker.

---

### 6. Touch Joystick & Mobile UX
* **Virtual Touch Joystick**: Smooth 360-degree analog touch stick for responsive character movement on mobile devices, with custom drag-and-drop repositioning (*Edit Layout* mode) and show/hide toggle.
* **Mobile Chat Preview**: Floating top-center text preview bar mirroring typed chat messages so mobile on-screen keyboards never cover the chat box, with real-time text sync and quick Clear / Send buttons.
* **In-Game Quick Utilities**: Floating menu providing instant access to Quest Loader, Cell Jump, Lag Killer, Hide Players, Open Bank, Set Spawnpoint, Packet Logger, and Auto Battle.

---

## Repository Structure

```text
aqw-mobile-dev/
├── ane/                          # Compiled ANE binary assets (com.aqw.battery.ane & .swc)
├── ane-src/                      # Android Native Extension source code (Java + AS3)
│   ├── android/                  # Native Java source (KeepAlive, SAF, PiP, Notifications)
│   └── as3/                      # ActionScript 3 interface (BatteryOptimizer.as)
├── assets/                       # Base Game.swf assets and client dependencies
├── loader/                       # Main client application source (ActionScript 3)
│   ├── app.xml                   # Adobe AIR application descriptor manifest
│   ├── src/
│   │   ├── Main.as               # Client entry point
│   │   ├── engine/               # Bot engine, combat logic, quest handler, socket hooks
│   │   ├── input/                # MainMenuUI, BotManager, AccountManager, UI modals
│   │   └── ui/                   # Layout components, modals, buttons, theme tokens
│   └── gamefiles/                # Patched Game.swf target directory
├── patcher/                      # Automated Game.swf bytecode patcher (Patcher.java & patches)
├── scripts/                      # Build automation and helper scripts
│   ├── build-ane.sh              # Android ANE compilation script
│   ├── build-game.sh             # Game.swf bytecode patcher script
│   ├── patch-air-pip.py          # AIR SDK PiP manifest template injector
│   └── build.bat                 # Automated Windows build script
├── build_mac.command             # macOS application bundle (.app) build script
├── run_mac.command               # Direct execution script via AIR Debug Launcher (ADL)
├── .github/workflows/
│   └── build-apk.yml             # GitHub Actions CI/CD automation pipeline for APK releases
└── README_SETUP.md               # Detailed Windows development environment setup guide
```

---

## Quick Start

### Prerequisites
1. **Java Development Kit (JDK 17+)**
2. **Adobe AIR SDK (Harman version 51.1+)**
3. **DMD (D Compiler) & RABCDAsm** *(Required only if fetching and patching new Game.swf builds from Artix servers)*

---

### A. Running on macOS

1. **Launch in Debug Mode (ADL)**:
   ```bash
   ./run_mac.command
   ```
   *Compiles `Loader.swf` and launches the game directly with live trace log output.*

2. **Package macOS Application (`.app`)**:
   ```bash
   ./build_mac.command
   ```

---

### B. Building on Windows

1. Refer to the complete environment setup instructions in **[README_SETUP.md](README_SETUP.md)** to configure JDK, DMD, RABCDAsm, and AIR SDK.
2. Run the automated build script:
   ```cmd
   scripts\build.bat
   ```
   *The generated `YouMadBro-armv8.apk` will be output to the project root directory.*

---

### C. Automated CI/CD (GitHub Actions)

This repository includes a continuous integration workflow configured in `.github/workflows/build-apk.yml`:
* Pushing commits or publishing tags on `master` automatically:
  - Configures AIR SDK 51.1.
  - Injects Picture-in-Picture template attributes into the SDK.
  - Builds `Game.swf` and compiles `Loader.swf`.
  - Packages signed ARM64 (`armv8`) APKs and macOS (`.app`) bundles, and attaches them to GitHub Releases.

---

## Privacy & Security

* **Local Storage Only**: All credentials stored in the Account Manager are handled locally on device via `SharedObject` or encrypted `accounts.json`. No personal information is ever transmitted to third-party endpoints.
* **Direct Server Communication**: Game traffic connects exclusively to official Artix Entertainment servers (`*.aq.com`).

---

## Disclaimer

* This project is maintained for educational, technical exploration, and community usability purposes.
* **AdventureQuest Worlds (AQW)** is a registered trademark of **Artix Entertainment, LLC**. This project is an independent community development and is not officially affiliated with Artix Entertainment.
