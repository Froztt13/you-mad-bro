---
name: you-mad-bro
description: >-
  Comprehensive development guide for the you-mad-bro AQW client and bot loader. Use when developing, compiling, debugging, or adding features (bot commands, UI components, update checks, memory management, ANEs, or build workflows) in the you-mad-bro project.
---

# you-mad-bro Developer Guide

Comprehensive guide for developing, building, and extending `you-mad-bro` — a cross-platform (macOS & Android) Adobe AIR client and automation loader for AdventureQuest Worlds (AQW).

---

## 1. Coding & Language Standards

- **Language Requirement**: **ALWAYS use English** for all:
  - UI labels, button texts, notifications, and dialog messages
  - App log messages (`bot.log`, `AppLogUI`, `trace`)
  - Code comments and docstrings
- **Framework & Runtime**: ActionScript 3 (AVM2), targeting Adobe AIR 51+ desktop (macOS) and mobile (Android).
- **Style**:
  - Clean object-oriented architecture in `loader/src/`.
  - Maintain defensive null checks when accessing `game.world`, `game.sfc`, or stage elements since Flash objects load asynchronously.

---

## 2. Directory Architecture

```
you-mad-bro/
├── ane/                 # Native Extensions (BatteryOptimizer.ane, BatteryOptimizer.swc)
├── assets/              # Vanilla & patched game assets / SWFs
├── example_bots/        # Sample bot script files (.json) bundled with releases
├── loader/
│   ├── Loader.swf       # Compiled client SWF
│   ├── app.xml          # Adobe AIR application descriptor
│   └── src/
│       ├── Main.as                  # Application entry point, window & memory management
│       ├── Config.as                # Global configs, versioning, GitHub release endpoints
│       ├── commands/                # Bot engine commands (Hunt, Join, Jump, Quest, etc.)
│       ├── engine/                  # Core systems (BotEngine, AutoBattle, MapCommands, AppUpdater)
│       ├── input/                   # UI panels & controllers (MainMenuUI, BotManagerUI, PacketLoggerUI)
│       └── ui/                      # Custom dark UI toolkit (MyButton, InfoMessage, ConfirmationMessage)
├── patcher/             # Java bytecode patcher leveraging RABCDAsm
└── scripts/             # Build and execution helper scripts
```

---

## 3. Build & Run Workflows

### Compiling `Loader.swf`
The client is compiled with `amxmlc` from Adobe AIR SDK:
```bash
/Users/d/AIRSDK_51.3.1/bin/amxmlc \
  -optimize=true \
  -inline=true \
  -omit-trace-statements=true \
  -library-path+=ane/BatteryOptimizer.swc \
  -output loader/Loader.swf \
  loader/src/Main.as
```

### Running on macOS (ADL)
Run locally using AIR Debug Launcher (`run_mac.command`):
```bash
/Users/d/AIRSDK_51.3.1/bin/adl -extdir ane loader/app.xml loader/
```

### Packaging Builds
- **macOS App Bundle**: `./build_mac.command` (packages `.dmg` or `.app` signed with `mac_cert.p12`).
- **Android APK**: `./build_android.command` (packages `.apk` with captive runtime and `ane/BatteryOptimizer.ane`).

---

## 4. Key Systems & Patterns

### A. Bot Engine & Commands (`loader/src/commands/`)
- Each bot command implements or follows the command pattern with an `execute(bot:BotEngine):void` entry point.
- **Timing & Delays**: Always use `bot.delay(ms)` or `bot.advanceStep(delayMs)` when waiting for server responses or map transitions.
- **Map Traversal & Smart Jump**:
  - Use `MapCommands.smartJump(cell, pad)` to automatically navigate cells and resolve fallback pads if the requested pad is unavailable.

### B. UI Component Architecture (`loader/src/ui/`)
- Always use the sleek dark theme palette:
  - Background panels: Deep charcoal `0x0f172a` with borders `0x334155`.
  - Buttons: `MyButton` with primary blue `0x2563eb` or danger/secondary styles.
  - Dialogs: `ConfirmationMessage` (two options: primary action + cancel) and `InfoMessage` (single OK button).
  - Fonts: Standard `_sans` with crisp text rendering.

### C. Update Checker (`loader/src/engine/AppUpdater.as`)
- **Rate Limit**: Auto-check strictly checks `SharedObject` and runs only if `>= 24 hours` have elapsed since the last check.
- **Manual Check**: Available in `MainMenuUI` gear menu (`AppUpdater.checkUpdate(stage, true)`), which notifies the user immediately if already up to date.
- **GitHub Releases**: Queries `https://api.github.com/repos/Froztt13/you-mad-bro/releases/latest` with a `User-Agent` header.

### D. Memory Management & Isolated Domains (`Main.as`)
- SWF map files contain complex MovieClips and embedded classes. To avoid memory leaks, maps are loaded into an isolated child `ApplicationDomain(ApplicationDomain.currentDomain)`.
- When switching maps, previous map loaders call `unloadAndStop(true)` and trigger GC cycles to reclaim memory.
