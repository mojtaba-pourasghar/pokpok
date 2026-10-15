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
    "living": "a cozy empty living room seen from the front, peach wallpaper, a big window in the middle of the wall, wooden floor filling the bottom 40 percent of the image, no furniture",
    "kitchen": "a bright empty kitchen seen from the front, mint tiled wall with upper cabinets and a window, warm orange checkered tile floor filling the bottom 40 percent, no table",
    "bedroom": "a cozy empty child's bedroom seen from the front, lavender wall with little star decals, a round window, soft purple carpet floor filling the bottom 40 percent, no bed",
    "bathroom": "a clean empty bathroom seen from the front, light blue tiled wall, small round mirror, light blue tile floor filling the bottom 40 percent, no bathtub",
    "playroom": "a cheerful empty playroom seen from the front, yellow striped wall, a window, pink carpet floor filling the bottom 40 percent",
    "shop": "the inside of a small friendly grocery shop seen from the front, light green wall with shelves of colorful goods in the upper half, wooden floor filling the bottom 40 percent",
    "studio": "an empty bright art studio seen from the front, pink wall with framed children's paintings, wooden floor filling the bottom 40 percent",
    "music": "a small colorful music stage seen from the front, purple backdrop with pink curtains on both sides and soft spotlights, empty stage floor in the bottom 40 percent",
    "street": "a sunny toy-like city seen from the front, a row of colorful houses and shops along the horizon in the middle, wide green grass in the bottom half with no road",
    "park": "a sunny park seen from the front, green trees along the horizon in the middle, wide open lawn in the bottom half with a winding sandy path",
    "forest": "a friendly sunny forest clearing seen from the front, rounded trees along the horizon in the middle, wide open grassy clearing in the bottom half",
    "garden": "a sunny vegetable garden seen from the front, white picket fence across the middle, two long rows of brown soil in the bottom half",
    "pond": "a sunny pond seen from the front, trees along the horizon, a wide oval blue pond in the lower middle surrounded by grass",
    "farm": "a sunny farm meadow seen from the front, rolling green hills and a wooden fence across the middle, wide open grass in the bottom half, no barn",
    "workshop": "a sunny construction yard seen from the front, colorful toy city skyline far away, flat sandy ground with a faint grid filling the bottom half",
    "map": "a top-down view of a small round cartoon island in a turquoise sea, green grass, a winding river, little round trees, sandy beaches, empty clearings for six places",
    "splash": "a magical sunny meadow at the edge of a friendly forest, flowers in the grass, soft clouds, wide open space in the middle",
    "meadow": "a sunny flower meadow with soft rolling hills and a few round trees far away, open grass in the bottom half",
}

CARDS = {
    "card_home": "a cute cozy little house with a red roof and warm lights",
    "card_city": "a tiny cheerful toy city street with colorful houses and a yellow bus",
    "card_nature": "a sunny green meadow with a cow, a duck and a tree",
    "card_art": "an artist's palette, paint brushes and colorful paint splashes on an easel",
    "card_music": "a toy piano keyboard, a little drum and colorful music notes",
    "card_build": "colorful toy building blocks, a small yellow toy crane and gears",
}

