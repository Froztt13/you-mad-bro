---
name: aqw-bot-script
description: >-
  Comprehensive guide and workflow for creating, modifying, and structuring AQW bot and farming scripts (.json) in the you-mad-bro client. Use whenever the user asks to create bot scripts, farm quests, hunt monsters, configure AutoQuest, setup item whitelists, or build JSON scripts for the Bot Manager.
---

# AQW Bot Script Development Guide (you-mad-bro)

This skill provides the standard specification, schema definitions, command structures, and best practices for creating JSON bot scripts for the **you-mad-bro** AQW client.

---

## 1. Directory & File Organization

Bot scripts are stored under `example_bots/`:
- Group related scripts into thematic subfolders when appropriate (e.g. `example_bots/Forge quests/`, `example_bots/Kathool items/`).
- Standard file naming format:
  - Complex / Item Farm: `<item_or_quest_slug>.json` (e.g. `example_bots/Forge quests/thaumaturgy.json`)
  - Map-specific Farm: `<map>_<quest_slug>.json` (e.g. `example_bots/Kathool items/midnightzone_sparagmos_andromeda.json`)

---

## 2. Bot Script Architecture Patterns

Depending on the complexity of the farming objective, use one of two core architectural patterns:

### Pattern A: Multi-Item Farm with Labels & `CHECK_REQUIREMENTS` Loop (Recommended for Complex & Multi-Map Farms)
Used for Forge enhancements, multi-reagent craftings, and quests requiring items from multiple maps or shops (e.g. [thaumaturgy.json](file:///Users/d/Documents/you-mad-bro/example_bots/thaumaturgy.json)).

**Architecture Flow**:
```text
[Start Bot]
    │
    ▼
[quest_accept (Main Quest)]
    │
    ▼
┌──► [label: CHECK_REQUIREMENTS]
│       │
│       ├─► Is Item A Not In Inventory? ──(True)──► [goto_label: FARM_ITEM_A] ──┐
│       │                                                                       │
│       ├─► Is Item B Not In Inventory? ──(True)──► [goto_label: FARM_ITEM_B] ──┤
│       │                                                                       │
│       ├─► Is Item C Not In Inventory? ──(True)──► [goto_label: BUY_ITEM_C] ───┤
│       │                                                                       │
│       ▼ (All items present in inventory)                                      │
│   [quest_complete (Main Quest)]                                               │
│   [notif / stop_bot]                                                          │
│                                                                               │
│   [Branch Sections]                                                           │
│   • FARM_ITEM_A: join ─► hunt ────────────────────────────────────────────────┤
│   • FARM_ITEM_B: join ─► hunt ────────────────────────────────────────────────┤
│   • BUY_ITEM_C:  join ─► buy_item ────────────────────────────────────────────┘
│                                                                      │
└─────────────────────── goto_label: CHECK_REQUIREMENTS ───────────────┘
```

**Key Advantages**:
1. **Idempotent**: Re-checks entire inventory before deciding what to farm next.
2. **Resilient**: If a connection drops, map changes, or partial items already exist in inventory/bank, it skips completed steps automatically.
3. **Modular**: Each item has its own isolated label section separated by `blank` spacer commands.

---

### Pattern B: Simple Single-Map AutoQuest Loop
Used for single-room / single-map repetitive quest turn-ins (e.g. daily farming, zone rep).
- Relies on `quests: ["QUEST_ID"]` and `"loop": true`.
- Concurrently runs the client's `AutoQuest` engine to accept/turn-in every 1000ms.

---

## 3. Bot Script JSON Schema

A complete bot configuration has the following root structure:

```json
{
  "name": "Script Display Title",
  "loop": false,
  "leaveCombatOnStop": true,
  "notifyItemDrops": true,
  "quests": [],
  "whitelist": [
    "Final Reward Item",
    "Prerequisite Item 1",
    "Prerequisite Item 2"
  ],
  "commands": [
    ...
  ]
}
```

### Root Fields Specification:
| Field | Type | Description |
|---|---|---|
| `name` | `string` | Human-readable title displayed in the Bot Manager UI. |
| `loop` | `boolean` | `false` for multi-item label checklists that terminate with `stop_bot`; `true` for continuous looping. |
| `leaveCombatOnStop` | `boolean` | `true` so the character immediately disengages combat when stopping. |
| `notifyItemDrops` | `boolean` | `true` to show drop notifications in-game. |
| `quests` | `string[]` | Array of Quest ID strings for the built-in `AutoQuest` engine. Keep `[]` empty when managing quests explicitly with `quest_accept` / `quest_complete`. |
| `whitelist` | `string[]` | Array of item names to automatically pick up. Must include all drops and quest rewards. |
| `commands` | `object[]` | Sequential list of bot commands to execute. |

---

## 4. Command Reference

### A. Flow Control & Labels
- **`label`**: Defines a jump target. Names are automatically converted to uppercase.
  ```json
  { "type": "label", "labelName": "CHECK_REQUIREMENTS" }
  ```
- **`goto_label`**: Unconditionally jumps to a target label.
  ```json
  { "type": "goto_label", "labelName": "CHECK_REQUIREMENTS" }
  ```
- **`blank`**: Visual spacer / section header in the Bot Manager command list.
  ```json
  { "type": "blank", "description": "=== MYSTIC SCRIBING KIT ===" }
  ```
- **`restart_bot`**: Restarts the script execution from command index 0.
  ```json
  { "type": "restart_bot" }
  ```
- **`stop_bot`**: Terminates the bot execution cleanly.
  ```json
  { "type": "stop_bot" }
  ```
- **`delay`**: Pauses bot execution for specified duration.
  ```json
  { "type": "delay", "delaySeconds": 1.0 }
  ```
- **`notif`**: Triggers in-game popup alert.
  ```json
  { "type": "notif", "title": "Farm Finished", "message": "All items acquired!" }
  ```

### B. Conditionals
> [!IMPORTANT]
> In `you-mad-bro`, conditional commands evaluate their statement:
> - If **true (condition MET)**: Executes the **immediate next command** (e.g. `goto_label`).
> - If **false (condition NOT met)**: **Skips** the immediate next command.

- **`is_item_not_in_inventory`**: Checks if item quantity in inventory is strictly less than target.
  ```json
  {
    "type": "is_item_not_in_inventory",
    "var1": "Mystic Scribing Kit",
    "var2": "1"
  },
  {
    "type": "goto_label",
    "labelName": "MYSTIC_SCRIBING"
  }
  ```
- **`is_item_in_inventory`**: Checks if item quantity in inventory is greater than or equal to target.
  ```json
  {
    "type": "is_item_in_inventory",
    "var1": "Dragon Runestone",
    "var2": "30"
  }
  ```
- **`is_quest_available`**: Checks if quest can currently be accepted.
  ```json
  {
    "type": "is_quest_available",
    "var1": "8912",
    "var2": ""
  }
  ```

### C. Combat & Movement
- **`join`**: Moves to target map, cell, and pad.
  ```json
  {
    "type": "join",
    "map": "alchemyacademy",
    "cell": "Enter",
    "pad": "Spawn"
  }
  ```
- **`hunt`**: Auto-searches all cells across the map for the specified monster.
  ```json
  {
    "type": "hunt",
    "monster": "Plague Spreader",
    "killMode": "item",
    "killCount": 1,
    "itemName": "Slimed Sigil",
    "itemQty": 50
  }
  ```
- **`kill`**: Fights monster strictly in the current cell.
  ```json
  {
    "type": "kill",
    "monster": "Staff of Inversion",
    "killMode": "count",
    "killCount": 1
  }
  ```
- **`jump`**: Changes cell in current map.
  ```json
  { "type": "jump", "cell": "r5", "pad": "Left" }
  ```

### D. Quests & Shops
- **`quest_accept`**:
  ```json
  { "type": "quest_accept", "questId": 8912 }
  ```
- **`quest_complete`**:
  ```json
  { "type": "quest_complete", "questId": 8912, "itemId": -1 }
  ```
- **`buy_item`**:
  ```json
  {
    "type": "buy_item",
    "shopId": 395,
    "itemName": "Dragon Runestone",
    "qty": 10
  }
  ```

---

## 5. Master Blueprint: Multi-Item Farm with `CHECK_REQUIREMENTS`

Use this blueprint when generating complex farming scripts (e.g. Thaumaturgy, Avarice, Forge quests):

```json
{
  "name": "Forge Weapon - Acolyte's Lament (Thaumaturgy)",
  "loop": false,
  "leaveCombatOnStop": true,
  "notifyItemDrops": true,
  "quests": [],
  "whitelist": [
    "Final Item",
    "Reagent Alpha",
    "Reagent Beta",
    "Shop Token"
  ],
  "commands": [
    {
      "type": "quest_accept",
      "questId": 8912
    },
    {
      "type": "label",
      "labelName": "CHECK_REQUIREMENTS"
    },
    {
      "type": "is_item_not_in_inventory",
      "var1": "Reagent Alpha",
      "var2": "1"
    },
    {
      "type": "goto_label",
      "labelName": "FARM_ALPHA"
    },
    {
      "type": "is_item_not_in_inventory",
      "var1": "Reagent Beta",
      "var2": "10"
    },
    {
      "type": "goto_label",
      "labelName": "FARM_BETA"
    },
    {
      "type": "is_item_not_in_inventory",
      "var1": "Shop Token",
      "var2": "30"
    },
    {
      "type": "goto_label",
      "labelName": "BUY_TOKEN"
    },
    {
      "type": "quest_complete",
      "questId": 8912,
      "itemId": -1
    },
    {
      "type": "notif",
      "title": "Quest Complete",
      "message": "All requirements gathered and quest turned in!"
    },
    {
      "type": "stop_bot"
    },
    {
      "type": "blank",
      "description": "=== REAGENT ALPHA ==="
    },
    {
      "type": "label",
      "labelName": "FARM_ALPHA"
    },
    {
      "type": "join",
      "map": "alphamap",
      "cell": "Enter",
      "pad": "Spawn"
    },
    {
      "type": "hunt",
      "monster": "Alpha Beast",
      "killMode": "item",
      "killCount": 1,
      "itemName": "Reagent Alpha",
      "itemQty": 1
    },
    {
      "type": "goto_label",
      "labelName": "CHECK_REQUIREMENTS"
    },
    {
      "type": "blank",
      "description": "=== REAGENT BETA ==="
    },
    {
      "type": "label",
      "labelName": "FARM_BETA"
    },
    {
      "type": "join",
      "map": "betamap",
      "cell": "r5",
      "pad": "Left"
    },
    {
      "type": "hunt",
      "monster": "*",
      "killMode": "item",
      "killCount": 1,
      "itemName": "Reagent Beta",
      "itemQty": 10
    },
    {
      "type": "goto_label",
      "labelName": "CHECK_REQUIREMENTS"
    },
    {
      "type": "blank",
      "description": "=== SHOP TOKEN ==="
    },
    {
      "type": "label",
      "labelName": "BUY_TOKEN"
    },
    {
      "type": "join",
      "map": "shopmap",
      "cell": "Enter",
      "pad": "Spawn"
    },
    {
      "type": "buy_item",
      "shopId": 395,
      "itemName": "Shop Token",
      "qty": 10
    },
    {
      "type": "is_item_not_in_inventory",
      "var1": "Shop Token",
      "var2": "30"
    },
    {
      "type": "goto_label",
      "labelName": "BUY_TOKEN"
    },
    {
      "type": "goto_label",
      "labelName": "CHECK_REQUIREMENTS"
    }
  ]
}
```

---

## 6. Checklist When Generating Bot Scripts

1. **Identify Pattern**:
   - Multi-item / Multi-map / Crafting quest $\rightarrow$ **Pattern A (`CHECK_REQUIREMENTS` Loop)**.
   - Single-map repeatable drop farm $\rightarrow$ **Pattern B (AutoQuest Loop)**.
2. **Main Hub Checks**:
   - Every requirement must have an `is_item_not_in_inventory` followed immediately by a `goto_label`.
3. **Loop Back**:
   - At the end of every branch section, jump back to `CHECK_REQUIREMENTS` via `goto_label`.
4. **Visual Readability**:
   - Precede each label block with a descriptive `blank` command (e.g. `{"type": "blank", "description": "=== SECTION NAME ==="}`).
5. **Whitelist Completeness**:
   - Ensure all intermediate drop items, sub-quest prerequisites, shop buy tokens, and final quest rewards are listed in `whitelist`.
