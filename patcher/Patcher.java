import java.io.*;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;
import java.util.stream.Collectors;

public class Patcher {
    private static final String VERSION_API = "https://game.aq.com/game/api/data/gameversion";
    private static final String GAME_FILES_URL = "https://game.aq.com/game/gamefiles/";
    private static final String SPIDERBOOK_URL = "https://game.aq.com/game/gamefiles/news/spiderbook3.swf";
    private static final String MAP_URL = "https://game.aq.com/game/gamefiles/news/Map-UI_r38.swf";
    private static final String CHARSELECT_URL = "https://game.aq.com/game/gamefiles/interface/CharSelect/charselect.swf";

    public static void main(String[] args) throws Exception {
        clearAssetDir();
        downloadAsset();
        exportBytecode();

        Path targetDir = Paths.get("assets/Game-0");
        sanitizeSecurity(targetDir);
        patchServerPaths(targetDir);
        patchAssetLoaders(targetDir);

        build();

        patchSpiderbook();
        patchWorldMap();
        patchCharSelect();
    }

    private static void clearAssetDir() throws IOException {
        Path assetPath = Paths.get("assets");
        if (Files.exists(assetPath)) {
            try (var stream = Files.walk(assetPath)) {
                stream.sorted(Comparator.reverseOrder())
                      .filter(p -> !p.equals(assetPath))
                      .filter(p -> {
                          Path rel = assetPath.relativize(p);
                          String first = rel.getName(0).toString();
                          // Preserve local SWF asset dependencies like Map-UI_r38.swf
                          return first.startsWith("Game-") || first.equals("Game.swf") || first.endsWith(".tmp")
                              || first.startsWith("spiderbook3-") || first.equals("spiderbook3.swf") || first.equals("book-of-lore.swf")
                              || first.startsWith("Map-UI_r38-") || first.equals("Map-UI_r38.swf") || first.equals("world-map.swf")
                              || first.startsWith("charselect-") || first.equals("charselect.swf");
                      })
                      .map(Path::toFile)
                      .forEach(File::delete);
            }
        } else {
            Files.createDirectories(assetPath);
        }
    }

    private static void downloadAsset() throws Exception {
        System.out.println("Fetching game version...");
        HttpURLConnection conn = (HttpURLConnection) URI.create(VERSION_API).toURL().openConnection();
        conn.setRequestProperty("User-Agent", "Mozilla/5.0");
        conn.setRequestProperty("Accept", "application/json");

        String json = new BufferedReader(new InputStreamReader(conn.getInputStream())).lines().collect(Collectors.joining());
        String fileName = json.split("\"sFile\":\"")[1].split("\"")[0];

        System.out.println("Downloading: " + fileName);
        try (InputStream in = URI.create(GAME_FILES_URL + fileName).toURL().openStream()) {
            Files.copy(in, Paths.get("assets/Game.swf"), StandardCopyOption.REPLACE_EXISTING);
        }
    }

    private static void exportBytecode() throws Exception {
        runCommand("abcexport", "assets/Game.swf");
        runCommand("rabcdasm", "assets/Game-0.abc");
    }

    /**
     * In Adobe AIR application sandbox, calling Security.allowDomain() or
     * Security.allowInsecureDomain() throws Error #3207.
     * We strip these calls across all disassembled .asasm files.
     */
    private static void sanitizeSecurity(Path targetDir) throws IOException {
        System.out.println("Sanitizing Security.allowDomain() calls for Adobe AIR compatibility...");
        try (var stream = Files.walk(targetDir)) {
            List<Path> asasmFiles = stream.filter(p -> p.toString().endsWith(".asasm")).collect(Collectors.toList());

            int totalStripped = 0;
            for (Path file : asasmFiles) {
                List<String> lines = Files.readAllLines(file);
                List<String> newLines = new ArrayList<>();
                int skip = 0;
                boolean modified = false;

                for (int i = 0; i < lines.size(); i++) {
                    if (skip > 0) {
                        skip--;
                        continue;
                    }

                    String line = lines.get(i);
                    if (line.contains("getlex") && line.contains("\"Security\"")) {
                        if (i + 2 < lines.size() 
                                && lines.get(i + 1).contains("pushstring") 
                                && lines.get(i + 2).contains("\"allowDomain\"")) {
                            System.out.println("  -> Removed Security.allowDomain from " + file.getFileName() + " (line " + (i + 1) + ")");
                            skip = 2;
                            modified = true;
                            totalStripped++;
                            continue;
                        }
                    }
                    newLines.add(line);
                }

                if (modified) {
                    Files.write(file, newLines);
                }
            }
            System.out.println("Security sanitization complete: " + totalStripped + " call sites removed.");
        }
    }

    /**
     * In AQW Mobile, Game.swf runs locally inside app:/gamefiles/Game.swf.
     * The original code extracts serverFilePath from loaderInfo.url, which ends up as "app:/gamefiles/".
     * We hardcode serverFilePath and serverGamePath to the official AQW endpoints.
     */
    private static void patchServerPaths(Path targetDir) throws IOException {
        Path gameAsasm = targetDir.resolve("Game.class.asasm");
        if (!Files.exists(gameAsasm)) return;

        System.out.println("Patching serverFilePath and serverGamePath in Game.class.asasm...");
        String content = Files.readString(gameAsasm).replace("\r\n", "\n");
        boolean modified = false;

        // Patch serverFilePath
        String startMarker = "findproperty        Multiname(\"serverFilePath\"";
        String endMarker = "setproperty         Multiname(\"serverFilePath\"";
        int idx1 = content.indexOf(startMarker);
        if (idx1 != -1) {
            int idx2 = content.indexOf(endMarker, idx1);
            if (idx2 != -1) {
                int lineStart = content.lastIndexOf('\n', idx1) + 1;
                int lineEnd = content.indexOf('\n', idx2) + 1;
                String fpLine = content.substring(lineStart, content.indexOf('\n', lineStart) + 1);
                String spLine = content.substring(content.lastIndexOf('\n', idx2 - 1) + 1, lineEnd);

                String newBlock = fpLine + "      pushstring          \"https://game.aq.com/game/gamefiles/\"\n" + spLine;
                content = content.substring(0, lineStart) + newBlock + content.substring(lineEnd);
                System.out.println("  -> serverFilePath patched to https://game.aq.com/game/gamefiles/");
                modified = true;
            }
        }

        // Patch serverGamePath
        String startMarkerG = "findproperty        Multiname(\"serverGamePath\"";
        String endMarkerG = "setproperty         Multiname(\"serverGamePath\"";
        int idx1G = content.indexOf(startMarkerG);
        if (idx1G != -1) {
            int idx2G = content.indexOf(endMarkerG, idx1G);
            if (idx2G != -1) {
                int lineStart = content.lastIndexOf('\n', idx1G) + 1;
                int lineEnd = content.indexOf('\n', idx2G) + 1;
                String fpLine = content.substring(lineStart, content.indexOf('\n', lineStart) + 1);
                String spLine = content.substring(content.lastIndexOf('\n', idx2G - 1) + 1, lineEnd);

                String newBlock = fpLine + "      pushstring          \"https://game.aq.com/game/\"\n" + spLine;
                content = content.substring(0, lineStart) + newBlock + content.substring(lineEnd);
                System.out.println("  -> serverGamePath patched to https://game.aq.com/game/");
                modified = true;
            }
        }

        if (modified) {
            Files.writeString(gameAsasm, content);
        }
    }

