# Release: YouMadBro 1.1.0

### Bot Engine & Automation
- **Visual Bot Script Builder**:
  - **Hunt Command**:
    - Multi-mode hunting (Kill Count, Item Drop, Once).
    - **Smart Jump**: Real-time cross-cell auto-jumping to locate and engage alive monsters.
    - **Most-Monsters-Only**: Option to stay exclusively in the single cell with the highest monster density, eliminating unnecessary cell-hopping between kills.
    - **Exact Monster Name Matching**: Case-insensitive exact name matching to avoid accidental targeting of monsters with similar names (e.g. "Luxuria" vs "Luxuria Guard").
    - Active target validation with automatic target cancellation when locked onto an incorrect monster.
  - **New Commands**:
    - `Buy Item`: Automatically purchase items from shops using Shop ID & Item ID.
    - `Get Map Item`: Pick up temporary quest items and map drops (`getMapItem`).
    - `Equip Item`: Equip gear and weapons directly from inventory or bank.
    - `Kill Monster`: Single kill, kill count, and item drop modes.
    - `Join Map & Cell/Pad Jump`: Safe map transitions and cell/pad jumping.
    - `Auto Quest`: Automatically accept & complete quests with custom reward selectors.
    - `Delay & Bank Transfer`: Configurable wait timers and inventory/bank item transfers.
    - `Custom Notification`: Trigger native OS notifications when custom milestones are reached.
  - **Control Flow & Branching (Conditionals)**:
    - Condition checks: Item in Inventory/Bank/Temp, Quest Available/Completed, Player Membership status, Gold amount, Current Map, and Current Cell.
    - `Label` and `Goto Label`: Non-linear execution and label jumping.
    - `Restart Script` and `Stop Script`: Flexible bot loop lifecycle control.
  - **Command Management**:
    - **Insert Below**: Add new commands directly below the currently selected item without having to append to the bottom.

### Bot File Explorer & Folder Navigation
- **Full Subfolder Support**:
  - Both Load and Save dialogs now support browsing nested subdirectories in `Documents/YouMadBro/Bots/` and Android public storage.
  - Real-time breadcrumb path display showing the current folder hierarchy.
  - Instant folder navigation (`📁 Open`, `⬆ .. Back/Up`) with directory boundary enforcement to prevent navigating above root bot folders.
- **Select to Replace (Overwrite)**:
  - Clicking an existing file in `BotSaveModal` automatically fills the filename input and highlights the selected file.
  - Automatic overwrite detection with a warning indicator (`⚠️ File exists. Will replace on save.`) and dynamic button label change to **Replace**.

### Combat & Auto Battle
- **Dedicated Class Combos & Logic**:
  - **Chrono ShadowHunter / Chrono ShadowSlayer (CSH)**:
    - Dedicated combo routine tracking Temporal Rift aura stacks.
    - Automatically executes Skill 4 nuke upon reaching 4+ stacks.
    - Automates reloading via Skill 1 when "Rounds Empty" aura is detected.
    - Applies Skill 2 buff when Temporal Rift is down and builds stacks with Skill 3.
  - **Arcana Invoker**:
    - Intelligent tarot cycle management: draws "0 - The Fool" (Skill 1) and advances through "XX - Judgement" (Skill 1) into "XXI - The World".
    - Prioritizes core damage and sustain rotation (Skill 2 and Skill 4).
    - Conservative mana management for Skill 3 (casts only when Judgement is active or MP > 50).
    - Executes high-damage nuke with Skill 1 when "End of The World" exceeds 10 stacks.
  - **Master Ranger & Ranger**:
    - Tracks "Marks" aura stacks across player and target; immediately fires Skill 3 upon reaching 6 Marks.
    - Prevents casting Skill 3 when Marks < 6, and avoids clipping Skill 4 when "Vampiric Shot" aura is already active.
  - **King's Echo**:
    - Dedicated rotation skipping Skill 3 whenever "Waiting For Corvak" aura is active to prevent wasted cooldowns.
  - **Hollowborn Vindicator**:
    - Full aura-state conditional rotation based on "Safeguard" and "Decay" auras:
    - Casts Skill 1 & Skill 3 only when "Safeguard" is active.
    - Casts Skill 2 only when "Decay" is active without Safeguard.
    - Casts Skill 4 only when neither Safeguard nor Decay is active.
  - **Void Highlord (VHL)**:
    - HP-preservation safety check: Blocks self-damage skills (Skill 1 & Skill 3) when HP drops below 60% to avoid accidental suicide.
  - **Scarlet Sorceress**:
    - Blood sacrifice protection: Prevents casting Skill 1 & Skill 4 when HP drops below 50%.
  - **Dragon of Time (DoT)**:
    - Self-damage safety protection: Blocks Skill 1 & Skill 3 when HP drops below 50%.
  - **Lich**:
    - Dual-resource safety management: Blocks Skill 4 when HP < 70%, and prevents casting Skill 3 when MP > 40.
  - **ArchPaladin**:
    - Heal conservation logic: Prevents casting Skill 2 heal when HP > 60% to save mana and keep cooldown ready for emergencies.
- **Universal Smart Rotation (All Other Classes)**:
  - Adaptive cyclic rotation across all available skills for any unlisted or custom class.
  - **Dynamic Mana Verification**: Real-time calculation of required MP against character's Class Mana Cost multiplier (`$cmc`) to prevent rotation stalls.
  - **Anti-Counterattack Protection**: Detects monster counterattack auras and halts attacks to avoid self-death.
  - **Infinite Range Extension**: Automatically extends skill cast range (`20000`) to eliminate range-based miss issues.

### Performance & Memory Optimization
- **Map Transition Memory Cleanup**:
  - Aggressive memory deallocation (`cleanupMap`) and isolated child `ApplicationDomain` usage on map transitions.
  - Thoroughly cleans residual monsters, player avatars, and audio assets from previous maps to eliminate memory leaks, lag spikes, and FPS drops on mobile devices.

### In-Game Utilities & QoL
- **Quest Tree & Shop Loader**: Integrated quest grabber with hierarchical tree navigation and instant shop loading.
- **In-App GitHub Update Checker**: Automated in-game notifications when a new release is available on GitHub.
- **Dedicated AppLog UI**: Separated bot and game logs from Packet Logger into a dedicated AppLog panel with live scrolling and filtering.
- **Clean UI**: Removed legacy virtual joystick overlay to free up screen real estate and reduce rendering overhead.

### Background Process & Android Integration
- **Background Execution**:
  - Persistent Keep-Alive foreground service (Partial WakeLock & WifiLock) ensures uninterrupted execution with screen off, standby, or minimized.
  - Battery optimization bypass requests (unrestricted background execution).
- **Display & Alerts**:
  - Picture-in-Picture (PiP) floating window support.
  - Native push notifications for bot completion, whitelist drops, and disconnect events.

### Account Manager
- Local encrypted multi-account storage.
- 1-tap quick switch and auto-login.
- Password reveal toggle & direct credential grab from active game session.
- JSON account import/export (`accounts.json`) via Android Storage Access Framework (SAF).

### Build System & Multiplatform
- Standardized all automation scripts (`build_android.command`, `build_mac.command`, `run_android.command`, `run_mac.command`) to English.
- Full HD (FHD) & High-DPI Retina resolution support on macOS.
- Optimized Android ARMv8 captive runtime APK packaging with integrated BatteryOptimizer ANE.