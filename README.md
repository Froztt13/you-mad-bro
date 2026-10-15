# YouMadBro — AdventureQuest Worlds (AQW) Mobile & Desktop Client

<p align="center">
  <img src="loader/icons/icon-512x512.png" alt="YouMadBro Logo" width="120" height="120">
</p>

<p align="center">
  <b>Advanced open-source wrapper and autonomous bot loader for AdventureQuest Worlds (AQW) targeting Android and macOS.</b><br>
  Featuring persistent background execution, dedicated class rotation engines, smart hunting, and nested folder script management.
</p>

<p align="center">
  <a href="https://froztt13.github.io/you-mad-bro/"><img src="https://img.shields.io/badge/Documentation-GitHub%20Pages-0284c7?style=flat&logo=github" alt="Documentation"></a>
  <a href="https://github.com/Froztt13/you-mad-bro/releases"><img src="https://img.shields.io/badge/Release-v1.1.0-emerald?style=flat" alt="Latest Release"></a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20macOS-blue" alt="Platforms">
  <img src="https://img.shields.io/badge/Runtime-Adobe%20AIR%2051.1%2B-red" alt="Adobe AIR">
  <img src="https://img.shields.io/badge/Language-ActionScript%203%20%7C%20Java-orange" alt="Languages">
</p>

---

## Documentation

Full user guides, tab-by-tab Bot Manager references, class combat rotations, and troubleshooting guides are hosted on our interactive documentation portal:

👉 **[Read the Full Documentation on GitHub Pages](https://froztt13.github.io/you-mad-bro/)**

| Documentation Section | Description |
| :--- | :--- |
| **[Bot Manager UI Guide](https://froztt13.github.io/you-mad-bro/#bot-manager-overview)** | In-depth breakdown of all 6 tabs (Combat, Quest, Map, Item, Misc, Settings) and modals. |
| **[14 Conditional Logics](https://froztt13.github.io/you-mad-bro/#conditionals)** | Flow control guards (Inventory, Equipment, Quests, Gold, Map, Cell, Membership). |
| **[Subfolder Script Explorer](https://froztt13.github.io/you-mad-bro/#file-explorer)** | Nested directory browser, breadcrumb navigation, and 1-click overwrite detection. |
| **[Dedicated Class Combos](https://froztt13.github.io/you-mad-bro/#class-combos)** | Optimized combat rotations for CSH, Arcana Invoker, Master Ranger, VHL, DoT, and more. |
| **[Background Service (ANE)](https://froztt13.github.io/you-mad-bro/#background-botting)** | Partial WakeLock, WifiLock, and Picture-in-Picture (PiP) multitasking setup. |

---

## Core Highlights

* **24/7 Background Farming**: Native Java Android ANE (`BatteryOptimizer`) maintains CPU WakeLock, WifiLock, and Foreground Service to prevent OS suspension when the screen turns off.
* **Picture-in-Picture (PiP)**: Keep a live floating game viewport over other applications while multitasking (Auto-enters PiP on Android 12+).
* **Exact-Match Smart Hunt**: Intelligent cross-cell jumping that verifies exact monster names, preventing unintended target lock-on (e.g. distinguishing *"Luxuria"* from *"Luxuria Guard"*).
* **Mobile Touch Ergonomics**: Responsive 360-degree virtual analog joystick with custom drag-and-drop repositioning (*Edit Layout* mode) and a floating non-obstructive chat preview bar.
* **Account Vault**: Secure on-device credential storage for multiple characters with 1-tap quick switching and password auto-fill.
* **Aggressive Memory Reclamation**: Independent map `ApplicationDomain` sandboxing and stage cleanup routines to eliminate memory bloat during multi-hour farming runs.

---

## Repository Structure

```text
you-mad-bro/
├── ane/                          # Compiled ANE binary assets (com.aqw.battery.ane & .swc)
├── ane-src/                      # Android Native Extension source code (Java + AS3)
│   ├── android/                  # Native Java source (WakeLock, SAF, PiP, Notifications)
│   └── as3/                      # ActionScript 3 interface (BatteryOptimizer.as)
├── assets/                       # Base Game.swf assets and client dependencies
├── docs/                         # GitHub Pages documentation portal (HTML, CSS, JS)
├── example_bots/                 # Pre-built farming routines (Forge, Enhancements, Dailies)
├── loader/                       # Main client application source (ActionScript 3)
│   ├── app.xml                   # Adobe AIR application descriptor manifest
│   ├── src/
│   │   ├── Main.as               # Client bootstrap entry point
│   │   ├── engine/               # Bot engine, combat logic, quest handlers, socket hooks
│   │   ├── input/                # BotManager, AccountManager, MainMenu, Modals
│   │   └── ui/                   # Reusable UI controls, dropdowns, buttons, themes
│   └── gamefiles/                # Patched Game.swf target directory
├── patcher/                      # Automated Game.swf bytecode patcher (Patcher.java & patches)
├── scripts/                      # Build automation and helper scripts
├── build_mac.command             # macOS application bundle (.app) build script
├── run_mac.command               # Launch game directly via AIR Debug Launcher (ADL)
└── .github/workflows/
    ├── build-apk.yml             # CI/CD pipeline building Android APK & macOS releases
    └── deploy-pages.yml          # Automated deployment for GitHub Pages documentation
```

---

## Developer Quick Start

### Prerequisites
1. **Java Development Kit (JDK 17+)**
2. **Adobe AIR SDK (Harman version 51.1+)**
3. **DMD (D Compiler) & RABCDAsm** *(Required only if fetching and patching new Game.swf builds from Artix servers)*

### Running on macOS

1. **Launch in Debug Mode (ADL)**:
   ```bash
   ./run_mac.command
   ```
   *Compiles `Loader.swf` and launches the game directly with live trace log output.*

2. **Package Standalone macOS Application (`.app`)**:
   ```bash
   ./build_mac.command
   ```

### Building for Android (Windows / Linux)

1. Set up your AIR SDK and JDK environment variables (see **[README_SETUP.md](README_SETUP.md)** for step-by-step Windows setup).
2. Run the automated build script:
   ```cmd
   scripts\build.bat
   ```
   *The packaged `YouMadBro-armv8.apk` will be output to the project root directory.*

### Automated CI/CD

Commits and tags pushed to `main` trigger GitHub Actions:
* **[Build & Package](.github/workflows/build-apk.yml)**: Injects PiP templates, compiles SWF assets, packages signed ARM64 APKs, and publishes GitHub Releases.
* **[Deploy Pages](.github/workflows/deploy-pages.yml)**: Builds and updates the live documentation portal on GitHub Pages.

---

## Security & Privacy

* **Local Storage Only**: All account credentials stored in the Account Vault are preserved locally on-device. No personal data or credentials are ever sent to external third-party servers.
* **Direct Game Traffic**: Client networking connects exclusively to official Artix Entertainment servers (`*.aq.com`).

---

## Disclaimer

* This project is maintained strictly for educational, technical exploration, and community usability purposes.
* **AdventureQuest Worlds (AQW)** is a registered trademark of **Artix Entertainment, LLC**. This project is an independent community development and is not officially affiliated with Artix Entertainment.