    /**
     * In Adobe AIR, remote SWFs loaded via Loader.load() cannot import bytecode/definitions
     * unless loaded via Loader.loadBytes() with LoaderContext.allowCodeImport = true.
     * We patch:
     * 1. World.loadNextWith() to call rootClass.failedServers.mobile.queueLoadViaBytes(ldr, url, context)
     * 2. World.loadMap() to call rootClass.failedServers.mobile.loadMapViaBytes(url, ldrC_map, onComplete, onProgress, onError)
     * 3. LoaderContext instances in PlayerDomainCache and World to have allowCodeImport = true
     */
    private static void patchAssetLoaders(Path targetDir) throws IOException {
        Path worldAsasm = targetDir.resolve("World.class.asasm");
        if (Files.exists(worldAsasm)) {
            System.out.println("Patching asset loading in World.class.asasm...");
            String content = Files.readString(worldAsasm).replace("\r\n", "\n");
            boolean modified = false;

            // 1. Patch World.loadNextWith: redirect ldr.load(urlReq, ctx) to queueLoadViaBytes
            if (!content.contains("queueLoadViaBytes")) {
                String targetLdrCall = 
                      "      getscopeobject      1\n"
                    + "      getslot             1\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"ldr\")\n"
                    + "      getscopeobject      1\n"
                    + "      getslot             3\n"
                    + "      getscopeobject      1\n"
                    + "      getslot             4\n"
                    + "      callpropvoid        QName(PackageNamespace(\"\"), \"load\"), 2";

                String replacementLdrCall =
                      "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"failedServers\")\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"mobile\")\n"
                    + "      getscopeobject      1\n"
                    + "      getslot             1\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"ldr\")\n"
                    + "      getscopeobject      1\n"
                    + "      getslot             3\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"url\")\n"
                    + "      getscopeobject      1\n"
                    + "      getslot             4\n"
                    + "      callpropvoid        QName(PackageNamespace(\"\"), \"queueLoadViaBytes\"), 3";

                if (content.contains(targetLdrCall)) {
                    content = content.replace(targetLdrCall, replacementLdrCall);
                    System.out.println("  -> World.loadNextWith patched to queueLoadViaBytes");
                    modified = true;
                } else {
                    System.err.println("  -> WARNING: target pattern for World.loadNextWith not found!");
                }
            }

            // Naikkan maxstack di World.loadNextWith
            Pattern pStack = Pattern.compile("(?s)(refid \"World/instance/World/loadNextWith\".*?body\\s+maxstack )\\d+");
            Matcher mStack = pStack.matcher(content);
            if (mStack.find()) {
                content = mStack.replaceFirst("$110");
                System.out.println("  -> World.loadNextWith maxstack patched to 10");
                modified = true;
            }

            // 2. Patch World.loadMap: redirect ldr_map.load to queueLoadViaBytes
            Pattern pMap = Pattern.compile("(?s)      getlocal0\\n      getproperty         QName\\(PackageNamespace\\(\"\"\\), \"ldr_map\"\\)\\n      findpropstrict      QName\\(PackageNamespace\\(\"flash\\.net\"\\), \"URLRequest\"\\).*?      callpropvoid        QName\\(PackageNamespace\\(\"\"\\), \"load\"\\), 2");
            Matcher mMap = pMap.matcher(content);
            if (mMap.find()) {
                String replMapCall =
                      "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"failedServers\")\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"mobile\")\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"ldr_map\")\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      getlocal1\n"
                    + "      callproperty        Multiname(\"vswf\", [PrivateNamespace(null, \"World\"), PackageNamespace(\"\"), PrivateNamespace(null, \"World/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.utils\"), PackageNamespace(\"flash.external\"), ProtectedNamespace(\"World\"), StaticProtectedNs(\"World\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")]), 1\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"ldrC_map\")\n"
                    + "      callpropvoid        QName(PackageNamespace(\"\"), \"queueLoadViaBytes\"), 3";
                content = mMap.replaceFirst(replMapCall);
                System.out.println("  -> World.loadMap patched to queueLoadViaBytes");
                modified = true;
            } else {
                System.err.println("  -> WARNING: loadMap pattern not found in World.class.asasm!");
            }

            // Naikkan maxstack di World.loadMap ke 12 (mencegah VerifyError #1023)
            Pattern pMapStack = Pattern.compile("(?s)(refid \"World/instance/loadMap\".*?body\\s+maxstack )\\d+");
            Matcher mMapStack = pMapStack.matcher(content);
            if (mMapStack.find()) {
                content = mMapStack.replaceFirst("$112");
                System.out.println("  -> World.loadMap maxstack patched to 12");
                modified = true;
            }

            // 2b. Patch World.loadHouseItem queue check (only trigger load when length == 1)
            Pattern pHouseQueue = Pattern.compile("(?s)(refid \"World/instance/loadHouseItem\".*?getproperty\\s+QName\\(PackageNamespace\\(\"\"\\), \"arrHouseItemQueue\"\\)\\s+getproperty\\s+Multiname\\(\"length\", [^\\]]+\\]\\)\\s+)pushbyte\\s+0\\s+ifngt\\s+(\\w+)");
            Matcher mHouseQueue = pHouseQueue.matcher(content);
            if (mHouseQueue.find()) {
                content = mHouseQueue.replaceFirst("$1pushbyte            1\n      ifne                $2");
                System.out.println("  -> World.loadHouseItem queue check patched to length == 1");
                modified = true;
            } else {
                System.err.println("  -> WARNING: loadHouseItem queue pattern not found in World.class.asasm!");
            }

            Pattern pHouseCatchA = Pattern.compile("(?s)(refid \"World/instance/loadHouseItem\".*?getlex\\s+QName\\(PackageNamespace\\(\"\"\\), \"arrHouseItemQueue\"\\)\\s+getproperty\\s+Multiname\\(\"length\", [^\\]]+\\]\\)\\s+)pushbyte\\s+0\\s+ifngt\\s+(\\w+)");
            Matcher mHouseCatchA = pHouseCatchA.matcher(content);
            if (mHouseCatchA.find()) {
                content = mHouseCatchA.replaceFirst("$1pushbyte            1\n      ifne                $2");
                System.out.println("  -> World.loadHouseItem catch queue check patched to length == 1");
                modified = true;
            }

            // 2c. Patch World.loadNextHouseItem: redirect ldr_House.load to queueLoadViaBytes
            Pattern pHouseA = Pattern.compile("(?s)(refid \"World/instance/loadNextHouseItem\".*?)getlocal0\\n      getproperty         QName\\(PackageNamespace\\(\"\"\\), \"ldr_House\"\\)\\n      findpropstrict      QName\\(PackageNamespace\\(\"flash\\.net\"\\), \"URLRequest\"\\).*?constructprop       QName\\(PackageNamespace\\(\"flash\\.net\"\\), \"URLRequest\"\\), 1\\n      getlocal0\\n      getproperty         QName\\(PackageNamespace\\(\"\"\\), \"loaderC\"\\)\\n      callpropvoid        QName\\(PackageNamespace\\(\"\"\\), \"load\"\\), 2");
            Matcher mHouseA = pHouseA.matcher(content);
            if (mHouseA.find()) {
                String replHouseCall =
                      "getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"failedServers\")\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"mobile\")\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"ldr_House\")\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      callproperty        Multiname(\"getFilePath\", [PrivateNamespace(null, \"World\"), PackageNamespace(\"\"), PrivateNamespace(null, \"World/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.utils\"), PackageNamespace(\"flash.external\"), ProtectedNamespace(\"World\"), StaticProtectedNs(\"World\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")]), 0\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"arrHouseItemQueue\")\n"
                    + "      pushbyte            0\n"
                    + "      getproperty         MultinameL([PrivateNamespace(null, \"World\"), PackageNamespace(\"\"), PrivateNamespace(null, \"World/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.utils\"), PackageNamespace(\"flash.external\"), ProtectedNamespace(\"World\"), StaticProtectedNs(\"World\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                    + "      getproperty         Multiname(\"item\", [PrivateNamespace(null, \"World\"), PackageNamespace(\"\"), PrivateNamespace(null, \"World/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.utils\"), PackageNamespace(\"flash.external\"), ProtectedNamespace(\"World\"), StaticProtectedNs(\"World\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                    + "      getproperty         Multiname(\"sFile\", [PrivateNamespace(null, \"World\"), PackageNamespace(\"\"), PrivateNamespace(null, \"World/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.utils\"), PackageNamespace(\"flash.external\"), ProtectedNamespace(\"World\"), StaticProtectedNs(\"World\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                    + "      add\n"
                    + "      callproperty        Multiname(\"vswf\", [PrivateNamespace(null, \"World\"), PackageNamespace(\"\"), PrivateNamespace(null, \"World/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.utils\"), PackageNamespace(\"flash.external\"), ProtectedNamespace(\"World\"), StaticProtectedNs(\"World\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")]), 1\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"loaderC\")\n"
                    + "      callpropvoid        QName(PackageNamespace(\"\"), \"queueLoadViaBytes\"), 3";
                content = mHouseA.replaceFirst(Matcher.quoteReplacement(mHouseA.group(1) + replHouseCall));
                System.out.println("  -> World.loadNextHouseItem patched to queueLoadViaBytes");
                modified = true;
            } else {
                System.err.println("  -> WARNING: loadNextHouseItem pattern not found in World.class.asasm!");
            }

            // Naikkan maxstack di World.loadNextHouseItem
            Pattern pHouseAStack = Pattern.compile("(?s)(refid \"World/instance/loadNextHouseItem\".*?body\\s+maxstack )\\d+");
            Matcher mHouseAStack = pHouseAStack.matcher(content);
            if (mHouseAStack.find()) {
                content = mHouseAStack.replaceFirst("$112");
                System.out.println("  -> World.loadNextHouseItem maxstack patched to 12");
                modified = true;
            }

            // 2d. Patch World.loadHouseItemB queue check (only trigger load when length == 1)
            Pattern pHouseBQueue = Pattern.compile("(?s)(refid \"World/instance/loadHouseItemB\".*?getproperty\\s+QName\\(PackageNamespace\\(\"\"\\), \"arrHouseItemQueue\"\\)\\s+getproperty\\s+Multiname\\(\"length\", [^\\]]+\\]\\)\\s+)pushbyte\\s+0\\s+ifngt\\s+(\\w+)");
            Matcher mHouseBQueue = pHouseBQueue.matcher(content);
            if (mHouseBQueue.find()) {
                content = mHouseBQueue.replaceFirst("$1pushbyte            1\n      ifne                $2");
                System.out.println("  -> World.loadHouseItemB queue check patched to length == 1");
                modified = true;
            } else {
                System.err.println("  -> WARNING: loadHouseItemB queue pattern not found in World.class.asasm!");
            }

            Pattern pHouseCatchB = Pattern.compile("(?s)(refid \"World/instance/loadHouseItemB\".*?getlex\\s+QName\\(PackageNamespace\\(\"\"\\), \"arrHouseItemQueue\"\\)\\s+getproperty\\s+Multiname\\(\"length\", [^\\]]+\\]\\)\\s+)pushbyte\\s+0\\s+ifngt\\s+(\\w+)");
            Matcher mHouseCatchB = pHouseCatchB.matcher(content);
            if (mHouseCatchB.find()) {
                content = mHouseCatchB.replaceFirst("$1pushbyte            1\n      ifne                $2");
                System.out.println("  -> World.loadHouseItemB catch queue check patched to length == 1");
                modified = true;
            }

            // 2e. Patch World.loadNextHouseItemB: redirect ldr_House.load to queueLoadViaBytes
            Pattern pHouseB = Pattern.compile("(?s)(refid \"World/instance/loadNextHouseItemB\".*?)getlocal0\\n      getproperty         QName\\(PackageNamespace\\(\"\"\\), \"ldr_House\"\\)\\n      findpropstrict      QName\\(PackageNamespace\\(\"flash\\.net\"\\), \"URLRequest\"\\).*?constructprop       QName\\(PackageNamespace\\(\"flash\\.net\"\\), \"URLRequest\"\\), 1\\n      getlocal0\\n      getproperty         QName\\(PackageNamespace\\(\"\"\\), \"loaderC\"\\)\\n      callpropvoid        QName\\(PackageNamespace\\(\"\"\\), \"load\"\\), 2");
            Matcher mHouseB = pHouseB.matcher(content);
            if (mHouseB.find()) {
                String replHouseBCall =
                      "getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"failedServers\")\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"mobile\")\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"ldr_House\")\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      callproperty        Multiname(\"getFilePath\", [PrivateNamespace(null, \"World\"), PackageNamespace(\"\"), PrivateNamespace(null, \"World/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.utils\"), PackageNamespace(\"flash.external\"), ProtectedNamespace(\"World\"), StaticProtectedNs(\"World\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")]), 0\n"
                    + "      getlocal2\n"
                    + "      add\n"
                    + "      callproperty        Multiname(\"vswf\", [PrivateNamespace(null, \"World\"), PackageNamespace(\"\"), PrivateNamespace(null, \"World/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.utils\"), PackageNamespace(\"flash.external\"), ProtectedNamespace(\"World\"), StaticProtectedNs(\"World\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")]), 1\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"loaderC\")\n"
                    + "      callpropvoid        QName(PackageNamespace(\"\"), \"queueLoadViaBytes\"), 3";
                content = mHouseB.replaceFirst(Matcher.quoteReplacement(mHouseB.group(1) + replHouseBCall));
                System.out.println("  -> World.loadNextHouseItemB patched to queueLoadViaBytes");
                modified = true;
            } else {
                System.err.println("  -> WARNING: loadNextHouseItemB pattern not found in World.class.asasm!");
            }

            // Naikkan maxstack di World.loadNextHouseItemB
            Pattern pHouseBStack = Pattern.compile("(?s)(refid \"World/instance/loadNextHouseItemB\".*?body\\s+maxstack )\\d+");
            Matcher mHouseBStack = pHouseBStack.matcher(content);
            if (mHouseBStack.find()) {
                content = mHouseBStack.replaceFirst("$112");
                System.out.println("  -> World.loadNextHouseItemB maxstack patched to 12");
                modified = true;
            }

            // 3. World constructor loaderC allowCodeImport
            String ctorLoaderC = "initproperty        QName(PackageNamespace(\"\"), \"loaderC\")";
            if (content.contains(ctorLoaderC) && !content.contains("loaderC\")\n      getlocal0\n      getproperty         QName(PackageNamespace(\"\"), \"loaderC\")\n      pushtrue\n      setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")")) {
                content = content.replace(ctorLoaderC, ctorLoaderC + "\n      getlocal0\n      getproperty         QName(PackageNamespace(\"\"), \"loaderC\")\n      pushtrue\n      setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")");
                System.out.println("  -> World loaderC allowCodeImport patched");
                modified = true;
            }

            // 4. World loadMap ldrC_map allowCodeImport
            String ldrCMap = "initproperty        QName(PackageNamespace(\"\"), \"ldrC_map\")";
            if (content.contains(ldrCMap) && !content.contains("ldrC_map\")\n      getlocal0\n      getproperty         QName(PackageNamespace(\"\"), \"ldrC_map\")\n      pushtrue\n      setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")")) {
                content = content.replace(ldrCMap, ldrCMap + "\n      getlocal0\n      getproperty         QName(PackageNamespace(\"\"), \"ldrC_map\")\n      pushtrue\n      setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")");
                System.out.println("  -> World ldrC_map allowCodeImport patched");
                modified = true;
            }

            if (modified) {
                Files.writeString(worldAsasm, content);
            }
        }

        // 5. PlayerDomainCache allowCodeImport
        Path pdcAsasm = targetDir.resolve("types/PlayerDomainCache.class.asasm");
        if (Files.exists(pdcAsasm)) {
            System.out.println("Patching allowCodeImport in PlayerDomainCache.class.asasm...");
            String pdcContent = Files.readString(pdcAsasm).replace("\r\n", "\n");
            String pdcTarget = "coerce              QName(PackageNamespace(\"flash.system\"), \"LoaderContext\")\n      setlocal3";
            String pdcReplacement = pdcTarget + "\n      getlocal3\n      pushtrue\n      setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")";
            if (pdcContent.contains(pdcTarget) && !pdcContent.contains("setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")")) {
                pdcContent = pdcContent.replace(pdcTarget, pdcReplacement);
                Files.writeString(pdcAsasm, pdcContent);
                System.out.println("  -> PlayerDomainCache allowCodeImport patched");
            }
        }

        // 6. Fix Avatar pet loading
        Path avatarAsasm = targetDir.resolve("Avatar.class.asasm");
        if (Files.exists(avatarAsasm)) {
            System.out.println("Patching pet loading in Avatar.class.asasm...");
            String avContent = Files.readString(avatarAsasm).replace("\r\n", "\n");
            boolean avModified = false;

            Pattern pPet = Pattern.compile("(?s)      getlocal0\\n      getproperty         QName\\(PrivateNamespace\\(null, \"Avatar\"\\), \"petLoader\"\\)\\n      findpropstrict      QName\\(PackageNamespace\\(\"flash\\.net\"\\), \"URLRequest\"\\).*?      callpropvoid        QName\\(PackageNamespace\\(\"\"\\), \"load\"\\), 2");
            Matcher mPet = pPet.matcher(avContent);
            if (mPet.find()) {
                String replPetCall =
                      "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"failedServers\")\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"mobile\")\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PrivateNamespace(null, \"Avatar\"), \"petLoader\")\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      callproperty        Multiname(\"getFilePath\", [PrivateNamespace(null, \"Avatar\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Avatar/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"Avatar\"), StaticProtectedNs(\"Avatar\")]), 0\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"objData\")\n"
                    + "      getproperty         Multiname(\"eqp\", [PrivateNamespace(null, \"Avatar\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Avatar/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"Avatar\"), StaticProtectedNs(\"Avatar\")])\n"
                    + "      pushstring          \"pe\"\n"
                    + "      getproperty         MultinameL([PrivateNamespace(null, \"Avatar\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Avatar/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"Avatar\"), StaticProtectedNs(\"Avatar\")])\n"
                    + "      getproperty         Multiname(\"sFile\", [PrivateNamespace(null, \"Avatar\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Avatar/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"Avatar\"), StaticProtectedNs(\"Avatar\")])\n"
                    + "      add\n"
                    + "      callproperty        Multiname(\"vswf\", [PrivateNamespace(null, \"Avatar\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Avatar/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"Avatar\"), StaticProtectedNs(\"Avatar\")]), 1\n"
                    + "      getlocal0\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      getproperty         Multiname(\"world\", [PrivateNamespace(null, \"Avatar\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Avatar/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"Avatar\"), StaticProtectedNs(\"Avatar\")])\n"
                    + "      getproperty         Multiname(\"loaderC\", [PrivateNamespace(null, \"Avatar\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Avatar/instance\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"Avatar\"), StaticProtectedNs(\"Avatar\")])\n"
                    + "      callpropvoid        QName(PackageNamespace(\"\"), \"queueLoadViaBytes\"), 3";
                avContent = mPet.replaceFirst(replPetCall);
                System.out.println("  -> Avatar pet loading patched to queueLoadViaBytes");
                avModified = true;
            }

            Pattern pPetStack = Pattern.compile("(?s)(refid \"Avatar/instance/loadPet\".*?body\\s+maxstack )\\d+");
            Matcher mPetStack = pPetStack.matcher(avContent);
            if (mPetStack.find()) {
                avContent = mPetStack.replaceFirst("$112");
                System.out.println("  -> Avatar.loadPet maxstack patched to 12");
                avModified = true;
            }

            if (avModified) {
                Files.writeString(avatarAsasm, avContent);
            }
        }

        // 7. Fix VerifyError: Error #1023 in inline_method#23 (ExtHandler response callback)
        Path m23Path = targetDir.resolve("Game.instance.init/inline_method#23.method.asasm");
        if (Files.exists(m23Path)) {
            String m23Content = Files.readString(m23Path).replace("\r\n", "\n");
            if (m23Content.contains("  maxstack 9\n")) {
                m23Content = m23Content.replaceFirst("  maxstack 9\n", "  maxstack 128\n");
                Files.writeString(m23Path, m23Content);
                System.out.println("  -> inline_method#23 maxstack patched to 128 (fixed VerifyError #1023)");
            }
        }

        // 8. Fix Game.class.asasm: assetsContext allowCodeImport, startGameMenuLoad, and loadExternalAssets
        Path gameAsasm = targetDir.resolve("Game.class.asasm");
        if (Files.exists(gameAsasm)) {
            System.out.println("Patching Game.class.asasm for assets & gameMenu loading...");
            String gameContent = Files.readString(gameAsasm).replace("\r\n", "\n");
            boolean gameModified = false;

            // 8-0. Add trait slot pocket to Game.class.asasm (enables gameMovieClip.pocket = this and rootClass.pocket)
            String failedServersTrait = "trait slot QName(PackageNamespace(\"\"), \"failedServers\") end";
            if (gameContent.contains(failedServersTrait) && !gameContent.contains("trait slot QName(PackageNamespace(\"\"), \"pocket\") end")) {
                gameContent = gameContent.replace(failedServersTrait, failedServersTrait + "\n  trait slot QName(PackageNamespace(\"\"), \"pocket\") end");
                System.out.println("  -> Game trait slot pocket added");
                gameModified = true;
            }

            // 8a. assetsContext allowCodeImport in constructor
            String ctorAssetsCtx = "initproperty        QName(PackageNamespace(\"\"), \"assetsContext\")";
            if (gameContent.contains(ctorAssetsCtx) && !gameContent.contains("assetsContext\")\n      getlocal0\n      getproperty         QName(PackageNamespace(\"\"), \"assetsContext\")\n      pushtrue\n      setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")")) {
                gameContent = gameContent.replace(ctorAssetsCtx, ctorAssetsCtx + "\n      getlocal0\n      getproperty         QName(PackageNamespace(\"\"), \"assetsContext\")\n      pushtrue\n      setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")");
                System.out.println("  -> Game constructor assetsContext allowCodeImport patched");
                gameModified = true;
            }

            // 8b. startGameMenuLoad -> queueLoadViaBytes
            int menuMethodIdx = gameContent.indexOf("refid \"Game/instance/Game/startGameMenuLoad\"");
            if (menuMethodIdx != -1) {
                int endMethodIdx = gameContent.indexOf("end ; trait", menuMethodIdx);
                String methodSub = gameContent.substring(menuMethodIdx, endMethodIdx);
                Pattern pMenu = Pattern.compile("(?s)L52:\\n\\s+getlocal0\\n\\s+getproperty\\s+Multiname\\(\"gameMenuLoader\".*?callpropvoid\\s+Multiname\\(\"load\".*?\\), 2");
                Matcher mMenu = pMenu.matcher(methodSub);
                if (mMenu.find()) {
                    String replMenuCall =
                          "L52:\n"
                        + "      getlocal0\n"
                        + "      getproperty         QName(PackageNamespace(\"\"), \"failedServers\")\n"
                        + "      getproperty         QName(PackageNamespace(\"\"), \"mobile\")\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"gameMenuLoader\", [PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                        + "      getscopeobject      1\n"
                        + "      getslot             1\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"assetsContext\", [PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                        + "      callpropvoid        QName(PackageNamespace(\"\"), \"queueLoadViaBytes\"), 3";
                    String newMethodSub = mMenu.replaceFirst(replMenuCall);
                    gameContent = gameContent.substring(0, menuMethodIdx) + newMethodSub + gameContent.substring(endMethodIdx);
                    System.out.println("  -> Game.startGameMenuLoad patched to queueLoadViaBytes");
                    gameModified = true;
                } else {
                    System.err.println("  -> WARNING: startGameMenuLoad pattern not found!");
                }
            }

            Pattern pMenuStack = Pattern.compile("(?s)(refid \"Game/instance/Game/startGameMenuLoad\".*?body\\s+maxstack )\\d+");
            Matcher mMenuStack = pMenuStack.matcher(gameContent);
            if (mMenuStack.find()) {
                gameContent = mMenuStack.replaceFirst("$110");
                System.out.println("  -> Game.startGameMenuLoad maxstack patched to 10");
                gameModified = true;
            }

            // 8c. loadExternalAssets -> queueLoadViaBytes
            int assetsMethodIdx = gameContent.indexOf("refid \"Game/instance/Game/loadExternalAssets\"");
            if (assetsMethodIdx != -1) {
                int endMethodIdx = gameContent.indexOf("end ; trait", assetsMethodIdx);
                String methodSub = gameContent.substring(assetsMethodIdx, endMethodIdx);
                Pattern pAssets = Pattern.compile("(?s)getlocal0\\n\\s+getproperty\\s+Multiname\\(\"assetsLoader\", [^\\]]+\\]\\)\\n\\s+getlocal2\\n\\s+getlocal0\\n\\s+getproperty\\s+Multiname\\(\"assetsContext\", [^\\]]+\\]\\)\\n\\s+callpropvoid\\s+Multiname\\(\"load\", [^\\]]+\\]\\), 2");
                Matcher mAssets = pAssets.matcher(methodSub);
                if (mAssets.find()) {
                    String replAssetsCall =
                          "getlocal0\n"
                        + "      getproperty         QName(PackageNamespace(\"\"), \"failedServers\")\n"
                        + "      getproperty         QName(PackageNamespace(\"\"), \"mobile\")\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"assetsLoader\", [PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                        + "      getlocal2\n"
                        + "      getproperty         QName(PackageNamespace(\"\"), \"url\")\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"assetsContext\", [PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                        + "      callpropvoid        QName(PackageNamespace(\"\"), \"queueLoadViaBytes\"), 3";
                    String newMethodSub = mAssets.replaceFirst(replAssetsCall);
                    gameContent = gameContent.substring(0, assetsMethodIdx) + newMethodSub + gameContent.substring(endMethodIdx);
                    System.out.println("  -> Game.loadExternalAssets patched to queueLoadViaBytes");
                    gameModified = true;
                } else {
                    System.err.println("  -> WARNING: loadExternalAssets pattern not found!");
                }
            }

            Pattern pAssetsStack = Pattern.compile("(?s)(refid \"Game/instance/Game/loadExternalAssets\".*?body\\s+maxstack )\\d+");
            Matcher mAssetsStack = pAssetsStack.matcher(gameContent);
            if (mAssetsStack.find()) {
                gameContent = mAssetsStack.replaceFirst("$110");
                System.out.println("  -> Game.loadExternalAssets maxstack patched to 10");
                gameModified = true;
            }

            // 8d. Book of Lore (BoL) patches:
            // 8d-1. onBoLComplete: load local app:/gamefiles/book-of-lore.swf via queueLoadViaBytes
            int bolCompleteIdx = gameContent.indexOf("refid \"Game/instance/onBoLComplete\"");
            if (bolCompleteIdx != -1) {
                int endCompleteIdx = gameContent.indexOf("end ; trait", bolCompleteIdx);
                String completeSub = gameContent.substring(bolCompleteIdx, endCompleteIdx);
                Pattern pBol = Pattern.compile("(?s)(callpropvoid\\s+Multiname\\(\"addEventListener\", .*?\\), 5\\s+)getlocal0\\s+getproperty\\s+Multiname\\(\"bolLoader\".*?findpropstrict\\s+Multiname\\(\"URLRequest\".*?callpropvoid\\s+Multiname\\(\"load\".*?\\), 2");
                Matcher mBol = pBol.matcher(completeSub);
                if (mBol.find()) {
                    String nsGame = "[PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")]";
                    String nsGameSys = "[PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\"), PackageNamespace(\"flash.system\")]";
                    String replBolCall =
                          "getlocal0\n"
                        + "      getproperty         QName(PackageNamespace(\"\"), \"failedServers\")\n"
                        + "      getproperty         QName(PackageNamespace(\"\"), \"mobile\")\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"bolLoader\", " + nsGame + ")\n"
                        + "      pushstring          \"app:/gamefiles/spiderbook3.swf\"\n"
                        + "      findpropstrict      Multiname(\"LoaderContext\", " + nsGameSys + ")\n"
                        + "      pushfalse\n"
                        + "      findpropstrict      Multiname(\"ApplicationDomain\", " + nsGameSys + ")\n"
                        + "      getlex              Multiname(\"ApplicationDomain\", " + nsGameSys + ")\n"
                        + "      getproperty         Multiname(\"currentDomain\", " + nsGameSys + ")\n"
                        + "      constructprop       Multiname(\"ApplicationDomain\", " + nsGameSys + "), 1\n"
                        + "      constructprop       Multiname(\"LoaderContext\", " + nsGameSys + "), 2\n"
                        + "      callpropvoid        QName(PackageNamespace(\"\"), \"queueLoadViaBytes\"), 3";
                    completeSub = mBol.replaceFirst(Matcher.quoteReplacement(mBol.group(1) + replBolCall));
                    gameContent = gameContent.substring(0, bolCompleteIdx) + completeSub + gameContent.substring(endCompleteIdx);
                    System.out.println("  -> Game.onBoLComplete patched to queueLoadViaBytes (local app:/gamefiles/spiderbook3.swf)");
                    gameModified = true;
                } else {
                    System.err.println("  -> WARNING: onBoLComplete bolLoader pattern not found!");
                }
            }

            Pattern pBolStack = Pattern.compile("(?s)(refid \"Game/instance/onBoLComplete\".*?body\\s+maxstack )\\d+");
            Matcher mBolStack = pBolStack.matcher(gameContent);
            if (mBolStack.find()) {
                gameContent = mBolStack.replaceFirst("$110");
                System.out.println("  -> Game.onBoLComplete maxstack patched to 10");
                gameModified = true;
            }

            // 8d-2. onBoLProgress: null-check on travelLoaderMC to prevent Error #1009
            int bolProgIdx = gameContent.indexOf("refid \"Game/instance/Game/onBoLProgress\"");
            if (bolProgIdx != -1) {
                int endProgIdx = gameContent.indexOf("end ; trait", bolProgIdx);
                String progSub = gameContent.substring(bolProgIdx, endProgIdx);
                if (!progSub.contains("travelLoaderMC") || !progSub.contains("pushnull\n      ifeq")) {
                    Matcher labelMatcher = Pattern.compile("(?m)^\\s*(L\\d+):\\s*\\n\\s*returnvoid").matcher(progSub);
                    String returnLabel = labelMatcher.find() ? labelMatcher.group(1) : "L79";

                    Pattern pProg = Pattern.compile("(?s)(convert_d\\s+setlocal3\\s+)(getlocal0\\s+getproperty\\s+Multiname\\(\"travelLoaderMC\")");
                    Matcher mProg = pProg.matcher(progSub);
                    if (mProg.find()) {
                        String nullCheck = "$1getlocal0\n      getproperty         Multiname(\"travelLoaderMC\", [PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n      pushnull\n      ifeq                " + returnLabel + "\n\n      $2";
                        progSub = mProg.replaceFirst(nullCheck);
                        gameContent = gameContent.substring(0, bolProgIdx) + progSub + gameContent.substring(endProgIdx);
                        System.out.println("  -> Game.onBoLProgress patched with null check for travelLoaderMC (label: " + returnLabel + ")");
                        gameModified = true;
                    }
                }
            }

            // 8d-3. onBoLContentComplete: safe attachment and initialization to NavMenu
            int bolContentCompIdx = gameContent.indexOf("refid \"Game/instance/onBoLContentComplete\"");
            if (bolContentCompIdx != -1) {
                int endContentCompIdx = gameContent.indexOf("end ; trait", bolContentCompIdx);
                String contentCompSub = gameContent.substring(bolContentCompIdx, endContentCompIdx);
                Pattern pContentAttach = Pattern.compile("(?s)getlocal0\\s+getproperty\\s+Multiname\\(\"ui\",.*?callpropvoid\\s+Multiname\\(\"addChild\",.*?\\), 1");
                Matcher mContentAttach = pContentAttach.matcher(contentCompSub);
                if (mContentAttach.find()) {
                    String nsGame = "[PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")]";
                    String safeAttach =
                          "getlocal0\n"
                        + "      getproperty         Multiname(\"newInstance\", " + nsGame + ")\n"
                        + "      iffalse             L_NO_NAV\n\n"
                        + "      getlocal0\n"
                        + "      pushfalse\n"
                        + "      setproperty         Multiname(\"newInstance\", " + nsGame + ")\n\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"bolContent\", " + nsGame + ")\n"
                        + "      pushstring          \"NavMenu\"\n"
                        + "      callpropvoid        Multiname(\"gotoAndStop\", " + nsGame + "), 1\n\n"
                        + "L_NO_NAV:\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"ui\", " + nsGame + ")\n"
                        + "      pushnull\n"
                        + "      ifeq                L_END\n\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"ui\", " + nsGame + ")\n"
                        + "      getproperty         Multiname(\"mcPopup\", " + nsGame + ")\n"
                        + "      pushnull\n"
                        + "      ifeq                L_END\n\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"ui\", " + nsGame + ")\n"
                        + "      getproperty         Multiname(\"mcPopup\", " + nsGame + ")\n"
                        + "      getproperty         Multiname(\"currentLabel\", " + nsGame + ")\n"
                        + "      pushstring          \"Book\"\n"
                        + "      ifne                L_END\n\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"ui\", " + nsGame + ")\n"
                        + "      getproperty         Multiname(\"mcPopup\", " + nsGame + ")\n"
                        + "      getproperty         Multiname(\"mcBook\", " + nsGame + ")\n"
                        + "      pushnull\n"
                        + "      ifeq                L_END\n\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"ui\", " + nsGame + ")\n"
                        + "      getproperty         Multiname(\"mcPopup\", " + nsGame + ")\n"
                        + "      getproperty         Multiname(\"mcBook\", " + nsGame + ")\n"
                        + "      getproperty         Multiname(\"numChildren\", " + nsGame + ")\n"
                        + "      pushbyte            0\n"
                        + "      ifle                L_DO_ADD\n\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"ui\", " + nsGame + ")\n"
                        + "      getproperty         Multiname(\"mcPopup\", " + nsGame + ")\n"
                        + "      getproperty         Multiname(\"mcBook\", " + nsGame + ")\n"
                        + "      pushbyte            0\n"
                        + "      callpropvoid        Multiname(\"removeChildAt\", " + nsGame + "), 1\n\n"
                        + "L_DO_ADD:\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"ui\", " + nsGame + ")\n"
                        + "      getproperty         Multiname(\"mcPopup\", " + nsGame + ")\n"
                        + "      getproperty         Multiname(\"mcBook\", " + nsGame + ")\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"bolContent\", " + nsGame + ")\n"
                        + "      callpropvoid        Multiname(\"addChild\", " + nsGame + "), 1\n\n"
                        + "L_END:";
                    contentCompSub = mContentAttach.replaceFirst(Matcher.quoteReplacement(safeAttach));
                    gameContent = gameContent.substring(0, bolContentCompIdx) + contentCompSub + gameContent.substring(endContentCompIdx);
                    System.out.println("  -> Game.onBoLContentComplete patched with safe attach and nav init");
                    gameModified = true;
                }
            }

            Pattern pContentStack = Pattern.compile("(?s)(refid \"Game/instance/onBoLContentComplete\".*?body\\s+maxstack )\\d+");
            Matcher mContentStack = pContentStack.matcher(gameContent);
            if (mContentStack.find()) {
                gameContent = mContentStack.replaceFirst("$110");
                System.out.println("  -> Game.onBoLContentComplete maxstack patched to 10");
                gameModified = true;
            }

            // 8e. Travel Map patches:
            // 8e-1. onTravelMapComplete: load local app:/gamefiles/Map-UI_r38.swf instead of remote URL
            int mapCompleteIdx = gameContent.indexOf("refid \"Game/instance/Game/onTravelMapComplete\"");
            if (mapCompleteIdx != -1) {
                int endMapCompleteIdx = gameContent.indexOf("end ; trait", mapCompleteIdx);
                String mapSub = gameContent.substring(mapCompleteIdx, endMapCompleteIdx);
                Pattern pMapReq = Pattern.compile("(?s)findpropstrict\\s+Multiname\\(\"URLRequest\".*?findpropstrict\\s+Multiname\\(\"vurl\".*?constructprop\\s+Multiname\\(\"URLRequest\".*?\\), 1\\s+findpropstrict\\s+Multiname\\(\"LoaderContext\".*?constructprop\\s+Multiname\\(\"LoaderContext\".*?\\), 2");
                Matcher mMapReq = pMapReq.matcher(mapSub);
                if (mMapReq.find()) {
                    String replMapReq = "findpropstrict      Multiname(\"URLRequest\", [PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\"), PackageNamespace(\"flash.net\")])\n"
                                      + "      pushstring          \"app:/gamefiles/Map-UI_r38.swf\"\n"
                                      + "      constructprop       Multiname(\"URLRequest\", [PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\"), PackageNamespace(\"flash.net\")]), 1\n"
                                      + "      findpropstrict      Multiname(\"LoaderContext\", [PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\"), PackageNamespace(\"flash.system\")])\n"
                                      + "      pushfalse\n"
                                      + "      getlex              Multiname(\"ApplicationDomain\", [PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\"), PackageNamespace(\"flash.system\")])\n"
                                      + "      getproperty         Multiname(\"currentDomain\", [PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                                      + "      constructprop       Multiname(\"LoaderContext\", [PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\"), PackageNamespace(\"flash.system\")]), 2\n"
                                      + "      dup\n"
                                      + "      pushtrue\n"
                                      + "      setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")";
                    mapSub = mMapReq.replaceFirst(replMapReq);

                    // Raise maxstack for onTravelMapComplete to 10
                    mapSub = Pattern.compile("(?s)(body\\s+maxstack )\\d+").matcher(mapSub).replaceFirst("$110");

                    gameContent = gameContent.substring(0, mapCompleteIdx) + mapSub + gameContent.substring(endMapCompleteIdx);
                    System.out.println("  -> Game.onTravelMapComplete patched to load app:/gamefiles/Map-UI_r38.swf with allowCodeImport");
                    gameModified = true;
                }
            }

            // 8e-2. onTravelMapProgress: null-check on travelLoaderMC to prevent Error #1009
            int mapProgIdx = gameContent.indexOf("refid \"Game/instance/Game/onTravelMapProgress\"");
            if (mapProgIdx != -1) {
                int endMapProgIdx = gameContent.indexOf("end ; trait", mapProgIdx);
                String mapProgSub = gameContent.substring(mapProgIdx, endMapProgIdx);
                if (!mapProgSub.contains("travelLoaderMC") || !mapProgSub.contains("pushnull\n      ifeq")) {
                    // Find the return label preceding 'returnvoid'
                    Matcher labelMatcher = Pattern.compile("(?m)^\\s*(L\\d+):\\s*\\n\\s*returnvoid").matcher(mapProgSub);
                    String returnLabel = labelMatcher.find() ? labelMatcher.group(1) : "L47";

                    Pattern pProg = Pattern.compile("(?s)(convert_d\\s+setlocal3\\s+)(getlocal0\\s+getproperty\\s+Multiname\\(\"travelLoaderMC\")");
                    Matcher mProg = pProg.matcher(mapProgSub);
                    if (mProg.find()) {
                        String nullCheck = "$1getlocal0\n      getproperty         Multiname(\"travelLoaderMC\", [PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n      pushnull\n      ifeq                " + returnLabel + "\n\n      $2";
                        mapProgSub = mProg.replaceFirst(nullCheck);

                        // Raise maxstack for onTravelMapProgress to 6
                        mapProgSub = Pattern.compile("(?s)(body\\s+maxstack )\\d+").matcher(mapProgSub).replaceFirst("$16");

                        gameContent = gameContent.substring(0, mapProgIdx) + mapProgSub + gameContent.substring(endMapProgIdx);
                        System.out.println("  -> Game.onTravelMapProgress patched with null check for travelLoaderMC (label: " + returnLabel + ")");
                        gameModified = true;
                    }
                }
            }

            // 8f. checkInterfaceQueue: load remote interface SWFs (OutfitSets, polling, friendships) via pocket.load
            int ifQueueIdx = gameContent.indexOf("refid \"Game/instance/checkInterfaceQueue\"");
            if (ifQueueIdx != -1) {
                int endIfQueueIdx = gameContent.indexOf("end ; trait", ifQueueIdx);
                String ifQueueSub = gameContent.substring(ifQueueIdx, endIfQueueIdx);
                Pattern pIfQueue = Pattern.compile("(?s)getlocal1\\s+findpropstrict\\s+Multiname\\(\"URLRequest\".*?callpropvoid\\s+Multiname\\(\"load\".*?\\), 2");
                Matcher mIfQueue = pIfQueue.matcher(ifQueueSub);
                if (mIfQueue.find()) {
                    String nsGame = "[PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")]";
                    String nsGameSys = "[PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\"), PackageNamespace(\"flash.system\")]";
                    String replIfQueue =
                          "getlocal0\n"
                        + "      getproperty         Multiname(\"pocket\", " + nsGame + ")\n"
                        + "      getlocal1\n"
                        + "      findpropstrict      Multiname(\"vurl\", " + nsGame + ")\n"
                        + "      getlocal0\n"
                        + "      callproperty        Multiname(\"getFilePath\", " + nsGame + "), 0\n"
                        + "      pushstring          \"interface/\"\n"
                        + "      add\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"interfaceQueue\", " + nsGame + ")\n"
                        + "      pushbyte            0\n"
                        + "      getproperty         MultinameL(" + nsGame + ")\n"
                        + "      getproperty         Multiname(\"intrf\", " + nsGame + ")\n"
                        + "      add\n"
                        + "      callproperty        Multiname(\"vurl\", " + nsGame + "), 1\n"
                        + "      findpropstrict      Multiname(\"LoaderContext\", " + nsGameSys + ")\n"
                        + "      pushfalse\n"
                        + "      findpropstrict      Multiname(\"ApplicationDomain\", " + nsGameSys + ")\n"
                        + "      getlex              Multiname(\"ApplicationDomain\", " + nsGameSys + ")\n"
                        + "      getproperty         Multiname(\"currentDomain\", " + nsGameSys + ")\n"
                        + "      constructprop       Multiname(\"ApplicationDomain\", " + nsGameSys + "), 1\n"
                        + "      constructprop       Multiname(\"LoaderContext\", " + nsGameSys + "), 2\n"
                        + "      callpropvoid        Multiname(\"load\", " + nsGame + "), 3";
                    ifQueueSub = mIfQueue.replaceFirst(Matcher.quoteReplacement(replIfQueue));

                    // Raise maxstack for checkInterfaceQueue to 10
                    ifQueueSub = Pattern.compile("(?s)(body\\s+maxstack )\\d+").matcher(ifQueueSub).replaceFirst("$110");

                    gameContent = gameContent.substring(0, ifQueueIdx) + ifQueueSub + gameContent.substring(endIfQueueIdx);
                    System.out.println("  -> Game.checkInterfaceQueue patched to pocket.load");
                    gameModified = true;
                } else {
                    System.err.println("  -> WARNING: checkInterfaceQueue pattern not found!");
                }
            }

            // 8g. frame43: character select loading via queueLoadViaBytes (fixes SecurityError #2193)
            int frame43Idx = gameContent.indexOf("refid \"Game/instance/frame43\"");
            if (frame43Idx != -1) {
                int endFrame43Idx = gameContent.indexOf("end ; trait", frame43Idx);
                String frame43Sub = gameContent.substring(frame43Idx, endFrame43Idx);
                Pattern pFrame43 = Pattern.compile("(?s)getlocal0\\s+getproperty\\s+Multiname\\(\"csLoader\", [^\\]]+\\]\\)\\s+findpropstrict\\s+Multiname\\(\"URLRequest\", [^\\]]+\\]\\)\\s+getlocal0\\s+getproperty\\s+Multiname\\(\"fileUrl\", [^\\]]+\\]\\)\\s+constructprop\\s+Multiname\\(\"URLRequest\", [^\\]]+\\]\\), 1\\s+callpropvoid\\s+Multiname\\(\"load\", [^\\]]+\\]\\), 1");
                Matcher mFrame43 = pFrame43.matcher(frame43Sub);
                if (mFrame43.find()) {
                    String nsGame = "[PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")]";
                    String nsGameSys = "[PrivateNamespace(null, \"Game#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"Game#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), PackageNamespace(\"flash.external\"), PackageNamespace(\"it.gotoandplay.smartfoxserver\"), PackageNamespace(\"liteAssets.draw\"), ProtectedNamespace(\"Game\"), StaticProtectedNs(\"Game\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\"), PackageNamespace(\"flash.system\")]";
                    String replFrame43 =
                          "getlocal0\n"
                        + "      getproperty         QName(PackageNamespace(\"\"), \"failedServers\")\n"
                        + "      getproperty         QName(PackageNamespace(\"\"), \"mobile\")\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"csLoader\", " + nsGame + ")\n"
                        + "      pushstring          \"app:/gamefiles/charselect.swf\"\n"
                        + "      findpropstrict      Multiname(\"LoaderContext\", " + nsGameSys + ")\n"
                        + "      pushfalse\n"
                        + "      getlex              Multiname(\"ApplicationDomain\", " + nsGameSys + ")\n"
                        + "      getproperty         Multiname(\"currentDomain\", " + nsGameSys + ")\n"
                        + "      constructprop       Multiname(\"LoaderContext\", " + nsGameSys + "), 2\n"
                        + "      dup\n"
                        + "      pushtrue\n"
                        + "      setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")\n"
                        + "      callpropvoid        QName(PackageNamespace(\"\"), \"queueLoadViaBytes\"), 3";
                    frame43Sub = mFrame43.replaceFirst(Matcher.quoteReplacement(replFrame43));

                    // Raise maxstack for frame43 to 10
                    frame43Sub = Pattern.compile("(?s)(body\\s+maxstack )\\d+").matcher(frame43Sub).replaceFirst("$110");

                    gameContent = gameContent.substring(0, frame43Idx) + frame43Sub + gameContent.substring(endFrame43Idx);
                    System.out.println("  -> Game.frame43 patched to queueLoadViaBytes for Character Select (fixes Error #2193)");
                    gameModified = true;
                } else {
                    System.err.println("  -> WARNING: frame43 csLoader load pattern not found!");
                }
            }

            if (gameModified) {
                Files.writeString(gameAsasm, gameContent);
            }
        }

        // 9. Patch PreviewAssetLoader allowCodeImport and route doLoad via queueLoadViaBytes
        Path palAsasm = targetDir.resolve("PreviewAssetLoader.class.asasm");
        if (Files.exists(palAsasm)) {
            System.out.println("Patching PreviewAssetLoader.class.asasm...");
            String palContent = Files.readString(palAsasm).replace("\r\n", "\n");
            boolean palModified = false;

            // 9a. sharedContext allowCodeImport
            Pattern sharedPattern = Pattern.compile("([ \\t]*constructprop[ \\t]+Multiname\\(\"LoaderContext\",.*?\\),[ \\t]*2[ \\t]*\\n[ \\t]*setproperty[ \\t]+Multiname\\(\"sharedContext\",.*?\\]\\))");
            Matcher sharedMatcher = sharedPattern.matcher(palContent);
            if (sharedMatcher.find()) {
                String match = sharedMatcher.group(1);
                String repl = match + "\n      getlex              Multiname(\"sharedContext\", [PrivateNamespace(null, \"PreviewAssetLoader#0\"), PrivateNamespace(null, \"PreviewAssetLoader#1\"), PackageNamespace(\"\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"PreviewAssetLoader\"), StaticProtectedNs(\"PreviewAssetLoader\")])\n      pushtrue\n      setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")";
                palContent = palContent.replace(match, repl);
                System.out.println("  -> PreviewAssetLoader sharedContext allowCodeImport patched");
                palModified = true;
            }

            // 9b. pLoaderC allowCodeImport (both in constructor and resetDomain)
            Pattern pLoaderCPattern = Pattern.compile("([ \\t]*constructprop[ \\t]+Multiname\\(\"LoaderContext\",.*?\\),[ \\t]*2[ \\t]*\\n[ \\t]*initproperty[ \\t]+Multiname\\(\"pLoaderC\",.*?\\]\\))");
            Matcher pLoaderCMatcher = pLoaderCPattern.matcher(palContent);
            StringBuilder sb = new StringBuilder();
            int pLoaderCCount = 0;
            while (pLoaderCMatcher.find()) {
                String match = pLoaderCMatcher.group(1);
                String appendCode = "\n      getlocal0\n      getproperty         Multiname(\"pLoaderC\", [PrivateNamespace(null, \"PreviewAssetLoader#0\"), PrivateNamespace(null, \"PreviewAssetLoader#1\"), PackageNamespace(\"\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"PreviewAssetLoader\"), StaticProtectedNs(\"PreviewAssetLoader\")])\n      pushtrue\n      setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")";
                pLoaderCMatcher.appendReplacement(sb, Matcher.quoteReplacement(match + appendCode));
                pLoaderCCount++;
            }
            pLoaderCMatcher.appendTail(sb);
            if (pLoaderCCount > 0) {
                palContent = sb.toString();
                System.out.println("  -> PreviewAssetLoader pLoaderC allowCodeImport patched (" + pLoaderCCount + " sites)");
                palModified = true;
            }

            // 9c. doLoad -> queueLoadViaBytes
            String doLoadTarget = "      getscopeobject      1\n"
                    + "      getslot             2\n"
                    + "      findpropstrict      Multiname(\"URLRequest\", [PrivateNamespace(null, \"PreviewAssetLoader#0\"), PrivateNamespace(null, \"PreviewAssetLoader#1\"), PackageNamespace(\"\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"PreviewAssetLoader\"), StaticProtectedNs(\"PreviewAssetLoader\"), PackageNamespace(\"flash.net\")])\n"
                    + "      getlocal0\n"
                    + "      getscopeobject      1\n"
                    + "      getslot             1\n"
                    + "      callproperty        Multiname(\"bustURL\", [PrivateNamespace(null, \"PreviewAssetLoader#0\"), PrivateNamespace(null, \"PreviewAssetLoader#1\"), PackageNamespace(\"\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"PreviewAssetLoader\"), StaticProtectedNs(\"PreviewAssetLoader\")]), 1\n"
                    + "      constructprop       Multiname(\"URLRequest\", [PrivateNamespace(null, \"PreviewAssetLoader#0\"), PrivateNamespace(null, \"PreviewAssetLoader#1\"), PackageNamespace(\"\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"PreviewAssetLoader\"), StaticProtectedNs(\"PreviewAssetLoader\"), PackageNamespace(\"flash.net\")]), 1\n"
                    + "      getlocal0\n"
                    + "      getproperty         Multiname(\"pLoaderC\", [PrivateNamespace(null, \"PreviewAssetLoader#0\"), PrivateNamespace(null, \"PreviewAssetLoader#1\"), PackageNamespace(\"\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"PreviewAssetLoader\"), StaticProtectedNs(\"PreviewAssetLoader\")])\n"
                    + "      callpropvoid        Multiname(\"load\", [PrivateNamespace(null, \"PreviewAssetLoader#0\"), PrivateNamespace(null, \"PreviewAssetLoader#1\"), PackageNamespace(\"\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"PreviewAssetLoader\"), StaticProtectedNs(\"PreviewAssetLoader\")]), 2";

            if (palContent.contains(doLoadTarget)) {
                String doLoadRepl = "      getlocal0\n"
                        + "      getproperty         Multiname(\"rootClass\", [PrivateNamespace(null, \"PreviewAssetLoader#0\"), PrivateNamespace(null, \"PreviewAssetLoader#1\"), PackageNamespace(\"\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"PreviewAssetLoader\"), StaticProtectedNs(\"PreviewAssetLoader\")])\n"
                        + "      getproperty         QName(PackageNamespace(\"\"), \"failedServers\")\n"
                        + "      getproperty         QName(PackageNamespace(\"\"), \"mobile\")\n"
                        + "      getscopeobject      1\n"
                        + "      getslot             2\n"
                        + "      getlocal0\n"
                        + "      getscopeobject      1\n"
                        + "      getslot             1\n"
                        + "      callproperty        Multiname(\"bustURL\", [PrivateNamespace(null, \"PreviewAssetLoader#0\"), PrivateNamespace(null, \"PreviewAssetLoader#1\"), PackageNamespace(\"\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"PreviewAssetLoader\"), StaticProtectedNs(\"PreviewAssetLoader\")]), 1\n"
                        + "      getlocal0\n"
                        + "      getproperty         Multiname(\"pLoaderC\", [PrivateNamespace(null, \"PreviewAssetLoader#0\"), PrivateNamespace(null, \"PreviewAssetLoader#1\"), PackageNamespace(\"\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"PreviewAssetLoader\"), StaticProtectedNs(\"PreviewAssetLoader\")])\n"
                        + "      callpropvoid        QName(PackageNamespace(\"\"), \"queueLoadViaBytes\"), 3";

                palContent = palContent.replace(doLoadTarget, doLoadRepl);

                // Update maxstack in doLoad if needed
                int doLoadIdx = palContent.indexOf("refid \"PreviewAssetLoader/instance/PreviewAssetLoader/doLoad\"");
                if (doLoadIdx != -1) {
                    int maxstackIdx = palContent.indexOf("maxstack ", doLoadIdx);
                    if (maxstackIdx != -1 && maxstackIdx < doLoadIdx + 200) {
                        int endLine = palContent.indexOf("\n", maxstackIdx);
                        palContent = palContent.substring(0, maxstackIdx) + "maxstack 10" + palContent.substring(endLine);
                    }
                }

                System.out.println("  -> PreviewAssetLoader doLoad patched to queueLoadViaBytes");
                palModified = true;
            }

            if (palModified) {
                Files.writeString(palAsasm, palContent);
            }
        }

        // 10. Patch LPFFrameListViewTabbed null icon safety
        Path lpfTabbedAsasm = targetDir.resolve("LPFFrameListViewTabbed.class.asasm");
        if (Files.exists(lpfTabbedAsasm)) {
            System.out.println("Patching LPFFrameListViewTabbed.class.asasm for null icon safety...");
            String content = Files.readString(lpfTabbedAsasm).replace("\r\n", "\n");
            int methodIdx = content.indexOf("refid \"LPFFrameListViewTabbed/instance/LPFFrameListViewTabbed/instance/initTabs\"");
            if (methodIdx != -1) {
                int endMethodIdx = content.indexOf("end ; trait", methodIdx);
                String methodSub = content.substring(methodIdx, endMethodIdx);
                String targetBefore = "coerce              QName(PackageNamespace(\"\"), \"Object\")\n      setlocal            7\n\n      getlocal            6";
                String targetAfter = "pushbyte            2\n      setproperty         Multiname(\"y\", [PrivateNamespace(null, \"LPFFrameListViewTabbed/instance\"), PrivateNamespace(null, \"LPFFrameListViewTabbed\"), PackageNamespace(\"\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), ProtectedNamespace(\"LPFFrameListViewTabbed\"), StaticProtectedNs(\"LPFFrameListViewTabbed\"), StaticProtectedNs(\"LPFFrame\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n\n      getlocal            6";
                if (methodSub.contains(targetBefore) && methodSub.contains(targetAfter) && !methodSub.contains("L_SKIP_ICON")) {
                    methodSub = methodSub.replace(targetBefore, "coerce              QName(PackageNamespace(\"\"), \"Object\")\n      setlocal            7\n\n      getlocal            7\n      pushnull\n      ifeq                L_SKIP_ICON\n\n      getlocal            6");
                    methodSub = methodSub.replace(targetAfter, "pushbyte            2\n      setproperty         Multiname(\"y\", [PrivateNamespace(null, \"LPFFrameListViewTabbed/instance\"), PrivateNamespace(null, \"LPFFrameListViewTabbed\"), PackageNamespace(\"\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.text\"), ProtectedNamespace(\"LPFFrameListViewTabbed\"), StaticProtectedNs(\"LPFFrameListViewTabbed\"), StaticProtectedNs(\"LPFFrame\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n\nL_SKIP_ICON:\n      getlocal            6");
                    content = content.substring(0, methodIdx) + methodSub + content.substring(endMethodIdx);
                    Files.writeString(lpfTabbedAsasm, content);
                    System.out.println("  -> LPFFrameListViewTabbed null icon check patched");
                }
            }
        }

        // 11. Patch LoaderMC.loadFile: redirect load to queueLoadViaBytes (fixes Error #2193 on bagspace_2025.swf etc.)
        Path loaderMcAsasm = targetDir.resolve("LoaderMC.class.asasm");
        if (Files.exists(loaderMcAsasm)) {
            System.out.println("Patching LoaderMC.class.asasm for queueLoadViaBytes...");
            String content = Files.readString(loaderMcAsasm).replace("\r\n", "\n");
            boolean modified = false;

            Pattern pLoaderMC = Pattern.compile("(?s)(refid \"LoaderMC/instance/loadFile\".*?)getlocal\\s+6\\n\\s+findpropstrict\\s+Multiname\\(\"URLRequest\",.*?"
                + "callpropvoid\\s+Multiname\\(\"load\", [^\\]]+\\]\\), 2");
            Matcher mLoaderMC = pLoaderMC.matcher(content);
            if (mLoaderMC.find()) {
                String replLoaderMCCall =
                      "getlocal0\n"
                    + "      getproperty         Multiname(\"rootClass\", [PrivateNamespace(null, \"LoaderMC/instance\"), PackageNamespace(\"\"), PrivateNamespace(null, \"LoaderMC\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.events\"), ProtectedNamespace(\"LoaderMC\"), StaticProtectedNs(\"LoaderMC\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                    + "      getproperty         Multiname(\"failedServers\", [PrivateNamespace(null, \"LoaderMC/instance\"), PackageNamespace(\"\"), PrivateNamespace(null, \"LoaderMC\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.events\"), ProtectedNamespace(\"LoaderMC\"), StaticProtectedNs(\"LoaderMC\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                    + "      getproperty         Multiname(\"mobile\", [PrivateNamespace(null, \"LoaderMC/instance\"), PackageNamespace(\"\"), PrivateNamespace(null, \"LoaderMC\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.events\"), ProtectedNamespace(\"LoaderMC\"), StaticProtectedNs(\"LoaderMC\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                    + "      getlocal            6\n"
                    + "      getlex              Multiname(\"Game\", [PrivateNamespace(null, \"LoaderMC/instance\"), PackageNamespace(\"\"), PrivateNamespace(null, \"LoaderMC\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.events\"), ProtectedNamespace(\"LoaderMC\"), StaticProtectedNs(\"LoaderMC\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                    + "      getlocal2\n"
                    + "      callproperty        Multiname(\"vurl\", [PrivateNamespace(null, \"LoaderMC/instance\"), PackageNamespace(\"\"), PrivateNamespace(null, \"LoaderMC\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.events\"), ProtectedNamespace(\"LoaderMC\"), StaticProtectedNs(\"LoaderMC\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")]), 1\n"
                    + "      findpropstrict      Multiname(\"LoaderContext\", [PrivateNamespace(null, \"LoaderMC/instance\"), PackageNamespace(\"\"), PrivateNamespace(null, \"LoaderMC\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.events\"), ProtectedNamespace(\"LoaderMC\"), StaticProtectedNs(\"LoaderMC\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\"), PackageNamespace(\"flash.system\")])\n"
                    + "      pushfalse\n"
                    + "      findpropstrict      Multiname(\"ApplicationDomain\", [PrivateNamespace(null, \"LoaderMC/instance\"), PackageNamespace(\"\"), PrivateNamespace(null, \"LoaderMC\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.events\"), ProtectedNamespace(\"LoaderMC\"), StaticProtectedNs(\"LoaderMC\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\"), PackageNamespace(\"flash.system\")])\n"
                    + "      getlex              Multiname(\"ApplicationDomain\", [PrivateNamespace(null, \"LoaderMC/instance\"), PackageNamespace(\"\"), PrivateNamespace(null, \"LoaderMC\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.events\"), ProtectedNamespace(\"LoaderMC\"), StaticProtectedNs(\"LoaderMC\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\"), PackageNamespace(\"flash.system\")])\n"
                    + "      getproperty         Multiname(\"currentDomain\", [PrivateNamespace(null, \"LoaderMC/instance\"), PackageNamespace(\"\"), PrivateNamespace(null, \"LoaderMC\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.events\"), ProtectedNamespace(\"LoaderMC\"), StaticProtectedNs(\"LoaderMC\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                    + "      constructprop       Multiname(\"ApplicationDomain\", [PrivateNamespace(null, \"LoaderMC/instance\"), PackageNamespace(\"\"), PrivateNamespace(null, \"LoaderMC\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.events\"), ProtectedNamespace(\"LoaderMC\"), StaticProtectedNs(\"LoaderMC\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\"), PackageNamespace(\"flash.system\")]), 1\n"
                    + "      constructprop       Multiname(\"LoaderContext\", [PrivateNamespace(null, \"LoaderMC/instance\"), PackageNamespace(\"\"), PrivateNamespace(null, \"LoaderMC\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), PackageNamespace(\"flash.events\"), ProtectedNamespace(\"LoaderMC\"), StaticProtectedNs(\"LoaderMC\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\"), PackageNamespace(\"flash.system\")]), 2\n"
                    + "      callpropvoid        QName(PackageNamespace(\"\"), \"queueLoadViaBytes\"), 3";
                content = mLoaderMC.replaceFirst(Matcher.quoteReplacement(mLoaderMC.group(1) + replLoaderMCCall));
                System.out.println("  -> LoaderMC.loadFile patched to queueLoadViaBytes");
                modified = true;
            } else {
                System.err.println("  -> WARNING: LoaderMC.loadFile pattern not found!");
            }

            Pattern pLoaderMCStack = Pattern.compile("(?s)(refid \"LoaderMC/instance/loadFile\".*?body\\s+maxstack )\\d+");
            Matcher mLoaderMCStack = pLoaderMCStack.matcher(content);
            if (mLoaderMCStack.find()) {
                content = mLoaderMCStack.replaceFirst("$112");
                System.out.println("  -> LoaderMC.loadFile maxstack patched to 12");
                modified = true;
            }

            if (modified) {
                Files.writeString(loaderMcAsasm, content);
            }
        }

        // 12. Patch liteAssets/draw/qRewardPrev.class.asasm (fixes [Load] ERR missing linkage <Item> onLoadPetComplete,
        //     showQuestList ReferenceError #1069, and custom drop UI preview loading)
        Path qRewardPrevAsasm = targetDir.resolve("liteAssets/draw/qRewardPrev.class.asasm");
        Path patchQRewardPrev = Paths.get("patcher/qRewardPrev.class.asasm");
        if (!Files.exists(patchQRewardPrev)) {
            patchQRewardPrev = Paths.get("patches/qRewardPrev.class.asasm");
        }
        if (Files.exists(patchQRewardPrev)) {
            System.out.println("Patching qRewardPrev.class.asasm with complete patched implementation...");
            Files.copy(patchQRewardPrev, qRewardPrevAsasm, StandardCopyOption.REPLACE_EXISTING);
            System.out.println("  -> qRewardPrev.class.asasm replaced with full patched implementation (showQuestList + pocket.load + allowCodeImport)");
        }

        // 13. Patch mcPopup loadBook null-safety (fixes TypeError #2007 when BoL is loaded remotely)
        Path spiderFlaDir = targetDir.resolve("spider_fla");
        if (Files.exists(spiderFlaDir)) {
            try (var stream = Files.list(spiderFlaDir)) {
                List<Path> popupFiles = stream
                    .filter(p -> p.getFileName().toString().matches("mcPopup_\\d+\\.class\\.asasm"))
                    .collect(Collectors.toList());
                for (Path popupFile : popupFiles) {
                    patchMcPopup(popupFile);
                }
            }
        }
    }

    private static void patchMcPopup(Path popupFile) throws IOException {
        String content = Files.readString(popupFile);
        boolean modified = false;

        int loadBookIdx = content.indexOf("/instance/loadBook\"");
        if (loadBookIdx != -1) {
            int methodStart = content.lastIndexOf("trait method", loadBookIdx);
            int methodEnd = content.indexOf("end ; trait", loadBookIdx);
            if (methodStart != -1 && methodEnd != -1) {
                String methodSub = content.substring(methodStart, methodEnd);

                Pattern pNs = Pattern.compile("Multiname\\(\"rootClass\",\\s*(\\[.*?\\])\\)");
                Matcher mNs = pNs.matcher(methodSub);
                String ns = mNs.find() ? mNs.group(1) : "[]";

                // Null-check on rootClass.bolContent: if null, return immediately (safe async remote loading)
                Pattern pCheck = Pattern.compile("(?s)(callpropvoid\\s+Multiname\\(\"trace\".*?\\), 1\\s+)(getlocal0\\s+getproperty\\s+Multiname\\(\"mcBook\")");
                Matcher mCheck = pCheck.matcher(methodSub);
                if (mCheck.find()) {
                    String nullCheck = mCheck.group(1) + "getlocal0\n"
                        + "       getproperty         Multiname(\"rootClass\", " + ns + ")\n"
                        + "       getproperty         Multiname(\"bolContent\", " + ns + ")\n"
                        + "       pushnull\n"
                        + "       ifeq                L_RET\n\n"
                        + "       " + mCheck.group(2);
                    methodSub = mCheck.replaceFirst(Matcher.quoteReplacement(nullCheck));
                    modified = true;
                }

                // Guard mcBook.removeChildAt with numChildren > 0
                Pattern pRem = Pattern.compile("(?s)(getlocal0\\s+getproperty\\s+Multiname\\(\"mcBook\",.*?\n\\s+pushbyte\\s+0\n\\s+callpropvoid\\s+Multiname\\(\"removeChildAt\".*?\\), 1)");
                Matcher mRem = pRem.matcher(methodSub);
                if (mRem.find()) {
                    String safeRem = "getlocal0\n"
                        + "       getproperty         Multiname(\"mcBook\", " + ns + ")\n"
                        + "       getproperty         Multiname(\"numChildren\", " + ns + ")\n"
                        + "       pushbyte            0\n"
                        + "       ifle                L_NO_REM\n\n"
                        + "       " + mRem.group(1) + "\n\n"
                        + " L_NO_REM:";
                    methodSub = mRem.replaceFirst(Matcher.quoteReplacement(safeRem));
                    modified = true;
                }

                // Add L_RET label before returnvoid
                if (!methodSub.contains("L_RET:")) {
                    methodSub = methodSub.replace("returnvoid", "L_RET:\n       returnvoid");
                    modified = true;
                }

                // Stack size
                Pattern pStack = Pattern.compile("(body\\s+maxstack\\s+)\\d+");
                Matcher mStack = pStack.matcher(methodSub);
                if (mStack.find()) {
                    methodSub = mStack.replaceFirst("$16");
                    modified = true;
                }

                if (modified) {
                    content = content.substring(0, methodStart) + methodSub + content.substring(methodEnd);
                    System.out.println("  -> Patched " + popupFile.getFileName() + " loadBook with null check and safe child removal");
                }
            }
        }

        int loadMapIdx = content.indexOf("/instance/loadMap\"");
        if (loadMapIdx != -1) {
            int methodStart = content.lastIndexOf("trait method", loadMapIdx);
            int methodEnd = content.indexOf("end ; trait", loadMapIdx);
            if (methodStart != -1 && methodEnd != -1) {
                String methodSub = content.substring(methodStart, methodEnd);
                boolean mapModified = false;

                Pattern pNs = Pattern.compile("Multiname\\(\"mcMap\",\\s*(\\[.*?\\])\\)");
                Matcher mNs = pNs.matcher(methodSub);
                String ns = mNs.find() ? mNs.group(1) : "[]";

                // Guard mcMap.removeChildAt with numChildren > 0
                Pattern pMapRem = Pattern.compile("(?s)(getlocal0\\s+getproperty\\s+Multiname\\(\"mcMap\",.*?\n\\s+pushbyte\\s+0\n\\s+callpropvoid\\s+Multiname\\(\"removeChildAt\".*?\\), 1)");
                Matcher mMapRem = pMapRem.matcher(methodSub);
                if (mMapRem.find()) {
                    String safeMapRem = "getlocal0\n"
                        + "       getproperty         Multiname(\"mcMap\", " + ns + ")\n"
                        + "       getproperty         Multiname(\"numChildren\", " + ns + ")\n"
                        + "       pushbyte            0\n"
                        + "       ifle                L_NO_MAP_REM\n\n"
                        + "       " + mMapRem.group(1) + "\n\n"
                        + " L_NO_MAP_REM:";
                    methodSub = mMapRem.replaceFirst(Matcher.quoteReplacement(safeMapRem));
                    mapModified = true;
                }

                // Redirect URLRequest from remote server to app:/gamefiles/Map-UI_r38.swf with allowCodeImport = true
                Pattern pMapReq = Pattern.compile("(?s)getlocal2\\s+findpropstrict\\s+Multiname\\(\"URLRequest\".*?callpropvoid\\s+Multiname\\(\"load\".*?\\), 2");
                Matcher mMapReq = pMapReq.matcher(methodSub);
                if (mMapReq.find()) {
                    String replMapReq = "getlocal2\n"
                        + "       findpropstrict      Multiname(\"URLRequest\", " + ns + ")\n"
                        + "       pushstring          \"app:/gamefiles/Map-UI_r38.swf\"\n"
                        + "       constructprop       Multiname(\"URLRequest\", " + ns + "), 1\n"
                        + "       findpropstrict      Multiname(\"LoaderContext\", " + ns + ")\n"
                        + "       pushfalse\n"
                        + "       getlex              Multiname(\"ApplicationDomain\", " + ns + ")\n"
                        + "       getproperty         Multiname(\"currentDomain\", " + ns + ")\n"
                        + "       constructprop       Multiname(\"LoaderContext\", " + ns + "), 2\n"
                        + "       dup\n"
                        + "       pushtrue\n"
                        + "       setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")\n"
                        + "       callpropvoid        Multiname(\"load\", " + ns + "), 2";
                    methodSub = mMapReq.replaceFirst(Matcher.quoteReplacement(replMapReq));
                    mapModified = true;
                }

                // Bump stack to 8
                Pattern pStack = Pattern.compile("(body\\s+maxstack\\s+)\\d+");
                Matcher mStack = pStack.matcher(methodSub);
                if (mStack.find()) {
                    methodSub = mStack.replaceFirst("$18");
                    mapModified = true;
                }

                if (mapModified) {
                    content = content.substring(0, methodStart) + methodSub + content.substring(methodEnd);
                    System.out.println("  -> Patched " + popupFile.getFileName() + " loadMap to load local Map-UI_r38.swf with allowCodeImport");
                    modified = true;
                }
            }
        }

        if (modified) {
            Files.writeString(popupFile, content);
        }
    }

    private static void build() throws Exception {
        runCommand("rabcasm", "assets/Game-0/Game-0.main.asasm");
        runCommand("abcreplace", "assets/Game.swf", "0", "assets/Game-0/Game-0.main.abc");
        System.out.println("Build finished successfully.");
    }

    private static void runCommand(String... args) throws Exception {
        ProcessBuilder pb = new ProcessBuilder(args);
        pb.inheritIO();
        if (pb.start().waitFor() != 0) throw new RuntimeException("Command failed: " + Arrays.toString(args));
    }

    private static void patchSpiderbook() throws Exception {
        System.out.println("Downloading latest remote spiderbook3.swf...");
        Path sbSwf = Paths.get("assets/spiderbook3.swf");
        try (InputStream in = URI.create(SPIDERBOOK_URL).toURL().openStream()) {
            Files.copy(in, sbSwf, StandardCopyOption.REPLACE_EXISTING);
        }

        System.out.println("Disassembling spiderbook3.swf...");
        runCommand("abcexport", "assets/spiderbook3.swf");
        runCommand("rabcdasm", "assets/spiderbook3-0.abc");

        Path sbDir = Paths.get("assets/spiderbook3-0");
        sanitizeSecurity(sbDir);

        Path mainTimeline = sbDir.resolve("spiderbook_fla/MainTimeline.class.asasm");
        if (Files.exists(mainTimeline)) {
            System.out.println("Patching badge loader in spiderbook3 MainTimeline.class.asasm...");
            String content = Files.readString(mainTimeline).replace("\r\n", "\n");

            Pattern pattern = Pattern.compile(
                "(?s)getlex\\s+QName\\(PackageNamespace\\(\"\"\\),\\s*\"ldr\"\\)\\s+"
                + "findpropstrict\\s+QName\\(PackageNamespace\\(\"flash\\.net\"\\),\\s*\"URLRequest\"\\)\\s+"
                + "(getlex\\s+QName\\(PackageNamespace\\(\"\"\\),\\s*\"rootClass\"\\)\\s+"
                + "callproperty\\s+Multiname\\(\"getFilePath\",\\s*(\\[.*?\\])\\),\\s*0\\s+"
                + "pushstring\\s+\"news/badges/\"\\s+"
                + "add\\s+"
                + "getlex\\s+QName\\(PackageNamespace\\(\"\"\\),\\s*\"loadObj\"\\)\\s+"
                + "getproperty\\s+Multiname\\(\"sFile\",\\s*\\[.*?\\]\\)\\s+"
                + "add)\\s+"
                + "constructprop\\s+QName\\(PackageNamespace\\(\"flash\\.net\"\\),\\s*\"URLRequest\"\\),\\s*1\\s+"
                + "(getlex\\s+QName\\(PackageNamespace\\(\"\"\\),\\s*\"rootClass\"\\)\\s+"
                + "getproperty\\s+Multiname\\(\"world\",\\s*\\[.*?\\]\\)\\s+"
                + "getproperty\\s+Multiname\\(\"loaderC\",\\s*\\[.*?\\]\\))\\s+"
                + "callpropvoid\\s+Multiname\\(\"load\",\\s*\\[.*?\\]\\),\\s*2"
            );

            Matcher m = pattern.matcher(content);
            if (m.find()) {
                String ns = m.group(2);
                String replacement =
                      "getlex              QName(PackageNamespace(\"\"), \"rootClass\")\n"
                    + "      getproperty         Multiname(\"pocket\", " + ns + ")\n"
                    + "      getlex              QName(PackageNamespace(\"\"), \"ldr\")\n"
                    + "      " + m.group(1) + "\n"
                    + "      " + m.group(3) + "\n"
                    + "      callpropvoid        Multiname(\"load\", " + ns + "), 3";
                content = m.replaceFirst(Matcher.quoteReplacement(replacement));
                Files.writeString(mainTimeline, content);
                System.out.println("  -> Badge loader successfully redirected to rootClass.pocket.load");
            } else {
                System.err.println("  -> WARNING: Badge loader pattern in spiderbook3 not found!");
            }
        }

        System.out.println("Reassembling spiderbook3.swf...");
        runCommand("rabcasm", "assets/spiderbook3-0/spiderbook3-0.main.asasm");
        runCommand("abcreplace", "assets/spiderbook3.swf", "0", "assets/spiderbook3-0/spiderbook3-0.main.abc");
        System.out.println("spiderbook3.swf built and patched successfully!");
    }

    private static void patchWorldMap() throws Exception {
        System.out.println("Downloading latest remote Map-UI_r38.swf...");
        Path mapSwf = Paths.get("assets/Map-UI_r38.swf");
        try (InputStream in = URI.create(MAP_URL).toURL().openStream()) {
            Files.copy(in, mapSwf, StandardCopyOption.REPLACE_EXISTING);
        }

        System.out.println("Disassembling Map-UI_r38.swf...");
        runCommand("abcexport", "assets/Map-UI_r38.swf");
        runCommand("rabcdasm", "assets/Map-UI_r38-0.abc");

        Path mapDir = Paths.get("assets/Map-UI_r38-0");
        sanitizeSecurity(mapDir);

        Path mapUIAsasm = mapDir.resolve("mapUI.class.asasm");
        if (Files.exists(mapUIAsasm)) {
            System.out.println("Patching mapUI.class.asasm for AIR stage lifecycle...");
            String content = Files.readString(mapUIAsasm).replace("\r\n", "\n");

            // 0. Remove Font.registerFont calls from constructor to prevent ArgumentError #1508 in Adobe AIR
            String fontPattern = "(?s)getlex\\s+QName\\(PackageNamespace\\(\"flash\\.text\"\\), \"Font\"\\)\\s+"
                + "getlex\\s+QName\\(PackageNamespace\\(\"\"\\), \"(BDMerced|Arial|ArialBold)\"\\)\\s+"
                + "callpropvoid\\s+QName\\(PackageNamespace\\(\"\"\\), \"registerFont\"\\), 1\\s*";
            content = content.replaceAll(fontPattern, "");
            System.out.println("  -> mapUI constructor registerFont calls removed (fixed Error #1508)");

            // 1. Stage lifecycle in frame6 and onAddedToStage listener
            Pattern pattern = Pattern.compile(
                "(?m)(\\s*trait method QName\\(PackageInternalNs\\(\"\"\\), \"frame6\"\\)\\s+method\\s+refid \"mapUI/instance/frame6\"\\s+body\\s+maxstack )\\d+(\\s+localcount \\d+\\s+initscopedepth \\d+\\s+maxscopedepth \\d+\\s+code\\s+getlocal0\\s+pushscope\\s+)(getlocal0\\s+callpropvoid\\s+QName\\(PackageNamespace\\(\"\"\\), \"init\"\\), 0)"
            );

            Matcher m = pattern.matcher(content);
            if (m.find()) {
                String replacement = m.group(1) + "3" + m.group(2)
                    + "getlex              QName(PackageNamespace(\"\"), \"stage\")\n"
                    + "       pushnull\n"
                    + "       ifeq                L8\n\n"
                    + "       getlocal0\n"
                    + "       callpropvoid        QName(PackageNamespace(\"\"), \"init\"), 0\n\n"
                    + "       jump                L14\n\n"
                    + "L8:\n"
                    + "       getlocal0\n"
                    + "       getlex              QName(PackageNamespace(\"flash.events\"), \"Event\")\n"
                    + "       getproperty         QName(PackageNamespace(\"\"), \"ADDED_TO_STAGE\")\n"
                    + "       getlocal0\n"
                    + "       getproperty         QName(PackageInternalNs(\"\"), \"onAddedToStage\")\n"
                    + "       callpropvoid        QName(PackageNamespace(\"\"), \"addEventListener\"), 2\n\n"
                    + "L14:";
                content = m.replaceFirst(Matcher.quoteReplacement(replacement));

                String traitOnAdded = "   trait method QName(PackageInternalNs(\"\"), \"onAddedToStage\")\n"
                    + "    method\n"
                    + "     refid \"mapUI/instance/onAddedToStage\"\n"
                    + "     param QName(PackageNamespace(\"flash.events\"), \"Event\")\n"
                    + "     returns QName(PackageNamespace(\"\"), \"void\")\n"
                    + "     body\n"
                    + "      maxstack 3\n"
                    + "      localcount 2\n"
                    + "      initscopedepth 10\n"
                    + "      maxscopedepth 11\n"
                    + "      code\n"
                    + "       getlocal0\n"
                    + "       pushscope\n\n"
                    + "       getlocal0\n"
                    + "       getlex              QName(PackageNamespace(\"flash.events\"), \"Event\")\n"
                    + "       getproperty         QName(PackageNamespace(\"\"), \"ADDED_TO_STAGE\")\n"
                    + "       getlocal0\n"
                    + "       getproperty         QName(PackageInternalNs(\"\"), \"onAddedToStage\")\n"
                    + "       callpropvoid        QName(PackageNamespace(\"\"), \"removeEventListener\"), 2\n\n"
                    + "       getlocal0\n"
                    + "       callpropvoid        QName(PackageNamespace(\"\"), \"init\"), 0\n\n"
                    + "       returnvoid\n"
                    + "      end ; code\n"
                    + "     end ; body\n"
                    + "    end ; method\n"
                    + "   end ; trait\n";

                Pattern pEndInst = Pattern.compile("(?m)^\\s*end ; instance");
                Matcher mEndInst = pEndInst.matcher(content);
                if (mEndInst.find()) {
                    content = content.substring(0, mEndInst.start()) + traitOnAdded + mEndInst.group() + content.substring(mEndInst.end());
                    System.out.println("  -> mapUI.class.asasm patched with ADDED_TO_STAGE listener (onAddedToStage inserted)");
                } else {
                    System.err.println("  -> WARNING: end ; instance not found in mapUI.class.asasm!");
                }
            } else {
                System.err.println("  -> WARNING: frame6 pattern in mapUI.class.asasm not found!");
            }



            // 3. Silence debug trace statements that pollute the console
            // 3a. In getIconClass: trace(strIcon + " - Icon to get")
            content = content.replaceAll("(?s)findpropstrict\\s+QName\\(PackageNamespace\\(\"\"\\), \"trace\"\\)\\s+getscopeobject\\s+1\\s+getslot\\s+1\\s+pushstring\\s+\" - Icon to get\"\\s+add\\s+callpropvoid\\s+QName\\(PackageNamespace\\(\"\"\\), \"trace\"\\), 1", "");

            // 3b. In getIconClass: catch trace "Definition not found on map"
            content = content.replaceAll("(?s)findpropstrict\\s+QName\\(PackageNamespace\\(\"\"\\), \"trace\"\\)\\s+pushstring\\s+\"Definition not found on map\"\\s+callpropvoid\\s+QName\\(PackageNamespace\\(\"\"\\), \"trace\"\\), 1", "");

            // 3c. In getIconClass: catch trace "Definition not found on Icon loaded app domain"
            content = content.replaceAll("(?s)findpropstrict\\s+QName\\(PackageNamespace\\(\"\"\\), \"trace\"\\)\\s+pushstring\\s+\"Definition not found on Icon loaded app domain\"\\s+callpropvoid\\s+QName\\(PackageNamespace\\(\"\"\\), \"trace\"\\), 1", "");

            // 3d. In getIconClass: catch trace "Definition not found on loaded app domain"
            content = content.replaceAll("(?s)findpropstrict\\s+QName\\(PackageNamespace\\(\"\"\\), \"trace\"\\)\\s+pushstring\\s+\"Definition not found on loaded app domain\"\\s+callpropvoid\\s+QName\\(PackageNamespace\\(\"\"\\), \"trace\"\\), 1", "");

            // 3e. In setStories: trace(index + ":" + selInd + "-" + strTitle + "-----")
            content = content.replaceAll("(?s)findpropstrict\\s+QName\\(PackageNamespace\\(\"\"\\), \"trace\"\\)\\s+getlocal\\s+6\\s+pushstring\\s+\":\".*?pushstring\\s+\"-----\"\\s+add\\s+callpropvoid\\s+QName\\(PackageNamespace\\(\"\"\\), \"trace\"\\), 1", "");

            // 3f. In setStories: trace("Couldn't find the area! - " + index)
            content = content.replaceAll("(?s)findpropstrict\\s+QName\\(PackageNamespace\\(\"\"\\), \"trace\"\\)\\s+pushstring\\s+\"Couldn't find the area! - \"\\s+getlocal\\s+6\\s+add\\s+callpropvoid\\s+QName\\(PackageNamespace\\(\"\"\\), \"trace\"\\), 1", "");

            System.out.println("  -> mapUI.class.asasm debug traces silenced");
            Files.writeString(mapUIAsasm, content);
        }

        System.out.println("Reassembling Map-UI_r38.swf...");
        runCommand("rabcasm", "assets/Map-UI_r38-0/Map-UI_r38-0.main.asasm");
        runCommand("abcreplace", "assets/Map-UI_r38.swf", "0", "assets/Map-UI_r38-0/Map-UI_r38-0.main.abc");
        System.out.println("Map-UI_r38.swf built and patched successfully!");
    }

    private static void patchCharSelect() throws Exception {
        System.out.println("Downloading latest remote charselect.swf...");
        Path csSwf = Paths.get("assets/charselect.swf");
        try (InputStream in = URI.create(CHARSELECT_URL).toURL().openStream()) {
            Files.copy(in, csSwf, StandardCopyOption.REPLACE_EXISTING);
        }

        System.out.println("Disassembling charselect.swf...");
        runCommand("abcexport", "assets/charselect.swf");
        runCommand("rabcdasm", "assets/charselect-0.abc");

        Path csDir = Paths.get("assets/charselect-0");
        sanitizeSecurity(csDir);

        // 1. In main.class.asasm: replace stage.getChildAt(0) with parent (fixes Error #2193)
        // and replace any getlex parent with getlocal0 / getproperty parent
        Path mainAsasm = csDir.resolve("main.class.asasm");
        if (Files.exists(mainAsasm)) {
            System.out.println("Patching root reference in main.class.asasm...");
            String content = Files.readString(mainAsasm).replace("\r\n", "\n");
            Pattern pStage = Pattern.compile("(?s)getlex\\s+QName\\(PackageNamespace\\(\"\"\\),\\s*\"stage\"\\)\\s+pushbyte\\s+0\\s+callproperty\\s+QName\\(PackageNamespace\\(\"\"\\),\\s*\"getChildAt\"\\),\\s*1");
            String replParent = "getlocal0\n      getproperty         QName(PackageNamespace(\"\"), \"parent\")";
            content = pStage.matcher(content).replaceAll(replParent);
            content = content.replace("getlex              QName(PackageNamespace(\"\"), \"parent\")", replParent);
            Files.writeString(mainAsasm, content);
            System.out.println("  -> main.class.asasm root patched to parent (fixed Error #2193)");
        }

        // 2. In manager.class.asasm & main.class.asasm: replace SharedObject.getLocal("AQWChars", "/", true)
        // with SharedObject.getLocal("AQWChars") to fix Error #2134 in Adobe AIR
        Pattern pSO = Pattern.compile("(?s)pushstring\\s+\"AQWChars\"\\s+pushstring\\s+\"/\"\\s+pushtrue\\s+callproperty\\s+QName\\(PackageNamespace\\(\"\"\\),\\s*\"getLocal\"\\),\\s*3");
        String replSO = "pushstring          \"AQWChars\"\n      callproperty        QName(PackageNamespace(\"\"), \"getLocal\"), 1";
        for (String fileToPatch : List.of("manager.class.asasm", "main.class.asasm")) {
            Path p = csDir.resolve(fileToPatch);
            if (Files.exists(p)) {
                String content = Files.readString(p).replace("\r\n", "\n");
                Matcher mSO = pSO.matcher(content);
                if (mSO.find()) {
                    content = mSO.replaceAll(replSO);
                    Files.writeString(p, content);
                    System.out.println("  -> " + fileToPatch + " SharedObject.getLocal patched (fixed Error #2134)");
                } else {
                    System.err.println("  -> WARNING: target SharedObject pattern not found in " + fileToPatch + "!");
                }
            }
        }

        // 3. In manager.class.asasm:
        // a. Initialize characters.data.users = {} if null/undefined
        // b. Guard displayAvts[0].loginInfo.bAsk check so Error #1010 doesn't occur when displayAvts is empty
        Path mgrAsasm = csDir.resolve("manager.class.asasm");
        if (Files.exists(mgrAsasm)) {
            System.out.println("Patching manager.class.asasm for empty character list...");
            String content = Files.readString(mgrAsasm).replace("\r\n", "\n");

            // a. Initialize characters.data.users if null
            Pattern pInitSO = Pattern.compile("(?s)(initproperty\\s+QName\\(PrivateNamespace\\(null,\\s*\"manager/instance#0\"\\),\\s*\"characters\"\\))");
            Matcher mInitSO = pInitSO.matcher(content);
            if (mInitSO.find()) {
                String matched = mInitSO.group(1);
                String replInitSO = matched + "\n\n"
                    + "      getlex              QName(PrivateNamespace(null, \"manager/instance#0\"), \"characters\")\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"data\")\n"
                    + "      getproperty         Multiname(\"users\", [PrivateNamespace(null, \"manager/instance#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"manager/instance#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"manager\"), StaticProtectedNs(\"manager\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                    + "      pushnull\n"
                    + "      ifne                L_HAS_USERS\n"
                    + "      getlex              QName(PrivateNamespace(null, \"manager/instance#0\"), \"characters\")\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"data\")\n"
                    + "      findpropstrict      QName(PackageNamespace(\"\"), \"Object\")\n"
                    + "      constructprop       QName(PackageNamespace(\"\"), \"Object\"), 0\n"
                    + "      setproperty         Multiname(\"users\", [PrivateNamespace(null, \"manager/instance#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"manager/instance#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"manager\"), StaticProtectedNs(\"manager\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                    + "L_HAS_USERS:";
                content = mInitSO.replaceFirst(Matcher.quoteReplacement(replInitSO));
                System.out.println("  -> manager.class.asasm characters.data.users initialization patched");
            }

            // b. Guard displayAvts[0].loginInfo.bAsk check
            Pattern pCharOpt = Pattern.compile("(?s)getlex\\s+QName\\(PackageNamespace\\(\"\"\\),\\s*\"displayAvts\"\\)\\s+pushbyte\\s+0\\s+getproperty\\s+MultinameL\\([^\\]]+\\]\\)\\s+getproperty\\s+Multiname\\(\"loginInfo\", [^\\]]+\\]\\)\\s+getproperty\\s+Multiname\\(\"bAsk\", [^\\]]+\\]\\)\\s+getlex\\s+QName\\(PackageNamespace\\(\"\"\\),\\s*\"Boolean\"\\)\\s+astypelate");
            Matcher mCharOpt = pCharOpt.matcher(content);
            if (mCharOpt.find()) {
                String replCharOpt =
                      "getlex              QName(PackageNamespace(\"\"), \"displayAvts\")\n"
                    + "      getproperty         QName(PackageNamespace(\"\"), \"length\")\n"
                    + "      pushbyte            0\n"
                    + "      ifngt               L_EMPTY_AVTS\n"
                    + "      getlex              QName(PackageNamespace(\"\"), \"displayAvts\")\n"
                    + "      pushbyte            0\n"
                    + "      getproperty         MultinameL([PrivateNamespace(null, \"manager/instance#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"manager/instance#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"manager\"), StaticProtectedNs(\"manager\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                    + "      getproperty         Multiname(\"loginInfo\", [PrivateNamespace(null, \"manager/instance#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"manager/instance#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"manager\"), StaticProtectedNs(\"manager\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                    + "      getproperty         Multiname(\"bAsk\", [PrivateNamespace(null, \"manager/instance#0\"), PackageNamespace(\"\"), PrivateNamespace(null, \"manager/instance#1\"), PackageInternalNs(\"\"), Namespace(\"http://adobe.com/AS3/2006/builtin\"), ProtectedNamespace(\"manager\"), StaticProtectedNs(\"manager\"), StaticProtectedNs(\"flash.display:MovieClip\"), StaticProtectedNs(\"flash.display:Sprite\"), StaticProtectedNs(\"flash.display:DisplayObjectContainer\"), StaticProtectedNs(\"flash.display:InteractiveObject\"), StaticProtectedNs(\"flash.display:DisplayObject\"), StaticProtectedNs(\"flash.events:EventDispatcher\")])\n"
                    + "      getlex              QName(PackageNamespace(\"\"), \"Boolean\")\n"
                    + "      astypelate\n"
                    + "      jump                L_INIT_AVTS\n"
                    + "L_EMPTY_AVTS:\n"
                    + "      pushfalse\n"
                    + "L_INIT_AVTS:";
                content = mCharOpt.replaceFirst(Matcher.quoteReplacement(replCharOpt));
                System.out.println("  -> manager.class.asasm displayAvts empty guard patched (fixed Error #1010)");
            } else {
                System.err.println("  -> WARNING: displayAvts[0].loginInfo pattern not found in manager.class.asasm!");
            }
            Files.writeString(mgrAsasm, content);
        }

        // 4. In selAvatarMC.class.asasm: add allowCodeImport = true to all LoaderContext instances
        Path selAvAsasm = csDir.resolve("selAvatarMC.class.asasm");
        if (Files.exists(selAvAsasm)) {
            System.out.println("Patching LoaderContext in selAvatarMC.class.asasm...");
            String content = Files.readString(selAvAsasm).replace("\r\n", "\n");
            String targetLC = "constructprop       QName(PackageNamespace(\"flash.system\"), \"LoaderContext\"), 2";
            String replLC = targetLC + "\n      dup\n      pushtrue\n      setproperty         QName(PackageNamespace(\"\"), \"allowCodeImport\")";
            if (content.contains(targetLC)) {
                content = content.replace(targetLC, replLC);
                Files.writeString(selAvAsasm, content);
                System.out.println("  -> selAvatarMC.class.asasm LoaderContext allowCodeImport patched");
            } else {
                System.err.println("  -> WARNING: LoaderContext pattern not found in selAvatarMC.class.asasm!");
            }
        }

        System.out.println("Reassembling charselect.swf...");
        runCommand("rabcasm", "assets/charselect-0/charselect-0.main.asasm");
        runCommand("abcreplace", "assets/charselect.swf", "0", "assets/charselect-0/charselect-0.main.abc");
        System.out.println("charselect.swf built and patched successfully!");

        Path loaderGamefiles = Paths.get("loader/gamefiles");
        if (Files.exists(loaderGamefiles)) {
            Files.copy(csSwf, loaderGamefiles.resolve("charselect.swf"), StandardCopyOption.REPLACE_EXISTING);
            System.out.println("  -> Copied charselect.swf to loader/gamefiles/charselect.swf");
        }
    }
}