OBJECTS = {
    # animals
    "cow": "a cute cartoon cow, white with black spots", "sheep": "a fluffy cute cartoon sheep",
    "chick": "a tiny fluffy yellow chick", "hen": "a cute white hen with a red comb",
    "rabbit": "a cute white bunny with pink ears", "duck": "a cute yellow duck floating",
    "frog": "a cute green frog smiling", "bird": "a cute small blue bird",
    "butterfly": "a cute purple and pink butterfly", "bee": "a cute round bumblebee",
    "fish": "a cute orange goldfish", "dog": "a cute light brown puppy sitting",
    "cat": "a cute orange kitten sitting", "horse": "a cute brown pony with a dark mane",
    # nature
    "tree": "a round green apple tree with red apples", "pine": "a cute green pine tree",
    "bush": "a round green bush with tiny flowers", "flower_red": "a single red flower with a smiling yellow center",
    "flower_yellow": "a single yellow flower with a smiling orange center", "flower_purple": "a single purple flower with a smiling yellow center",
    "sprout": "a small green sprout with two leaves in a mound of soil", "seed": "a single brown seed on a small mound of soil",
    "mushroom": "a cute red mushroom with white dots", "sun": "a cute smiling sun", "cloud": "a fluffy white cloud",
    "watering_can": "a turquoise toy watering can", "carrot": "an orange carrot with green leaves",
    "pond": "a small round blue pond", "lily": "a green lily pad with a pink flower", "rock": "a smooth grey rock",
    "hay": "a round yellow hay bale", "barn": "a small red toy barn",
    # home
    "sofa": "a cute purple sofa", "armchair": "a turquoise armchair", "lamp": "a yellow floor lamp",
    "table": "a small wooden table", "tv": "a cute flat screen television on a stand", "plant": "a green plant in an orange pot",
    "bookshelf": "a wooden bookshelf with colorful books", "rug": "a round pink rug seen from above at an angle",
    "bed": "a small child's bed with a blue blanket", "teddy": "a pink plush bunny toy", "ball": "a red and yellow beach ball",
    "toy_blocks": "three toy letter blocks stacked", "fridge": "a cute white refrigerator", "stove": "a white kitchen stove with an oven",
    "pot": "a red cooking pot", "pan": "a black frying pan", "plate": "a white plate", "cup": "a turquoise mug",
    "bathtub": "a white bathtub full of bubbles", "rubber_duck": "a yellow rubber duck toy", "towel": "a folded turquoise towel",
    "soap": "a pink soap bar with bubbles", "toothbrush": "a blue toothbrush", "apple": "a shiny red apple",
    "banana": "a yellow banana", "bread": "a loaf of bread", "milk": "a carton of milk", "cheese": "a wedge of yellow cheese",
    "basket": "a wicker shopping basket", "bowl": "a blue pet food bowl with kibble", "window": "a window with blue sky",
    "clock": "an orange round wall clock",
    # city
    "car": "a cute red toy car seen from the side", "bus": "a cute yellow toy bus seen from the side",
    "truck": "a cute blue and orange toy truck seen from the side", "taxi": "a cute yellow toy taxi seen from the side",
    "bicycle": "a red child's bicycle seen from the side", "house": "a cute small house with a red roof",
    "house_blue": "a cute small blue house", "shop": "a cute small shop with a green striped awning",
    "traffic_light": "a cute traffic light", "fountain": "a small stone fountain with water", "bench": "a wooden park bench",
    "bus_stop": "a blue bus stop sign",
    # music, art, construction
    "guitar": "a small acoustic guitar", "drum": "a red toy drum with sticks", "trumpet": "a golden toy trumpet",
    "note": "a purple music note", "palette": "an artist's paint palette with colorful paints", "brush": "a paint brush with red paint",
    "gear": "an orange toy gear", "crane": "a yellow toy crane", "wheel": "a toy wheel", "cone": "an orange traffic cone",
    "bridge": "a blue toy bridge", "road_piece": "a straight piece of toy road", "flag": "a red flag on a pole",
}

GROUPS = json.loads((ROOT / "assets/content/asset_manifest.json").read_text(encoding="utf-8"))


def main():
    groups = {a["id"]: a["group"] for a in GROUPS["assets"] if a["path"].startswith("art/") and a["path"].endswith(".svg")}
    items = []
    for pid, pose in POSES.items():
        items.append({"id": pid, "kind": "character", "target": f"assets/art/character/{pid}.webp", "size": 768,
                      "prompt": f"{POPO}, {pose}, full body. {STYLE_OBJECT}"})
    for sid, desc in SCENES.items():
        items.append({"id": f"bg_{sid}", "kind": "background", "target": f"assets/art/backgrounds/{sid}.webp", "size": 1024,
                      "prompt": f"{desc}. {STYLE_SCENE}"})
    for cid, desc in CARDS.items():
        items.append({"id": cid, "kind": "card", "target": f"assets/art/cards/{cid}.webp", "size": 768,
                      "prompt": f"{desc}. {STYLE_CARD}"})
    missing = sorted(set(groups) - set(OBJECTS))
    if missing:
        raise SystemExit(f"no prompt for: {missing}")
    for oid, desc in OBJECTS.items():
        items.append({"id": oid, "kind": "object", "target": f"assets/art/{groups[oid]}/{oid}.webp", "size": 512,
                      "prompt": f"{desc}. {STYLE_OBJECT}"})
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({
        "model": "@cf/black-forest-labs/flux-1-schnell",
        "note": "Generated by tools/art/prompts.py. Images are made by tools/art/generate_cf.py (Cloudflare Workers AI).",
        "items": items,
    }, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"{len(items)} prompts → {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
