#!/usr/bin/env python3
"""
Builds the CDN upload tree and the versioned pack index (packs.json) for the Flutter app.

    python3 cloudflare/scripts/build_packs.py --version v1 \
        [--voice-dir path/to/recorded/voice] [--art-dir path/to/final/webp/art]

Output: cloudflare/dist/popo/<version>/...
  packs.json                 index read by lib/core/assets/download_manager.dart
                             (id, title, version, minApp, size + sha256 per file)
  audio/voice/*.mp3          recorded narrator lines            -> pack "voice-fa"
  art/<group>/<id>.webp      finished raster illustrations      -> one pack per world
  audio/animals|sfx|ambient  higher-quality sound replacements  -> pack "sounds-hq"
  audio/music/*.mp3          background music                   -> pack "music"

Paths are the app's logical asset paths, so a downloaded file overrides the bundled one with no
code change (lib/core/assets/asset_resolver.dart; a .webp beside an .svg id wins). Everything is
optional: the app ships with vector art, synthesised effects and Commons recordings, and works
offline without any pack.

--art-dir expects files named like the art ids (cow.webp, sofa.webp…), in any sub-folder; the
group comes from assets/content/asset_manifest.json.
"""
import argparse
import hashlib
import json
import os
import shutil

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.dirname(os.path.dirname(HERE))
ASSETS = os.path.join(APP, "assets")
MIN_APP = 1

ART_PACKS = {
    "home": ("art-home", "تصویرهای خانه", "اتاق‌ها، وسایل و اسباب‌بازی‌ها", "home"),
    "city": ("art-city", "تصویرهای شهر", "ماشین‌ها، خانه‌ها و پارک", "city"),
    "animals": ("art-animals", "تصویر حیوان‌ها", "حیوان‌های جنگل، برکه و مزرعه", "nature"),
    "nature": ("art-nature", "تصویرهای طبیعت", "درخت‌ها، گل‌ها و آسمان", "nature"),
    "music": ("art-studios", "تصویرهای استودیو", "سازها، نقاشی و ساخت‌وساز", None),
    "art": ("art-studios", "تصویرهای استودیو", "سازها، نقاشی و ساخت‌وساز", None),
    "construction": ("art-studios", "تصویرهای استودیو", "سازها، نقاشی و ساخت‌وساز", None),
}


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", default="v1")
    ap.add_argument("--voice-dir", help="recorded narrator mp3s (default: assets/audio/voice)")
    ap.add_argument("--art-dir", help="finished .webp illustrations named by art id")
    args = ap.parse_args()

    root = os.path.join(APP, "cloudflare", "dist", "popo", args.version)
    if os.path.isdir(root):
        shutil.rmtree(root)
    os.makedirs(root)

    packs = {}

    def add(pack_id, title, desc, world, src, logical):
        dst = os.path.join(root, logical)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copyfile(src, dst)
        p = packs.setdefault(pack_id, {"id": pack_id, "title": title, "description": desc, "version": 1, "minApp": MIN_APP, "files": []})
        if world:
            p["world"] = world
        p["files"].append({"path": logical, "size": os.path.getsize(src), "sha256": sha256(src)})

    voice_dir = args.voice_dir or os.path.join(ASSETS, "audio/voice")
    for n in sorted(os.listdir(voice_dir)) if os.path.isdir(voice_dir) else []:
        if n.lower().endswith(".mp3"):
            add("voice-fa", "صدای پوپو", "جمله‌های ضبط‌شده‌ی گوینده", None, os.path.join(voice_dir, n), f"audio/voice/{n}")

    for sub in ("animals", "sfx", "ambient"):
        d = os.path.join(ASSETS, "audio", sub)
        for n in sorted(os.listdir(d)) if os.path.isdir(d) else []:
            if n.endswith(".mp3"):
                add("sounds-hq", "صداهای باکیفیت", "صدای حیوان‌ها، وسایل و طبیعت", None, os.path.join(d, n), f"audio/{sub}/{n}")

    d = os.path.join(ASSETS, "audio", "music")
    for n in sorted(os.listdir(d)) if os.path.isdir(d) else []:
        if n.endswith(".mp3"):
            add("music", "موسیقی", "موسیقی پس‌زمینه", None, os.path.join(d, n), f"audio/music/{n}")

    if args.art_dir:
        manifest = json.load(open(os.path.join(ASSETS, "content/asset_manifest.json"), encoding="utf-8"))
        groups = {a["id"]: a["group"] for a in manifest["assets"] if a["path"].startswith("art/")}
        for dirpath, _, names in os.walk(args.art_dir):
            for n in sorted(names):
                stem, ext = os.path.splitext(n)
                if ext.lower() not in (".webp", ".png"):
                    continue
                group = groups.get(stem)
                if group is None:
                    print(f"! {n}: no art id «{stem}» in asset_manifest.json — skipped")
                    continue
                pid, title, desc, world = ART_PACKS[group]
                add(pid, title, desc, world, os.path.join(dirpath, n), f"art/{group}/{stem}{ext.lower()}")

    index = {"version": args.version, "packs": list(packs.values())}
    with open(os.path.join(root, "packs.json"), "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=1)
    for p in index["packs"]:
        print("%-12s %4d files %8d KB" % (p["id"], len(p["files"]), sum(x["size"] for x in p["files"]) // 1024))
    print("wrote", os.path.relpath(root, APP))


if __name__ == "__main__":
    main()
