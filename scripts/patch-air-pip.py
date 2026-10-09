#!/usr/bin/env python3
import sys, os, glob, zipfile, shutil

def patch_adt(sdk_dir):
    jars = []
    if sdk_dir and os.path.isfile(sdk_dir) and sdk_dir.endswith("adt.jar"):
        jars.append(sdk_dir)
    elif sdk_dir and os.path.isdir(sdk_dir):
        jars.extend(glob.glob(os.path.join(sdk_dir, "lib", "adt.jar")))
        jars.extend(glob.glob(os.path.join(sdk_dir, "**/adt.jar"), recursive=True))

    if not jars:
        home = os.path.expanduser("~")
        jars.extend(glob.glob(os.path.join(home, "AIRSDK*", "lib", "adt.jar")))
        jars.extend(glob.glob("/opt/**/adt.jar", recursive=True))
        jars.extend(glob.glob("/home/**/adt.jar", recursive=True))

    jars = list(set(jars))
    if not jars:
        print("[patch-air-pip] No adt.jar found to patch.")
        return

    for jar_path in jars:
        print(f"[patch-air-pip] Inspecting {jar_path} for Picture-in-Picture support...")
        tmp_jar = jar_path + ".tmp"
        patched_count = 0
        with zipfile.ZipFile(jar_path, "r") as zin:
            with zipfile.ZipFile(tmp_jar, "w") as zout:
                for item in zin.infolist():
                    data = zin.read(item.filename)
                    if "AndroidManifest_template" in item.filename:
                        try:
                            text = data.decode("utf-8")
                            if "android:supportsPictureInPicture" not in text:
                                text = text.replace("<activity ", '<activity android:supportsPictureInPicture="true" ')
                                data = text.encode("utf-8")
                                patched_count += 1
                        except Exception:
                            pass
                    zout.writestr(item, data)
        shutil.move(tmp_jar, jar_path)
        print(f"[patch-air-pip] Successfully ensured PiP in {jar_path} (updated {patched_count} templates).")

if __name__ == "__main__":
    sdk_arg = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("AIR_SDK_PATH", "")
    patch_adt(sdk_arg)
