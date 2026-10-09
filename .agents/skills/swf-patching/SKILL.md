---
name: swf-patching
description: >-
  Comprehensive guide and workflow for reverse engineering, disassembling, patching, and reassembling ActionScript 3 SWF files (Game.swf, charselect.swf, spiderbook3.swf, Map-UI_r38.swf, etc.) in the you-mad-bro AQW wrapper. Use whenever the user asks to patch a SWF, fix ActionScript 3 / Flash / Adobe AIR runtime errors (SecurityError, TypeError, VerifyError), redirect remote SWF assets locally, modify AVM2 bytecode using RABCDAsm, or automate patches in patcher/Patcher.java.
---

# ActionScript 3 & SWF Patching Guide (you-mad-bro)

Standard operational workflow and technical reference for analyzing, disassembling, modifying AVM2 bytecode, resolving Adobe AIR / ADL runtime errors, and automating SWF patches in `patcher/Patcher.java`.

---

## 1. Toolchain & Disassembly Workflow

The primary tools used from RABCDAsm:
- **`abcexport <file.swf>`**: Extracts ActionScript 3 bytecode into ABC blocks (e.g., `file-0.abc`).
- **`rabcdasm <file-0.abc>`**: Disassembles an ABC block into a folder `file-0/` containing `.asasm` files.
- **`rabcasm <file-0/file-0.main.asasm>`**: Reassembles `.asasm` files back into `file-0.main.abc`.
- **`abcreplace <file.swf> <tag_id> <file-0.main.abc>`**: Replaces the target ABC block in the SWF (typically tag_id `0`).

### Quick Manual Inspection (Terminal)
To inspect or test a patch manually before integrating it into `Patcher.java`:
```bash
abcexport assets/target.swf
rabcdasm assets/target-0.abc
# Edit files in assets/target-0/*.asasm
rabcasm assets/target-0/target-0.main.asasm
abcreplace assets/target.swf 0 assets/target-0/target-0.main.abc
```

---

## 2. Common Adobe AIR / ADL Runtime Errors & Fixes

When web Flash SWFs run inside the Adobe AIR application sandbox, the following runtime errors are commonly encountered:

### A. `SecurityError: Error #2193: Security sandbox violation`
- **Symptom**:
  ```
  SecurityError: Error #2193: Security sandbox violation: getChildAt: ... cannot access app:/Loader.swf/...
      at flash.display::DisplayObjectContainer/getChildAt()
      at main/onStage()
  ```
- **Root Cause**: The SWF attempts to access the root container using `stage.getChildAt(0)`. In Adobe AIR, `stage.getChildAt(0)` resolves to the AIR host container (`app:/Loader.swf`), which violates sandbox boundaries.
- **Fix**: Replace `stage.getChildAt(0)` with `this.parent` (`getlocal0; getproperty parent`) or an explicit reference to the parent MovieClip:
  ```asasm
  // Replace:
  getlex              QName(PackageNamespace(""), "stage")
  pushbyte            0
  callproperty        QName(PackageNamespace(""), "getChildAt"), 1

  // With:
  getlocal0
  getproperty         QName(PackageNamespace(""), "parent")
  ```

### B. `SecurityError: Error #2134: Cannot create SharedObject`
- **Symptom**:
  ```
  SecurityError: Error #2134: Cannot create SharedObject
  ```
- **Root Cause**: Calling `SharedObject.getLocal("name", "/", true)` with 3 arguments (using root path `/` and secure flag). In Adobe AIR's application sandbox, passing a root path `/` is disallowed.
- **Fix**: Call `SharedObject.getLocal("name")` using 1 argument:
  ```asasm
  // Replace:
  pushstring          "AQWChars"
  pushstring          "/"
  pushtrue
  callproperty        QName(PackageNamespace(""), "getLocal"), 3

  // With:
  pushstring          "AQWChars"
  callproperty        QName(PackageNamespace(""), "getLocal"), 1
  ```

### C. `TypeError: Error #1010: A term is undefined and has no properties`
- **Symptom**:
  ```
  TypeError: Error #1010: A term is undefined and has no properties.
      at manager()
      at main/onStage()
  ```
