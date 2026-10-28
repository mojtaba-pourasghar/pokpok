#!/usr/bin/env python3
"""Writes art/art_manifest.json: one prompt per image the app can show, all in one style.

Every prompt = subject + the shared style guide, so the whole game looks like one set
(the same recipe goshyar_game uses for its Cloudflare-generated art). Edit the subjects here,
run this script, then tools/art/generate_cf.py makes the images.

    python3 tools/art/prompts.py
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art/art_manifest.json"

STYLE_OBJECT = ("Soft glossy Pixar-style 3D render, rounded soft shapes, bright saturated colors, cute children's game asset, "
                "single object, full view, centered, isolated on a plain pure white background, soft contact shadow, "
                "no text, no letters, no watermark")
STYLE_SCENE = ("Soft glossy Pixar-style 3D render, warm cheerful lighting, bright saturated pastel colors, rounded shapes, "
               "children's game background, wide view, empty and uncluttered so toys can be placed on it, "
               "no characters, no people, no animals, no text, no letters, no watermark")
STYLE_CARD = ("Soft glossy Pixar-style 3D render, bright saturated colors, rounded shapes, children's game menu card illustration, "
              "centered composition, no text, no letters, no watermark")

POPO = ("Cute 3D rendered cartoon little girl fox cub named Popo, bright orange fur, white cheeks and muzzle and white tail tip, "
        "big round dark eyes with long eyelashes, pointy ears with brown tips, a big pink bow on her head, "
        "a lavender purple dress with white round collar, small white polka dots and a yellow flower, white socks and pink shoes, "
        "fluffy tail")
POSES = {
    "popo_welcome": "waving hello with one paw raised, big happy smile",
    "popo_curious": "head tilted, looking curiously, one eyebrow raised, small smile",
    "popo_thinking": "thinking, one paw under her chin, eyes looking up",
    "popo_happy": "jumping with joy, both arms raised high, eyes closed in a big laugh",
    "popo_surprised": "surprised, mouth in a small o, eyes wide, arms out",
    "popo_sleepy": "sleepy, eyes closed, yawning with a paw over her mouth",
    "popo_pointing": "pointing to the side with one paw, friendly smile",
    "popo_idle": "standing calmly, arms relaxed at her sides, gentle smile, facing forward",
}

# Background id → layout-aware description (rooms: floor fills the bottom 40%; outdoors: horizon at the middle).
SCENES = {
    "kitchen": "a bright cozy cartoon kitchen seen from the front, mint tiled wall with wooden shelves of jars, a window with sunshine, warm wooden floor filling the bottom 40 percent, empty counter in the middle",
    "farm": "a sunny farm garden seen from the front, red barn far away on the left, a white fence across the middle, green grass and rows of soil in the bottom half",
    "workshop": "a cozy wooden carpenter workshop inside a big tree, tool wall with pegboard, warm lamps, wooden workbench floor filling the bottom 40 percent",
    "studio": "a bright colorful art studio seen from the front, pink wall with children's paintings, paint splashes, easels on the sides, wooden floor filling the bottom 40 percent",
    "night_forest": "a friendly magical forest at night seen from the front, big round trees, a big moon, soft blue and purple light, glowing mushrooms, open clearing in the bottom half, cozy not scary",
    "stage": "a small colorful outdoor music stage in a forest seen from the front, purple curtains, warm spotlights, wooden stage floor in the bottom 40 percent",
    "city": "a sunny toy-like small city seen from the front, colorful houses along the horizon, a river with a broken wooden bridge in the middle, street in the bottom part",
    "festival": "a festive forest square seen from the front, strings of lights and bunting between trees, a long empty table on the left, open space in the middle, warm sunset light",
    "playroom": "a cozy empty child's playroom seen from the front, light purple wall with wooden shelves, a big window with sky, soft carpet floor filling the bottom 40 percent",
    "star_workshop": "a magical wooden workshop room with star decorations and glowing crates on shelves, warm light, wooden floor in the bottom 40 percent",
    "shop": "a cute little tool shop counter seen from the front, wooden shelves with toy tools, warm light, wooden floor filling the bottom 40 percent",
    "meadow": "a sunny flower meadow with soft rolling green hills, blue sky with fluffy clouds, a few round trees far away, open grass in the bottom half",
}

GAME = json.loads((ROOT / "art/game_art.json").read_text(encoding="utf-8"))

# Which pictures are made first (the daily Cloudflare allowance is limited): characters and
# chapter 1–3 first, then the rest.
# White things vanish when a white backdrop is cut away: these render on sky blue, which is keyed out.
ON_BLUE = {"milk", "fridge", "glass", "flour", "q_rain", "egg", "sheep"}

FIRST = ["kitchen", "farm", "workshop", "meadow"]



def main():
    items = []
    for pid, pose in POSES.items():
        items.append({"id": pid, "kind": "character", "target": f"assets/art/character/{pid}.webp", "size": 768,
                      "prompt": f"{POPO}, {pose}, full body. {STYLE_OBJECT}"})
    for fid, desc in GAME["friends"].items():
        items.append({"id": f"friend_{fid}", "kind": "character", "target": f"assets/art/characters/{fid}.webp", "size": 768,
                      "prompt": f"Cute 3D rendered cartoon {desc}, friendly smile, waving, full body. {STYLE_OBJECT}"})
    scenes = sorted(SCENES, key=lambda s: (s not in FIRST, s))
    for sid in scenes:
        items.append({"id": f"bg_{sid}", "kind": "background", "target": f"assets/art/backgrounds/{sid}.webp", "size": 1024,
                      "prompt": f"{SCENES[sid]}. {STYLE_SCENE}"})
    for oid, desc in GAME["objects"].items():
        item = {"id": oid, "kind": "object", "target": f"assets/art/items/{oid}.webp", "size": 512,
                "prompt": f"{desc}. {STYLE_OBJECT}"}
        if oid in ON_BLUE:
            item["prompt"] = item["prompt"].replace("plain pure white background", "plain solid sky blue background")
            item["key"] = "blue"
        items.append(item)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({
        "model": "@cf/black-forest-labs/flux-1-schnell",
        "note": "Generated by tools/art/prompts.py from art/game_art.json (tools/content/build_game.py). "
                "Images are made by tools/art/generate_cf.py (Cloudflare Workers AI).",
        "items": items,
    }, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"{len(items)} prompts → {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
