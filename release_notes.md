# Release: YouMadBro 1.0.0

### Bot Engine & Automation
- **Visual Bot Script Builder**:
  - Kill Monster (Once, Count, Item Drop)
  - Join Map & Cell/Pad Jump
  - Auto Quest Accept & Complete (reward selector)
  - Delay timer & item transfer (Bank/Inventory)
  - Custom Notification trigger
- **Bot Controls**:
  - Uncapped loop mode dengan runtime stats (timer, counter, step)
  - Safety toggle "Leave Combat" saat Stop/Pause
- **Drops & Storage**:
  - Whitelist item drops (auto-accept & drop alert)
  - Save/Load script via JSON (`.json`) dan SAF file picker

### Background Process & Android Integration
- **Background Execution**:
  - Keep-Alive foreground service (Partial WakeLock & WifiLock)
  - Berjalan tanpa henti saat layar mati, standby, atau aplikasi di-minimize
  - Request bypass optimasi baterai (unrestricted)
- **Display & Alerts**:
  - PiP (Picture-in-Picture) floating window (Auto-Enter di Android 12+)
  - Notifikasi native (bot selesai, drop whitelist, disconnect)
  - Penyesuaian prioritas notifikasi tanpa getar terus-menerus

### Controls & In-Game Utilities
- **Virtual Joystick**: Floating joystick responsif, layout drag-and-drop (bisa disimpan/disembunyikan)
- **Quick Action Menu**: Quest Loader, Cell Jump, Lag Killer, Hide Players, Open Bank, Set Spawnpoint, Packet Logger
- **Combat**: Auto Battle dengan proteksi class safety dan anti counter-attack

### Mobile UX & Chat
- **Floating Chat Preview**: Bar preview di bagian atas agar input tidak tertutup keyboard virtual
- **Text Mirror**: Sinkronisasi ketikan real-time dengan tombol Clear dan Send

### Account Manager
- Penyimpanan multi-akun lokal terenkripsi
- 1-tap quick switch dan auto-login
- Tombol intip sandi & fitur ambil kredensial langsung dari game
- Import/Export akun format JSON (`accounts.json`) via SAF

### Bug Fixes
- Perbaikan asset loading preview item dan reward quest (`qRewardPrev`)
- Perbaikan ReferenceError `#1069` (`showQuestList`) pada preview UI drop
- Kompatibilitas font & lifecycle stage AIR pada Travel Map & Book of Lore
- Perbaikan loading remote interface untuk OutfitSets dan badge