- **Root Cause**: Unchecked indexing into an empty array (e.g. `displayAvts[0].loginInfo` when `displayAvts.length == 0`), or accessing nested properties on `SharedObject.data` before initialization.
- **Fix**:
  1. Add a length guard (`length > 0`) before accessing index `0`:
     ```asasm
     getlex              QName(PackageNamespace(""), "displayAvts")
     getproperty         QName(PackageNamespace(""), "length")
     pushbyte            0
     ifngt               L_EMPTY
     getlex              QName(PackageNamespace(""), "displayAvts")
     pushbyte            0
     getproperty         MultinameL(...)
     getproperty         Multiname("loginInfo", ...)
     getproperty         Multiname("bAsk", ...)
     getlex              QName(PackageNamespace(""), "Boolean")
     astypelate
     jump                L_DONE
     L_EMPTY:
     pushfalse
     L_DONE:
     callpropvoid        Multiname("init", ...), 1
     ```
  2. Guard and initialize nested objects if `null`/`undefined`:
     ```asasm
     getlex              QName(..., "characters")
     getproperty         QName(PackageNamespace(""), "data")
     getproperty         Multiname("users", ...)
     pushnull
     ifne                L_HAS_DATA
     getlex              QName(..., "characters")
     getproperty         QName(PackageNamespace(""), "data")
     findpropstrict      QName(PackageNamespace(""), "Object")
     constructprop       QName(PackageNamespace(""), "Object"), 0
     setproperty         Multiname("users", ...)
     L_HAS_DATA:
     ```

### D. `SecurityError: Error #3205` / `SecurityError: Error #3207` / `Security.allowDomain()`
- **Symptom**: AIR throws a SecurityError when `Security.allowDomain()` is invoked inside an application-domain context.
- **Fix**: Use the `sanitizeSecurity(Path dir)` helper in `Patcher.java` to strip all `Security.allowDomain()` instruction sequences.

### E. `VerifyError: Error #1023: Stack overflow occurred`
- **Root Cause**: The method adds more operands to the execution stack than declared in `maxstack` at the method header.
- **Fix**: Increase `maxstack` in the method header (e.g., from `maxstack 3` to `maxstack 10` or `maxstack 12`).

---

## 3. Local Asset Redirection Pattern

When a remote sub-SWF (such as `spiderbook3.swf`, `Map-UI_r38.swf`, `charselect.swf`) fails due to remote sandbox restrictions, protocol issues, or upstream changes:

1. **Bundle as a Local Patched SWF**:
   - Download the remote SWF to `assets/<name>.swf`.
   - Disassemble, sanitize security, apply necessary runtime fixes.
   - Reassemble back into `assets/<name>.swf`.
   - Copy the output to `loader/gamefiles/<name>.swf`.
2. **Redirect the Load Call in `Game.swf`**:
   - Locate the `Loader.load(new URLRequest(...))` call site in `Game.swf`.
   - Redirect the target URL to `app:/gamefiles/<name>.swf`.
   - Load via `queueLoadViaBytes(loader, "app:/gamefiles/<name>.swf", context)` with `LoaderContext(false, ApplicationDomain.currentDomain)` and `allowCodeImport = true`.
   Bytecode example:
   ```asasm
   getlocal0
   getproperty         QName(PackageNamespace(""), "failedServers")
   getproperty         QName(PackageNamespace(""), "mobile")
   getlocal0
   getproperty         Multiname("csLoader", ...)
   pushstring          "app:/gamefiles/charselect.swf"
   findpropstrict      Multiname("LoaderContext", ...)
   pushfalse
   getlex              Multiname("ApplicationDomain", ...)
   getproperty         Multiname("currentDomain", ...)
   constructprop       Multiname("LoaderContext", ...), 2
   dup
   pushtrue
   setproperty         QName(PackageNamespace(""), "allowCodeImport")
   callpropvoid        QName(PackageNamespace(""), "queueLoadViaBytes"), 3
   ```
3. **Update Build Scripts**:
   Ensure the new SWF is copied into `loader/gamefiles/` across all build scripts:
   - `scripts/build.sh` & `scripts/build-game.sh`
   - `scripts/build.bat` & `scripts/build-game.bat`

---

## 4. Automation Best Practices in `patcher/Patcher.java`

1. **Flexible Multinames Regex**:
   Always match multinames with `[^\\]]+\\]` to handle varying namespace arrays:
   ```java
   Pattern p = Pattern.compile("(?s)getlex\\s+QName\\(PackageNamespace\\(\"\"\\),\\s*\"displayAvts\"\\)...");
   ```
2. **Beware of `Matcher.quoteReplacement`**:
   If your replacement contains regex capture groups like `$1`, **DO NOT** leave `$1` inside a string passed to `Matcher.quoteReplacement()` (it will be escaped to a literal `"$1"`). Instead, extract the capture group in Java first:
   ```java
   String matched = matcher.group(1);
   String replacement = matched + "\n" + extraCode;
   content = matcher.replaceFirst(Matcher.quoteReplacement(replacement));
   ```
3. **Unique Labels**:
   Use descriptive, unique label names to prevent collisions with disassembler auto-generated labels (e.g., `L_HAS_USERS`, `L_EMPTY_AVTS`, `L_INIT_AVTS`).
4. **Build & Test Verification**:
   Always verify changes end-to-end:
   ```bash
   bash scripts/build-game.sh
   # Verify ADL runtime logs
   ./run_mac.command
   ```
