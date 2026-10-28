#!/usr/bin/env python3
"""The whole POPO story in one place: chapters, sections, the things the child makes, kits, shop
tools, play-room combos and orders. Writes

    assets/content/game.json         what the app plays
    assets/content/voice_lines.json  every line Popo says (the studio reads this; recorded files stay)
    art/game_art.json                one image prompt per picture (tools/art/prompts.py merges it)

    python3 tools/content/build_game.py

Each mini-game step is one of the engines in lib/game/engines/ (see ENGINES below). A section is
mission → steps → discover (sound, taste, use) → quiz → free play → backpack.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

ENGINES = {
    "collect", "sort", "cut", "tap", "rotate", "pour", "timing", "assemble", "order", "count",
    "paint", "mix", "scrub", "dark", "trace", "rhythm", "puzzle", "use", "serve",
}

# ── pictures: id → (emoji fallback, prompt subject) ─────────────────────────────────────────────
ART: dict[str, tuple[str, str]] = {}


def art(id: str, emoji: str, prompt: str) -> str:
    ART.setdefault(id, (emoji, prompt))
    return id


for _id, _e, _p in [
    # fruit, food, kitchen
    ("orange", "🍊", "a shiny round orange fruit with a green leaf"),
    ("orange_half", "🍊", "half of an orange cut open showing juicy slices"),
    ("juicer", "🍋", "a cute turquoise citrus juicer"),
    ("glass", "🥛", "an empty clear drinking glass"),
    ("juice", "🧃", "a cartoon juice box with a bendy straw and an orange on it"),
    ("flour", "🌾", "a small sack of white flour"),
    ("water_jug", "💧", "a blue jug of water"),
    ("bowl_mix", "🥣", "a big mixing bowl"),
    ("dough", "🫓", "a round beige pizza base on a wooden cutting board"),
    ("oven", "🔥", "a cute small kitchen oven with a glowing window"),
    ("bread", "🍞", "a cartoon baked bread loaf on a wooden board"),
    ("carrot", "🥕", "an orange carrot with green leaves"),
    ("potato", "🥔", "a brown potato"),
    ("tomato", "🍅", "a bunch of three red cherry tomatoes on a vine"),
    ("rotten_apple", "🍂", "a brown rotten apple with a worm, funny not scary"),
    ("old_shoe", "👞", "an old brown shoe"),
    ("pot", "🍲", "a red cooking pot"),
    ("soup", "🍲", "a bowl of warm vegetable soup with steam"),
    ("egg", "🥚", "a white egg"),
    ("eggs", "🥚", "three eggs in a small nest of straw"),
    ("candle", "🕯️", "a small striped birthday candle"),
    ("cake", "🎂", "a round birthday cake with pink frosting and candles"),
    ("milk", "🥛", "a bottle of milk"),
    ("fridge", "🧊", "a cute white refrigerator"),
    ("cheese", "🧀", "a wedge of yellow cheese"),
    ("lettuce", "🥬", "a green lettuce leaf"),
    ("sandwich", "🥪", "a cheese and lettuce sandwich"),
    ("honey", "🍯", "a pot of golden honey"),
    # garden, farm
    ("watering_can", "🚿", "a turquoise watering can"),
    ("can_body", "🪣", "the round body of a turquoise watering can without spout or handle"),
    ("can_spout", "🚿", "the long spout of a turquoise watering can, alone"),
    ("can_handle", "➰", "the curved handle of a turquoise watering can, alone"),
    ("well", "⛲", "a small stone water well with a wooden crank"),
    ("seed", "🌰", "a single brown seed"),
    ("flower_pot", "🌷", "a pink tulip blooming in a terracotta flower pot"),
    ("empty_pot", "🪴", "an empty terracotta flower pot full of soil"),
    ("sprout", "🌱", "a small green sprout"),
    ("bee", "🐝", "a cute round bumblebee"),
    ("hay", "🌾", "a small bundle of yellow hay"),
    ("nest", "🪺", "an empty straw nest"),
    ("hen", "🐔", "a cute white hen with a red comb"),
    ("cow", "🐄", "a cute cartoon cow, white with black spots"),
    ("bucket", "🪣", "a metal milk bucket"),
    # workshop
    ("hammer", "🔨", "a toy-like hammer with a wooden handle"),
    ("hammer_head", "🔩", "the metal head of a hammer, alone"),
    ("hammer_handle", "🪵", "a wooden hammer handle, alone"),
    ("screw", "🔩", "a shiny screw"),
    ("nail", "📍", "a shiny nail"),
    ("plank", "🪵", "a wooden plank"),
    ("flashlight", "🔦", "a cute yellow flashlight"),
    ("battery", "🔋", "a battery"),
    ("bulb", "💡", "a small light bulb"),
    ("cart", "🛒", "a small wooden pull cart with two wheels"),
    ("wheel", "⚙️", "a toy wheel"),
    ("box", "📦", "a cardboard box"),
    ("toy_car", "🚗", "a cute red toy car with a wind-up key"),
    ("car_body", "🚙", "the red body of a toy car without wheels"),
    ("car_key", "🗝️", "a golden wind-up key"),
    ("junk_spoon", "🥄", "a spoon"),
    ("junk_sock", "🧦", "a striped sock"),
    # art studio
    ("brush", "🖌️", "a paint brush"),
    ("bristles", "🖌️", "a tuft of brush bristles"),
    ("paints", "🎨", "an artist's palette with colorful paints and a brush"),
    ("clay", "🟤", "an orange terracotta clay block with a wooden sculpting tool"),
    ("clay_bowl", "🥣", "a hand made clay bowl painted with dots"),
    ("pottery_wheel", "🏺", "a small toy potter's wheel with a clay pot on it"),
    ("paper", "📄", "a sheet of colored paper"),
    ("scissors", "✂️", "child safe scissors"),
    ("lantern", "🏮", "a glowing paper lantern"),
    ("mask", "🎭", "a colorful paper animal mask"),
    ("bunting", "🎏", "a string of colorful triangle party flags"),
    ("flag", "🚩", "a single triangle paper flag"),
    # night forest
    ("map_piece", "🗺️", "a torn piece of an old treasure map"),
    ("map", "🗺️", "a cute hand drawn forest map with a red dotted path"),
    ("tent", "⛺", "a small orange camping tent"),
    ("tent_cloth", "🟧", "a folded orange tent cloth"),
    ("pole", "🥢", "a tent pole"),
    ("peg", "📌", "a tent peg"),
    ("firefly", "✨", "a cute glowing firefly"),
    ("firefly_jar", "🫙", "a glass jar full of glowing fireflies"),
    ("baby_owl", "🦉", "a cute fluffy baby owl"),
    ("telescope", "🔭", "a cute toy telescope on a tripod"),
    ("lens", "🔍", "a round magnifying glass lens without handle"),
    ("tube", "🧻", "a cardboard tube"),
    ("moon", "🌙", "a smiling crescent moon"),
    ("star", "⭐", "a shiny yellow star"),
    # music
    ("drum", "🥁", "a red toy drum with sticks"),
    ("drum_skin", "⚪", "a round white drum head"),
    ("xylophone", "🎹", "a rainbow toy xylophone with two mallets"),
    ("bar_red", "🟥", "a red xylophone bar"),
    ("flute", "🪈", "a simple reed flute"),
    ("reed", "🎋", "a long green reed stalk"),
    ("song", "🎶", "colorful music notes flying"),
    ("note", "🎵", "a purple music note"),
    # city
    ("bridge", "🌉", "a small wooden bridge over a river"),
    ("traffic_light", "🚦", "a cute traffic light"),
    ("light_red", "🔴", "a round red traffic lamp"),
    ("light_yellow", "🟡", "a round yellow traffic lamp"),
    ("light_green", "🟢", "a round green traffic lamp"),
    ("bus", "🚌", "a cute yellow city bus seen from the side"),
    ("tire", "🛞", "a black tire"),
    ("fuel", "⛽", "a red fuel can"),
    ("letter", "✉️", "a pink envelope with a heart"),
    ("mailbox", "📮", "a red mailbox"),
    ("invitation", "💌", "a colorful folded greeting card decorated with balloons and confetti, blank, without any writing"),
    # festival
    ("feast", "🍱", "a festival table full of food"),
    ("decorations", "🎊", "colorful party decorations, lanterns and flags"),
    ("concert", "🎤", "a small festival music stage with instruments"),
    ("medal", "🏅", "a golden medal with a star on a ribbon"),
    ("firework", "🎆", "colorful fireworks"),
    # kits
    ("bubbles", "🫧", "a pink bubble wand with rainbow soap bubbles floating"),
    ("soap_bottle", "🧴", "a bottle of bubble soap"),
    ("necklace", "📿", "a colorful bead necklace"),
    ("bead", "🔵", "a round colorful bead"),
    ("kite", "🪁", "a colorful diamond kite with a tail"),
    ("robot", "🤖", "a cute friendly toy robot"),
    ("robot_head", "🤖", "the head of a cute toy robot"),
    ("robot_body", "🟦", "the body of a cute toy robot"),
    ("dollhouse", "🏠", "a cute pink dollhouse"),
    ("rocket", "🚀", "a cute toy rocket"),
    ("submarine", "🟡", "a cute yellow toy submarine"),
    ("fish", "🐟", "a cute orange goldfish"),
    ("train", "🚂", "a cute toy steam train"),
    ("rail", "🛤️", "a piece of toy train track"),
    # shop tools and recipes
    ("magnifier", "🔍", "a magnifying glass"),
    ("ladybug", "🐞", "a cute ladybug"),
    ("bug_book", "📔", "a children's notebook with bug stickers"),
    ("saw", "🪚", "a classic carpenter hand saw with a wooden handle and a long flat toothed metal blade, toy style"),
    ("bird_house", "🏡", "a wooden bird house"),
    ("glue_gun", "🧴", "a toy glue gun"),
    ("photo_frame", "🖼️", "a colorful photo frame"),
    ("big_oven", "♨️", "a big cute baking oven"),
    ("pizza", "🍕", "a whole round pizza with cheese and tomato slices"),
    ("cookie", "🍪", "a chocolate chip cookie"),
    ("sewing_machine", "🧵", "a cute sewing machine"),
    ("rag_doll", "🧸", "a soft rag doll"),
    ("drill", "🛠️", "a toy power drill"),
    ("windmill", "🌬️", "a small toy windmill"),
    ("wrench", "🔧", "a wrench"),
    ("bicycle", "🚲", "a red child's bicycle"),
    ("magnet", "🧲", "a red horseshoe magnet"),
    ("magnet_fish", "🎣", "a toy fishing rod with a magnet"),
    # quiz pictures
    ("q_thirsty", "🥵", "a thirsty little rabbit holding an empty cup"),
    ("q_sleep", "😴", "a sleeping little bear in bed"),
    ("q_paint", "🎨", "a child painting on an easel"),
    ("q_hungry", "😋", "a hungry little bear holding a spoon"),
    ("q_cold", "🥶", "a little owl shivering in the cold"),
    ("q_flowers", "🌼", "thirsty drooping flowers"),
    ("q_dark", "🌑", "a dark room at night"),
    ("q_carry", "📦", "a pile of heavy boxes"),
    ("q_nail", "🪵", "two wooden planks and a nail"),
    ("q_travel", "🛣️", "a winding road"),
    ("q_music", "🎵", "music notes"),
    ("q_rain", "🌧️", "a rain cloud with drops"),
    ("q_lost", "❓", "a little owl lost in the forest"),
    ("q_sky", "🌌", "a starry night sky"),
    ("q_party", "🎉", "a bunch of colorful balloons and a gift box, without any writing"),
    ("q_swim", "🏊", "a swimming pool"),
    ("q_cross", "🚸", "children crossing the street"),
    ("q_eat", "🍽️", "a plate and a spoon"),
    ("q_wear", "😺", "a happy cat wearing a mask"),
    ("q_water", "💧", "a water drop"),
]:
    art(_id, _e, _p)

# ── characters ──────────────────────────────────────────────────────────────────────────────────
FRIENDS = {
    "bear": ("خاله خرسی", "🐻", "a kind round mother bear wearing a white chef apron and a small chef hat"),
    "bunny": ("بانی", "🐰", "a cute little white bunny girl with long pink ears and a green overall"),
    "squirrel": ("آقا سنجاب", "🐿️", "a cute brown squirrel with a big fluffy tail wearing a blue work apron and goggles on his head"),
    "parrot": ("کوکو", "🦜", "a cute colorful parrot artist with a red beret"),
    "owl": ("مادربزرگ جغد", "🦉", "a cute old grandma owl with round glasses and a knitted purple shawl"),
    "cat": ("میمی", "🐱", "a cute grey kitten girl singer with a yellow bow tie"),
    "turtle": ("لاکی", "🐢", "a cute green turtle bus driver with a blue driver cap"),
}

# ── mini-game step builders ─────────────────────────────────────────────────────────────────────


def step(engine: str, say: str, **p) -> dict:
    assert engine in ENGINES, engine
    return {"engine": engine, "say": say, **p}


def collect(target, n, say, distract=(), sound="audio/ui/pop.mp3"):
    return step("collect", say, target=target, count=n, distract=list(distract), sound=sound)


def sort(good, bad, say, good_label="خوب", bad_label="خراب"):
    return step("sort", say, good=good, bad=bad, goodLabel=good_label, badLabel=bad_label)


def cut(target, say, lines=1, result=None):
    return step("cut", say, target=target, lines=lines, result=result or target)


def tap(target, n, say, sound, label="", result=None):
    return step("tap", say, target=target, count=n, sound=sound, label=label, result=result or target)


def rotate(target, turns, say, sound="audio/sfx/stir.mp3", result=None):
    return step("rotate", say, target=target, turns=turns, sound=sound, result=result or target)


def pour(source, into, say, sound="audio/sfx/pour.mp3", color="#FFA726"):
    return step("pour", say, source=source, into=into, sound=sound, color=color)


def timing(target, say, sound="audio/ui/chime.mp3", label="حالا!", result=None):
    return step("timing", say, target=target, sound=sound, label=label, result=result or target)


def assemble(base, parts, say, result):
    """parts: [(art, x, y)] in 0..1 of the build area; base is drawn faint underneath."""
    return step("assemble", say, base=base, parts=[{"art": a, "x": x, "y": y} for a, x, y in parts], result=result)


def order(items, say, sound=None):
    """items in the right order (biggest first, or a sequence)."""
    return step("order", say, items=items, sound=sound)


def count(target, n, into, say, sound="audio/ui/pop.mp3"):
    return step("count", say, target=target, count=n, into=into, sound=sound)


def paint(target, say, parts=4):
    return step("paint", say, target=target, areas=parts)


def mix(a, b, result, result_name, say):
    return step("mix", say, a=a, b=b, result=result, resultName=result_name)


def scrub(target, say):
    return step("scrub", say, target=target)


def dark(target, n, say):
    return step("dark", say, target=target, count=n)


def trace(target, say, shape="wave"):
    return step("trace", say, target=target, shape=shape)


def rhythm(pads, say, rounds=3):
    """pads: [(art, sound)]"""
    return step("rhythm", say, pads=[{"art": a, "sound": s} for a, s in pads], rounds=rounds)


def puzzle(target, say):
    return step("puzzle", say, target=target)


def use(need, spot, say, done, why):
    """An obstacle that only a thing from the backpack solves. why = what the item is for (said
    when the child offers the wrong one)."""
    return step("use", say, need=need, spot=spot, done=done, why=why)


def serve(pairs, say):
    """pairs: [(friend, item)] — give each friend what they want, from the backpack."""
    return step("serve", say, pairs=[{"friend": f, "item": i} for f, i in pairs])


# ── items (things the child makes) ──────────────────────────────────────────────────────────────
ITEMS: dict[str, dict] = {}


def item(id, title, kind, sound, use_text, quiz, *, taste=None, target=None, tags=(), play=None):
    """quiz = (question, [(art, label)], index of the right answer)."""
    q, options, answer = quiz
    ITEMS[id] = {
        "id": id, "title": title, "kind": kind, "sound": sound, "use": use_text, "taste": taste,
        "target": target, "tags": list(tags), "play": play or kind,
        "quiz": {"q": q, "options": [{"art": a, "label": l} for a, l in options], "answer": answer},
    }
    return id


S = "audio/sfx/"
I = "audio/instruments/"
item("juice", "آب‌پرتقال", "drink", S + "sip.mp3", "آب‌میوه تشنگی را برطرف می‌کند و ویتامین دارد.",
     ("با آب‌میوه چه کار می‌کنیم؟", [("q_thirsty", "تشنگی"), ("q_sleep", "خواب"), ("q_paint", "نقاشی")], 0),
     taste="شیرین و کمی ترش", tags=["drink", "sweet", "food"])
item("bread", "نان", "food", S + "crunch.mp3", "نان غذای هر روز ماست؛ با آن ساندویچ هم درست می‌کنیم.",
     ("نان را کی می‌خوریم؟", [("q_hungry", "وقتی گرسنه‌ایم"), ("q_cold", "وقتی سردمان است"), ("q_dark", "وقتی تاریک است")], 0),
     taste="ترد و گرم", tags=["food"])
item("soup", "سوپ سبزیجات", "food", S + "sizzle.mp3", "سوپ گرم، وقتی سردمان است بدن را گرم می‌کند.",
     ("سوپ گرم به درد کی می‌خورد؟", [("q_cold", "کسی که سردش است"), ("q_swim", "کسی که شنا می‌کند"), ("q_paint", "کسی که نقاشی می‌کند")], 0),
     taste="شور و داغ", tags=["food", "warm"])
item("cake", "کیک تولد", "food", S + "giggle.mp3", "کیک برای جشن و تولد است؛ شمع‌ها را فوت می‌کنیم.",
     ("کیک تولد برای چیست؟", [("q_party", "جشن"), ("q_rain", "باران"), ("q_carry", "بار بردن")], 0),
     taste="شیرین", tags=["food", "sweet", "party"])
item("watering_can", "آب‌پاش", "container", S + "splash.mp3", "با آب‌پاش به گل‌ها و گیاه‌ها آب می‌دهیم.",
     ("با آب‌پاش چه کار می‌کنیم؟", [("q_flowers", "آب دادن به گل‌ها"), ("q_eat", "غذا خوردن"), ("q_nail", "میخ زدن")], 0),
     target="q_flowers", tags=["water"])
item("flower_pot", "گلدان گل", "plant", S + "buzz.mp3", "گل بوی خوش دارد و زنبورها از آن شهد می‌گیرند.",
     ("کی سراغ گل می‌آید؟", [("bee", "زنبور"), ("fish", "ماهی"), ("moon", "ماه")], 0),
     taste="خوش‌بو", tags=["pretty", "plant"])
item("eggs", "تخم‌مرغ", "food", S + "cluck.mp3", "مرغ تخم می‌گذارد؛ با تخم‌مرغ کیک و نیمرو درست می‌کنیم.",
     ("تخم‌مرغ از کجا می‌آید؟", [("hen", "مرغ"), ("cow", "گاو"), ("bee", "زنبور")], 0),
     taste="پخته‌اش خوشمزه است", tags=["food"])
item("sandwich", "ساندویچ پنیر", "food", S + "crunch.mp3", "ساندویچ یک غذای کامل و راحت برای پیک‌نیک است.",
     ("ساندویچ را با چه درست کردیم؟", [("bread", "نان و پنیر"), ("paints", "رنگ"), ("nail", "میخ")], 0),
     taste="نرم و شور", tags=["food"])
item("hammer", "چکش", "tool", S + "hammer.mp3", "با چکش میخ را در چوب فرو می‌کنیم تا تکه‌ها به هم بچسبند.",
     ("با چکش چه کار می‌کنیم؟", [("q_nail", "میخ زدن"), ("q_flowers", "آب دادن"), ("q_eat", "غذا خوردن")], 0),
     target="nail", tags=["tool", "build"])
item("flashlight", "چراغ‌قوه", "light", S + "light_switch.mp3", "چراغ‌قوه در تاریکی راه را روشن می‌کند.",
     ("چراغ‌قوه کجا به کار می‌آید؟", [("q_dark", "تاریکی"), ("q_swim", "استخر"), ("q_party", "تولد")], 0),
     tags=["light"])
item("cart", "گاری", "cart", S + "squeak.mp3", "با گاری بارهای سنگین را راحت جابه‌جا می‌کنیم.",
     ("گاری به چه کاری می‌آید؟", [("q_carry", "بردن بار"), ("q_music", "موسیقی"), ("q_sleep", "خواب")], 0),
     target="box", tags=["carry"])
item("toy_car", "ماشین اسباب‌بازی", "vehicle", S + "engine.mp3", "ماشین با موتور روشن می‌شود و ما را به جاهای دور می‌برد.",
     ("ماشین چطور راه می‌افتد؟", [("car_key", "با کلید روشن می‌شود"), ("watering_can", "با آب"), ("brush", "با رنگ")], 0),
     tags=["vehicle"])
item("paints", "رنگ‌ها", "craft", S + "rustle.mp3", "قرمز و زرد با هم نارنجی می‌شوند؛ آبی و زرد سبز!",
     ("قرمز و زرد با هم چه رنگی می‌شوند؟", [("orange", "نارنجی"), ("lettuce", "سبز"), ("bar_red", "قرمز")], 0),
     tags=["color"])
item("clay_bowl", "کاسه‌ی گلی", "container", "audio/ui/pop.mp3", "کاسه‌ی خوب آب را نگه می‌دارد و چیزی نمی‌ریزد.",
     ("کاسه را برای چه می‌سازیم؟", [("q_water", "نگه داشتن آب و غذا"), ("q_nail", "میخ زدن"), ("q_dark", "روشنایی")], 0),
     tags=["water", "container"])
item("lantern", "فانوس", "light", "audio/ui/chime.mp3", "فانوس با نور رنگی، شب را قشنگ و روشن می‌کند.",
     ("فانوس کی روشن می‌شود؟", [("q_dark", "شب"), ("q_swim", "استخر"), ("q_eat", "غذا")], 0),
     tags=["light", "pretty"])
item("mask", "ماسک", "craft", S + "giggle.mp3", "ماسک را برای بازی و جشن به صورت می‌زنیم.",
     ("ماسک را کجا می‌زنیم؟", [("q_wear", "روی صورت"), ("q_flowers", "روی گل"), ("q_carry", "روی جعبه")], 0),
     tags=["pretty", "party"])
item("map", "نقشه‌ی جنگل", "map", "audio/ui/page.mp3", "نقشه راه را نشان می‌دهد تا گم نشویم.",
     ("نقشه به چه درد می‌خورد؟", [("q_lost", "پیدا کردن راه"), ("q_hungry", "غذا"), ("q_music", "آواز")], 0),
     tags=["find"])
item("tent", "چادر", "shelter", "audio/ambient/rain.ogg", "چادر زیر باران ما را خشک و گرم نگه می‌دارد.",
     ("چادر کی به کار می‌آید؟", [("q_rain", "باران"), ("q_paint", "نقاشی"), ("q_cross", "خیابان")], 0),
     tags=["shelter"])
item("firefly_jar", "شیشه‌ی کرم شب‌تاب", "light", "audio/ui/sparkle.mp3", "کرم‌های شب‌تاب خودشان نور دارند!",
     ("کرم شب‌تاب کی می‌درخشد؟", [("q_dark", "شب"), ("q_swim", "استخر"), ("q_hungry", "ناهار")], 0),
     tags=["light"])
item("telescope", "تلسکوپ", "lookout", "audio/ui/sparkle.mp3", "با تلسکوپ چیزهای خیلی دور مثل ماه و ستاره‌ها را نزدیک می‌بینیم.",
     ("با تلسکوپ چه می‌بینیم؟", [("q_sky", "ماه و ستاره‌ها"), ("q_eat", "غذا"), ("q_carry", "جعبه‌ها")], 0),
     tags=["find", "sky"])
item("drum", "طبل", "instrument", I + "drum_tom.mp3", "طبل با ضربه صدا می‌دهد؛ ضربه‌ی محکم بلند، ضربه‌ی آرام آهسته.",
     ("طبل را چطور می‌نوازیم؟", [("drum", "با ضربه"), ("flute", "با فوت"), ("water_jug", "با آب")], 0),
     tags=["music", "low"])
item("xylophone", "زایلوفون", "instrument", I + "xylo_c4.mp3", "تیغه‌ی بلند صدای بم دارد و تیغه‌ی کوتاه صدای زیر.",
     ("تیغه‌ی کوتاه چه صدایی دارد؟", [("note", "زیر"), ("drum", "بم"), ("q_sleep", "بی‌صدا")], 0),
     tags=["music", "high"])
item("flute", "نی", "instrument", I + "flute.mp3", "نی را با فوت می‌نوازیم؛ سوراخ‌ها نت را عوض می‌کنند.",
     ("نی را چطور می‌نوازیم؟", [("flute", "با فوت"), ("hammer", "با چکش"), ("brush", "با رنگ")], 0),
     tags=["music", "high"])
item("song", "آهنگ جشن", "song", I + "xylo_g4.mp3", "آهنگ را با چند ساز با هم می‌نوازیم.",
     ("آهنگ را با چه ساختیم؟", [("drum", "سازها"), ("pot", "قابلمه"), ("bus", "اتوبوس")], 0),
     tags=["music"])
item("bridge", "پل", "build", S + "car_horn.mp3", "پل دو طرف رودخانه را به هم وصل می‌کند.",
     ("پل به چه درد می‌خورد؟", [("q_travel", "رد شدن از رودخانه"), ("q_sleep", "خوابیدن"), ("q_eat", "غذا")], 0),
     tags=["build"])
item("traffic_light", "چراغ راهنمایی", "signal", "audio/ui/toggle.mp3", "قرمز یعنی بایست، سبز یعنی برو.",
     ("چراغ قرمز یعنی چه؟", [("light_red", "بایست"), ("light_green", "برو"), ("q_party", "جشن")], 0),
     tags=["rules"])
item("bus", "اتوبوس", "vehicle", S + "bus_horn.mp3", "اتوبوس خیلی‌ها را با هم جابه‌جا می‌کند.",
     ("اتوبوس برای چیست؟", [("q_travel", "بردن مسافرها"), ("q_flowers", "آب دادن"), ("q_music", "آواز")], 0),
     tags=["vehicle"])
item("invitation", "کارت دعوت", "letter", "audio/ui/page.mp3", "با کارت دعوت دوستانمان را به جشن خبر می‌کنیم.",
     ("کارت دعوت برای چیست؟", [("q_party", "خبر کردن برای جشن"), ("q_hungry", "غذا"), ("q_dark", "نور")], 0),
     tags=["party"])
item("feast", "میز جشن", "food", S + "giggle.mp3", "همه‌ی غذاهایی که ساختی روی یک میز!",
     ("روی میز جشن چه گذاشتیم؟", [("q_eat", "غذاها"), ("tent", "چادر"), ("tire", "لاستیک")], 0),
     taste="خوشمزه", tags=["food", "party"])
item("decorations", "تزئینات جشن", "craft", "audio/ui/sparkle.mp3", "تزئینات میدان را رنگی و شاد می‌کند.",
     ("تزئینات برای چیست؟", [("q_party", "قشنگ کردن جشن"), ("q_cold", "گرم شدن"), ("q_travel", "سفر")], 0),
     tags=["pretty", "party"])
item("concert", "کنسرت جشن", "song", I + "xylo_c5.mp3", "گروه میمی آهنگ تو را می‌نوازد!",
     ("در کنسرت چه می‌شنویم؟", [("q_music", "موسیقی"), ("q_rain", "باران"), ("cow", "گاو")], 0),
     tags=["music", "party"])
item("medal", "مدال قهرمان جنگل", "medal", "audio/ui/success.mp3", "تو با ساخته‌هایت جشن جنگل را نجات دادی!",
     ("چه کسی جشن را نجات داد؟", [("medal", "من!"), ("moon", "ماه"), ("tire", "لاستیک")], 0),
     tags=["party"])
# Star Workshop kits
item("bubbles", "حباب‌ساز", "bubbles", S + "bubbles.mp3", "با فوت، صابون حباب‌های رنگی می‌شود.",
     ("حباب چطور درست می‌شود؟", [("bubbles", "با فوت و صابون"), ("hammer", "با چکش"), ("bread", "با نان")], 0), tags=["play"])
item("necklace", "گردنبند مهره‌ای", "craft", "audio/ui/chime.mp3", "مهره‌ها را به ترتیب رنگ به نخ می‌کشیم.",
     ("گردنبند را کجا می‌اندازیم؟", [("q_wear", "گردن"), ("q_flowers", "گل"), ("q_carry", "جعبه")], 0), tags=["pretty"])
item("kite", "بادبادک", "kite", "audio/ambient/wind.ogg", "باد بادبادک را بالا می‌برد.",
     ("بادبادک با چه بالا می‌رود؟", [("q_sky", "باد"), ("q_water", "آب"), ("q_eat", "غذا")], 0), tags=["play", "sky"])
item("robot", "ربات", "robot", S + "robot.mp3", "ربات با باتری روشن می‌شود و کارهایی را که بگوییم انجام می‌دهد.",
     ("ربات با چه روشن می‌شود؟", [("battery", "باتری"), ("water_jug", "آب"), ("bread", "نان")], 0), tags=["play", "machine"])
item("dollhouse", "خانه‌ی عروسکی", "house", S + "door.mp3", "در خانه‌ی عروسکی چراغ‌ها روشن می‌شوند و شیر آب باز می‌شود.",
     ("خانه برای چیست؟", [("q_sleep", "زندگی و خواب"), ("q_swim", "شنا"), ("q_travel", "سفر")], 0), tags=["play"])
item("rocket", "موشک", "rocket", S + "rocket.mp3", "موشک با موتورهای قوی به فضا می‌رود.",
     ("موشک کجا می‌رود؟", [("q_sky", "فضا"), ("q_swim", "استخر"), ("q_eat", "آشپزخانه")], 0), tags=["play", "sky", "vehicle"])
item("submarine", "زیردریایی", "submarine", S + "bubbles.mp3", "زیردریایی زیر آب می‌رود و با چراغش ماهی‌ها را می‌بیند.",
     ("زیردریایی کجا می‌رود؟", [("fish", "زیر آب"), ("q_sky", "آسمان"), ("q_party", "جشن")], 0), tags=["play", "vehicle"])
item("train", "قطار", "vehicle", S + "train.mp3", "قطار روی ریل حرکت می‌کند و سوت می‌کشد: چوووو!",
     ("قطار روی چه حرکت می‌کند؟", [("rail", "ریل"), ("q_water", "آب"), ("q_sky", "ابر")], 0), tags=["play", "vehicle"])
# Tool-shop recipes
item("bug_book", "دفترچه‌ی حشره‌ها", "find", "audio/ui/page.mp3", "با ذره‌بین حشره‌های کوچک را بزرگ می‌بینیم.",
     ("ذره‌بین چه کار می‌کند؟", [("ladybug", "کوچک را بزرگ نشان می‌دهد"), ("q_cold", "گرم می‌کند"), ("q_music", "آواز")], 0), tags=["find"])
item("bird_house", "خانه‌ی پرنده", "house", "audio/animals/bird.mp3", "پرنده در خانه‌اش لانه می‌سازد.",
     ("خانه‌ی پرنده برای کیست؟", [("q_sky", "پرنده"), ("fish", "ماهی"), ("cow", "گاو")], 0), tags=["build"])
item("photo_frame", "قاب عکس", "craft", "audio/ui/camera.mp3", "عکس یادگاری را در قاب می‌گذاریم و به دیوار می‌زنیم.",
     ("قاب عکس برای چیست؟", [("q_party", "نگه داشتن یادگاری"), ("q_hungry", "غذا"), ("q_rain", "باران")], 0), tags=["pretty"])
item("pizza", "پیتزا", "food", S + "sizzle.mp3", "پیتزا را در فر می‌پزیم تا پنیرش آب شود.",
     ("پیتزا را کجا می‌پزیم؟", [("big_oven", "فر"), ("fridge", "یخچال"), ("bucket", "سطل")], 0), taste="شور و داغ", tags=["food"])
item("cookie", "کلوچه", "food", S + "crunch.mp3", "کلوچه‌ی تازه ترد و شیرین است.",
     ("کلوچه چه مزه‌ای دارد؟", [("cake", "شیرین"), ("lettuce", "تلخ"), ("soup", "شور")], 0), taste="شیرین و ترد", tags=["food", "sweet"])
item("rag_doll", "عروسک پارچه‌ای", "doll", S + "giggle.mp3", "عروسک نرم را بغل می‌کنیم.",
     ("با عروسک چه کار می‌کنیم؟", [("q_sleep", "بغل و بازی"), ("q_nail", "میخ"), ("q_travel", "رانندگی")], 0), tags=["play"])
item("windmill", "آسیاب بادی", "windmill", "audio/ambient/wind.ogg", "باد پره‌ها را می‌چرخاند.",
     ("چه چیزی آسیاب بادی را می‌چرخاند؟", [("q_sky", "باد"), ("q_water", "آب"), ("q_hungry", "غذا")], 0), tags=["machine"])
item("bicycle", "دوچرخه", "vehicle", S + "bike_bell.mp3", "دوچرخه با رکاب زدن حرکت می‌کند: زینگ زینگ!",
     ("دوچرخه چطور حرکت می‌کند؟", [("q_travel", "با رکاب زدن"), ("q_rain", "با باران"), ("q_music", "با آواز")], 0), tags=["vehicle"])
item("magnet_fish", "ماهیگیری آهن‌ربایی", "magnet", S + "snap.mp3", "آهن‌ربا چیزهای آهنی را به خودش می‌کشد.",
     ("آهن‌ربا چه چیزی را می‌کشد؟", [("nail", "میخ آهنی"), ("paper", "کاغذ"), ("bread", "نان")], 0), tags=["play", "machine"])

# ── chapters and sections ─────────────────────────────────────────────────────────────────────


def section(id, title, makes, mission, steps, target=120, secret=None):
    assert makes in ITEMS, makes
    return {"id": id, "title": title, "makes": makes, "mission": mission, "steps": steps,
            "targetSec": target, "secret": secret}


CHAPTERS = [
    {
        "id": "c1", "title": "آشپزخانه‌ی خاله خرسی", "friend": "bear", "bg": "kitchen", "color": "#FF8A1F",
        "ambient": "audio/ambient/kitchen.ogg",
        "intro": "طوفان آشپزخانه‌ی خاله خرسی را به هم ریخته و برای جشن هیچ غذایی نمانده. بیا با هم آشپزی کنیم!",
        "film": ["آب‌پرتقال شیرین و ترش", "نان ترد و گرم", "سوپ داغ و خوشمزه", "و کیک تولد با شمع‌های روشن!"],
        "next": "بانی در باغ تشنه است... بیا برویم پیشش!",
        "sections": [
            section("c1s1", "آب‌پرتقال", "juice", "خاله خرسی تشنه است. بیا برایش آب‌پرتقال درست کنیم!", [
                collect("orange", 4, "پرتقال‌های رسیده را از درخت بچین.", distract=["rotten_apple"]),
                cut("orange", "پرتقال را از وسط نصف کن. انگشتت را روی خط بکش.", result="orange_half"),
                tap("juicer", 8, "پرتقال را روی آب‌گیری فشار بده! تند تند بزن.", S + "squeak.mp3", result="juice"),
                pour("juice", "glass", "حالا آب‌میوه را در لیوان بریز. تا خط پر کن، نه بیشتر!", color="#FFA726"),
            ], 100, secret="magnifier"),
            section("c1s2", "نان", "bread", "برای ناهار نان لازم داریم. بیا نان بپزیم!", [
                pour("flour", "bowl_mix", "آرد را در کاسه بریز.", sound=S + "rustle.mp3", color="#FFF3E0"),
                pour("water_jug", "bowl_mix", "کمی آب هم اضافه کن.", color="#4FC3F7"),
                tap("dough", 10, "خمیر را ورز بده! با هر ضربه نرم‌تر می‌شود.", S + "thunk.mp3"),
                timing("oven", "نان را در فر گذاشتیم. وقتی طلایی شد، بزن!", sound=S + "kettle.mp3", result="bread"),
            ], 110, secret="big_oven"),
            section("c1s3", "سوپ سبزیجات", "soup", "باد سرد می‌آید. یک سوپ گرم بپزیم!", [
                sort(["carrot", "potato", "tomato"], ["rotten_apple", "old_shoe"], "سبزی‌های سالم را در سبد بگذار و خراب‌ها را در سطل.", "سالم", "خراب"),
                cut("carrot", "هویج را خرد کن.", lines=3),
                count("carrot", 3, "pot", "سه تکه هویج در قابلمه بینداز.", sound=S + "splash.mp3"),
                rotate("pot", 3, "سوپ را هم بزن. انگشتت را دور قابلمه بچرخان.", result="soup"),
            ], 120),
            section("c1s4", "کیک تولد", "cake", "امروز تولد خاله خرسی است! بیا کیک بپزیم.", [
                tap("egg", 3, "تخم‌مرغ‌ها را بشکن. روی هر کدام بزن.", S + "snap.mp3", result="bowl_mix"),
                pour("flour", "bowl_mix", "آرد را اضافه کن.", sound=S + "rustle.mp3", color="#FFF3E0"),
                rotate("bowl_mix", 3, "خوب هم بزن تا خمیر کیک صاف شود.", result="cake"),
                paint("cake", "کیک را با رنگ‌های خوشمزه تزئین کن.", parts=4),
                count("candle", 4, "cake", "چهار شمع روی کیک بگذار.", sound="audio/ui/chime.mp3"),
            ], 140),
        ],
    },
    {
        "id": "c2", "title": "باغ و مزرعه‌ی بانی", "friend": "bunny", "bg": "farm", "color": "#2FBF71",
        "ambient": "audio/ambient/farm.ogg",
        "intro": "بانی تشنه است و باغش خشک شده. کمکش کنیم باغ دوباره سبز شود!",
        "film": ["آب‌پاش، گل‌ها را سیراب کرد", "گلدان گل، زنبورها را آورد", "مرغ‌ها تخم گذاشتند", "و ساندویچ پنیر برای پیک‌نیک!"],
        "next": "کارگاه آقا سنجاب خراب شده... بیا کمکش کنیم!",
        "sections": [
            section("c2s1", "آب‌پاش", "watering_can", "بانی خیلی تشنه است و حرف نمی‌زند! اول یک چیزی برای نوشیدن بهش بده.", [
                use("juice", "q_thirsty", "از کوله‌پشتی چیزی بده که تشنگی را برطرف کند.", "به به! بانی سرحال شد.", "این برای رفع تشنگی نیست."),
                assemble("watering_can", [("can_body", .5, .6), ("can_spout", .2, .45), ("can_handle", .78, .38)], "تکه‌های آب‌پاش را سر جایشان بگذار.", "watering_can"),
                rotate("well", 3, "دسته‌ی چاه را بچرخان تا آب بالا بیاید.", sound=S + "water_tap.mp3"),
                pour("water_jug", "watering_can", "آب‌پاش را پر کن.", color="#4FC3F7"),
            ], 110, secret="magnifier"),
            section("c2s2", "گلدان گل", "flower_pot", "بانی می‌خواهد یک گل قشنگ بکارد.", [
                tap("empty_pot", 5, "خاک را با بیلچه بکن.", S + "rustle.mp3"),
                count("seed", 3, "empty_pot", "سه دانه در خاک بکار."),
                use("watering_can", "empty_pot", "دانه‌ها تشنه‌اند! از کوله چیزی بیاور که با آن آب بدهیم.", "آفرین! دانه‌ها آب خوردند.", "با این نمی‌شود آب داد."),
                timing("sprout", "جوانه دارد بزرگ می‌شود... وقتی گل باز شد بزن!", sound=S + "grow.mp3", result="flower_pot"),
            ], 110),
            section("c2s3", "لانه‌ی مرغ", "eggs", "مرغ‌های بانی لانه ندارند و گم شده‌اند!", [
                collect("hay", 5, "کاه جمع کن.", distract=["old_shoe"], sound=S + "rustle.mp3"),
                count("hay", 4, "nest", "کاه‌ها را در لانه بگذار."),
                collect("hen", 3, "مرغ‌های گم‌شده را پیدا کن. پشت بوته‌ها را ببین!", sound=S + "cluck.mp3"),
            ], 100, secret="saw"),
            section("c2s4", "ساندویچ پیک‌نیک", "sandwich", "وقت پیک‌نیک است! یک ساندویچ خوشمزه درست کنیم.", [
                tap("cow", 6, "گاو را آرام بدوش. با هر ضربه شیر می‌آید.", "audio/animals/cow.mp3", result="milk"),
                rotate("bucket", 3, "شیر را هم بزن تا پنیر شود.", result="cheese"),
                use("bread", "q_hungry", "برای ساندویچ نان لازم داریم! از کوله بیاور.", "نان رسید!", "این نان نیست."),
                order(["bread", "lettuce", "cheese", "bread"], "ساندویچ را لایه‌لایه بچین: نان، کاهو، پنیر، نان."),
            ], 120),
        ],
    },
    {
        "id": "c3", "title": "کارگاه آقا سنجاب", "friend": "squirrel", "bg": "workshop", "color": "#3B82F6",
        "ambient": "audio/ambient/workshop.ogg",
        "intro": "طوفان کارگاه آقا سنجاب را خراب کرده و ابزارهایش پخش شده‌اند. بیا ابزار بسازیم!",
        "film": ["چکش، میخ را فرو کرد: تق تق!", "چراغ‌قوه تاریکی را روشن کرد", "گاری جعبه‌ها را برد", "و ماشین با کلید روشن شد: برووووم!"],
        "next": "کوکو همه‌ی رنگ‌هایش را گم کرده...",
        "sections": [
            section("c3s1", "چکش", "hammer", "آقا سنجاب چکشش را گم کرده. تکه‌هایش این‌جا پخش شده‌اند!", [
                collect("hammer_head", 1, "سر چکش را در کارگاه شلوغ پیدا کن.", distract=["junk_spoon", "junk_sock"]),
                collect("hammer_handle", 1, "دسته‌ی چوبی را هم پیدا کن.", distract=["junk_spoon", "junk_sock"]),
                assemble("hammer", [("hammer_head", .5, .25), ("hammer_handle", .5, .65)], "سر و دسته را به هم وصل کن.", "hammer"),
                rotate("screw", 2, "پیچ را سفت کن.", sound=S + "gear.mp3", result="hammer"),
            ], 100, secret="wrench"),
            section("c3s2", "چراغ‌قوه", "flashlight", "گوشه‌ی کارگاه خیلی تاریک است!", [
                assemble("flashlight", [("battery", .35, .5), ("battery", .6, .5)], "باتری‌ها را در چراغ‌قوه بگذار.", "flashlight"),
                rotate("bulb", 2, "لامپ را بپیچان.", sound=S + "gear.mp3"),
                tap("flashlight", 1, "کلید را بزن!", S + "light_switch.mp3"),
                dark("box", 3, "با نور، جعبه‌های گم‌شده را در تاریکی پیدا کن."),
            ], 100, secret="magnifier"),
            section("c3s3", "گاری", "cart", "جعبه‌ها خیلی سنگین‌اند. یک گاری لازم داریم!", [
                use("hammer", "q_nail", "تخته‌ها باید با میخ به هم وصل شوند. چه وسیله‌ای لازم است؟", "تق تق! تخته‌ها وصل شدند.", "با این نمی‌شود میخ زد."),
                tap("nail", 4, "میخ‌ها را با چکش بکوب!", S + "hammer.mp3"),
                count("wheel", 2, "cart", "دو چرخ به گاری وصل کن.", sound=S + "gear.mp3"),
            ], 100, secret="drill"),
            section("c3s4", "ماشین اسباب‌بازی", "toy_car", "آقا سنجاب یک ماشین قدیمی دارد. بیا درستش کنیم!", [
                count("wheel", 4, "car_body", "چهار چرخ به ماشین وصل کن. بشمار!", sound=S + "gear.mp3"),
                paint("toy_car", "ماشین را رنگ کن.", parts=3),
                rotate("car_key", 3, "کلید را بچرخان تا ماشین روشن شود!", sound=S + "engine.mp3", result="toy_car"),
            ], 110, secret="wrench"),
        ],
    },
    {
        "id": "c4", "title": "آتلیه‌ی رنگی کوکو", "friend": "parrot", "bg": "studio", "color": "#E9478F",
        "ambient": "audio/ambient/studio.ogg",
        "intro": "کوکو همه‌ی رنگ‌هایش را در طوفان گم کرده و تزئینات جشن بی‌رنگ مانده‌اند.",
        "film": ["قرمز و زرد، نارنجی شد!", "کاسه‌ی گلی آب را نگه داشت", "فانوس با لامپ چراغ‌قوه روشن شد", "و ماسک‌ها و پرچم‌ها رنگی شدند!"],
        "next": "مادربزرگ جغد راه خانه‌اش را در شب گم کرده...",
        "sections": [
            section("c4s1", "رنگ‌ها", "paints", "اول یک قلم‌مو و رنگ می‌خواهیم!", [
                assemble("brush", [("bristles", .5, .2), ("brush", .5, .6)], "موهای قلم‌مو را به دسته وصل کن.", "brush"),
                mix("#F44336", "#FFEB3B", "#FF9800", "نارنجی", "قرمز و زرد را با هم مخلوط کن. چه رنگی شد؟"),
                mix("#2196F3", "#FFEB3B", "#4CAF50", "سبز", "حالا آبی و زرد!"),
            ], 90, secret="glue_gun"),
            section("c4s2", "کاسه‌ی گلی", "clay_bowl", "کوکو یک کاسه برای آب رنگ‌ها می‌خواهد.", [
                use("watering_can", "clay", "گل رس خشک است! با چه خیسش کنیم؟", "شُر شُر! گل نرم شد.", "با این نمی‌شود خیس کرد."),
                tap("clay", 6, "گل را ورز بده.", S + "thunk.mp3"),
                rotate("pottery_wheel", 3, "چرخ سفالگری را بچرخان تا کاسه شکل بگیرد.", result="clay_bowl"),
                paint("clay_bowl", "کاسه را رنگ کن.", parts=3),
            ], 120),
            section("c4s3", "فانوس", "lantern", "برای شب جشن فانوس رنگی لازم داریم.", [
                cut("paper", "کاغذ را روی خط‌ها ببُر.", lines=2),
                paint("lantern", "فانوس را رنگ کن.", parts=4),
                use("flashlight", "lantern", "فانوس نور ندارد! چه چیزی لامپ دارد؟", "روشن شد! چه قشنگ.", "این نور ندارد."),
            ], 110, secret="glue_gun"),
            section("c4s4", "ماسک و پرچم", "mask", "برای جشن ماسک و پرچم درست کنیم!", [
                cut("paper", "ماسک را با قیچی ببُر.", lines=2, result="mask"),
                paint("mask", "ماسک را رنگ کن.", parts=4),
                count("flag", 5, "bunting", "پنج پرچم به نخ آویزان کن."),
            ], 110, secret="sewing_machine"),
        ],
    },
    {
        "id": "c5", "title": "شب جنگل و مادربزرگ جغد", "friend": "owl", "bg": "night_forest", "color": "#5B2BC4",
        "ambient": "audio/ambient/night.ogg",
        "intro": "مادربزرگ جغد راه خانه‌اش را در جنگلِ شب گم کرده. نترس، با هم پیدایش می‌کنیم!",
        "film": ["نقشه راه را نشان داد", "چادر ما را از باران حفظ کرد", "کرم‌های شب‌تاب مسیر را روشن کردند", "و با تلسکوپ ماه را دیدیم!"],
        "next": "سازهای گروه میمی شکسته‌اند...",
        "sections": [
            section("c5s1", "نقشه‌ی جنگل", "map", "تکه‌های نقشه در باد پخش شده‌اند!", [
                puzzle("map", "تکه‌های نقشه را کنار هم بچین."),
                trace("map", "با انگشت راه را از خانه‌ی جغد تا درخت بزرگ دنبال کن.", shape="wave"),
            ], 100, secret="magnifier"),
            section("c5s2", "چادر", "tent", "باران دارد می‌آید! یک چادر بزنیم.", [
                assemble("tent", [("tent_cloth", .5, .45), ("pole", .25, .6), ("pole", .75, .6)], "پارچه و ستون‌های چادر را سر جایشان بگذار.", "tent"),
                use("hammer", "peg", "میخ‌های چادر را با چه بکوبیم؟", "تق تق! چادر محکم شد.", "با این نمی‌شود میخ زد."),
                tap("peg", 4, "همه‌ی میخ‌ها را بکوب.", S + "hammer.mp3"),
            ], 110),
            section("c5s3", "مسیر نورانی", "firefly_jar", "مسیر خیلی تاریک است و مادربزرگ سردش است.", [
                use("flashlight", "q_dark", "با چه چیزی تاریکی را روشن کنیم؟", "روشن شد!", "این نور ندارد."),
                dark("firefly", 4, "کرم‌های شب‌تاب را در تاریکی پیدا کن و در شیشه بگذار."),
                use("soup", "q_cold", "مادربزرگ جغد سردش است. از کوله چیزی بده که گرمش کند.", "آخیش! گرم شدم، ممنون عزیزم.", "این گرم نمی‌کند."),
            ], 120),
            section("c5s4", "تلسکوپ", "telescope", "مادربزرگ جغد می‌خواهد ستاره‌ها را نشانت بدهد.", [
                rotate("tube", 2, "مقوا را لوله کن.", sound=S + "rustle.mp3"),
                order(["lens", "lens", "lens"], "عدسی‌ها را از بزرگ به کوچک بگذار."),
                rotate("telescope", 2, "تلسکوپ را تنظیم کن تا تصویر واضح شود.", sound=S + "gear.mp3"),
            ], 110, secret="magnet"),
        ],
    },
    {
        "id": "c6", "title": "گروه موسیقی میمی", "friend": "cat", "bg": "stage", "color": "#A855F7",
        "ambient": "audio/ambient/stage.ogg",
        "intro": "میمی می‌خواهد در جشن بخواند، اما سازهای گروه در طوفان شکسته‌اند.",
        "film": ["طبل: بوم بوم!", "زایلوفون: زیر و بم", "نی: فووو", "و آهنگ جشن با همه‌ی سازها!"],
        "next": "پل شهر شکسته و اتوبوس لاکی خراب است...",
        "sections": [
            section("c6s1", "طبل", "drum", "اول یک طبل محکم بسازیم!", [
                use("clay_bowl", "drum_skin", "برای بدنه‌ی طبل یک کاسه لازم داریم.", "این کاسه عالی است!", "این کاسه نیست."),
                assemble("drum", [("drum_skin", .5, .3)], "پوست طبل را روی کاسه بکش.", "drum"),
                tap("drum", 5, "طناب‌ها را سفت کن. هر بار بزن!", I + "drum_tom.mp3"),
            ], 90, secret="drill"),
            section("c6s2", "زایلوفون", "xylophone", "زایلوفون تیغه‌های رنگی دارد.", [
                order(["bar_red", "bar_red", "bar_red", "bar_red"], "تیغه‌ها را از بلند به کوتاه بچین.", sound=I + "xylo_c4.mp3"),
                use("hammer", "q_nail", "تیغه‌ها با میخ به پایه وصل می‌شوند. چه وسیله‌ای لازم است؟", "تق تق!", "با این نمی‌شود میخ زد."),
                rhythm([("bar_red", I + "xylo_c4.mp3"), ("bar_red", I + "xylo_e4.mp3"), ("bar_red", I + "xylo_g4.mp3")], "آهنگ میمی را تکرار کن!", rounds=2),
            ], 110),
            section("c6s3", "نی", "flute", "نی صدای پرنده‌ها را دارد.", [
                cut("reed", "نی را ببُر.", lines=1, result="flute"),
                collect("flute", 4, "جای سوراخ‌ها را لمس کن.", sound="audio/ui/pop.mp3"),
                timing("flute", "فوت کن... حالا بزن!", sound=I + "flute.mp3"),
            ], 90, secret="saw"),
            section("c6s4", "آهنگ جشن", "song", "با سازهایی که ساختی آهنگ جشن را بسازیم!", [
                rhythm([("drum", I + "drum_tom.mp3"), ("xylophone", I + "xylo_e4.mp3"), ("flute", I + "flute.mp3")], "آهنگ را تکرار کن. اول گوش کن!", rounds=3),
            ], 90),
        ],
    },
    {
        "id": "c7", "title": "شهر و راننده لاکی", "friend": "turtle", "bg": "city", "color": "#F0524F",
        "ambient": "audio/ambient/street.ogg",
        "intro": "پل شهر شکسته و اتوبوس لاکی خراب شده. هیچ‌کس نمی‌تواند به جشن برسد!",
        "film": ["پل دوباره ساخته شد", "چراغ راهنمایی: قرمز بایست، سبز برو", "اتوبوس روشن شد: بوق بوق!", "و همه کارت دعوت گرفتند!"],
        "next": "همه آماده‌اند... وقت جشن بزرگ است!",
        "sections": [
            section("c7s1", "تعمیر پل", "bridge", "پل شکسته! ماشین‌ها نمی‌توانند رد شوند.", [
                use("cart", "plank", "تخته‌ها سنگین‌اند. با چه بیاوریمشان؟", "گاری تخته‌ها را آورد!", "این بار نمی‌برد."),
                count("plank", 3, "bridge", "تخته‌ها را در جاهای خالی پل بگذار."),
                use("hammer", "q_nail", "تخته‌ها را با چه محکم کنیم؟", "تق تق! پل محکم شد.", "با این نمی‌شود میخ زد."),
            ], 110, secret="drill"),
            section("c7s2", "چراغ راهنمایی", "traffic_light", "چراغ راهنمایی خاموش است و ماشین‌ها گیج شده‌اند.", [
                order(["light_red", "light_yellow", "light_green"], "چراغ‌ها را به ترتیب بچین: قرمز، زرد، سبز."),
                use("paints", "traffic_light", "رنگ چراغ‌ها رفته! چه چیزی رنگ دارد؟", "رنگی شد!", "این رنگ ندارد."),
                tap("traffic_light", 3, "چراغ را عوض کن: قرمز، زرد، سبز!", "audio/ui/toggle.mp3"),
            ], 100),
            section("c7s3", "تعمیر اتوبوس", "bus", "اتوبوس لاکی پنچر و کثیف و بی‌بنزین است!", [
                rotate("tire", 2, "پیچ‌های لاستیک نو را ببند.", sound=S + "gear.mp3"),
                scrub("bus", "اتوبوس را بشور. گل‌ها را پاک کن!"),
                pour("fuel", "bus", "باک را پر کن.", color="#E53935"),
                rotate("car_key", 2, "حالا روشنش کن!", sound=S + "engine.mp3", result="bus"),
            ], 130, secret="wrench"),
            section("c7s4", "کارت دعوت", "invitation", "باید همه را به جشن دعوت کنیم!", [
                puzzle("invitation", "عکس دوستان را روی کارت درست کن."),
                count("letter", 3, "mailbox", "نامه‌ها را در صندوق بینداز.", sound="audio/ui/page.mp3"),
                use("toy_car", "q_travel", "خانه‌ها دورند. با چه نامه‌ها را برسانیم؟", "برووووم! نامه‌ها رسیدند.", "این حرکت نمی‌کند."),
                trace("toy_car", "ماشین را در مسیر بران.", shape="zigzag"),
            ], 130, secret="magnet"),
        ],
    },
    {
        "id": "c8", "title": "جشن بزرگ جنگل", "friend": "bear", "bg": "festival", "color": "#FFC83D",
        "ambient": "audio/ambient/festival.ogg",
        "intro": "همه‌چیز آماده است! با چیزهایی که ساختی جشن بزرگ جنگل را برپا کنیم.",
        "film": ["میز جشن پر از غذاهای تو", "میدان با فانوس و پرچم‌های تو", "کنسرت با سازهای تو", "و تو قهرمان جنگل شدی!"],
        "next": "",
        "sections": [
            section("c8s1", "میز جشن", "feast", "مهمان‌ها گرسنه‌اند! هر کدام غذای دلخواهش را می‌خواهد.", [
                serve([("bear", "cake"), ("bunny", "juice"), ("owl", "soup"), ("squirrel", "sandwich")], "به هر مهمان غذای دلخواهش را بده."),
            ], 90),
            section("c8s2", "تزئین میدان", "decorations", "میدان جشن را قشنگ کنیم!", [
                serve([("parrot", "lantern"), ("cat", "mask"), ("bunny", "flower_pot")], "هر تزئین را به دوستی بده که می‌خواهد."),
                count("flag", 4, "bunting", "پرچم‌ها را آویزان کن."),
            ], 100),
            section("c8s3", "کنسرت", "concert", "وقت کنسرت میمی است!", [
                serve([("cat", "drum"), ("parrot", "xylophone"), ("owl", "flute")], "سازها را به نوازنده‌ها بده."),
                rhythm([("drum", I + "drum_tom.mp3"), ("xylophone", I + "xylo_e4.mp3"), ("flute", I + "flute.mp3")], "با گروه بنواز!", rounds=3),
            ], 110),
            section("c8s4", "جشن نهایی", "medal", "آخرین کار: مهمان‌ها را بیاوریم و آتش‌بازی کنیم!", [
                use("bus", "q_travel", "مهمان‌ها دورند. با چه بیاوریمشان؟", "بوق بوق! همه رسیدند.", "این همه را نمی‌آورد."),
                use("telescope", "q_sky", "برای دیدن نمایش ستاره‌ها چه لازم است؟", "وای! ستاره‌ها!", "با این نمی‌شود دور را دید."),
                collect("firework", 5, "آتش‌بازی کن! روی آسمان بزن.", sound="audio/ui/whoosh.mp3"),
            ], 120),
        ],
    },
]

# Star Workshop: a kit opens itself when the total stars reach [stars]. Same section format.
KITS = [
    section("k_bubbles", "حباب‌ساز", "bubbles", "بیا یک حباب‌ساز بسازیم!", [
        pour("soap_bottle", "bowl_mix", "صابون را در کاسه بریز.", color="#B3E5FC"),
        rotate("bowl_mix", 2, "هم بزن.", result="bubbles"),
        collect("bubbles", 6, "حباب‌ها را بترکان!", sound=S + "bloop.mp3"),
    ], 80),
    section("k_necklace", "گردنبند مهره‌ای", "necklace", "یک گردنبند رنگی بسازیم.", [
        count("bead", 6, "necklace", "مهره‌ها را به نخ بکش.", sound="audio/ui/chime.mp3"),
        paint("necklace", "مهره‌ها را رنگ کن.", parts=4),
    ], 80),
    section("k_kite", "بادبادک", "kite", "روز بادی است! بادبادک بسازیم.", [
        cut("paper", "کاغذ بادبادک را ببُر.", lines=2),
        paint("kite", "بادبادک را رنگ کن.", parts=4),
        trace("kite", "بادبادک را در باد بالا ببر.", shape="wave"),
    ], 100),
    section("k_robot", "ربات", "robot", "یک ربات دوست بسازیم!", [
        assemble("robot", [("robot_head", .5, .25), ("robot_body", .5, .6)], "سر و بدنه‌ی ربات را وصل کن.", "robot"),
        count("battery", 2, "robot", "باتری‌ها را بگذار.", sound=S + "gear.mp3"),
        paint("robot", "ربات را رنگ کن.", parts=4),
        trace("robot", "ربات را تا گل راه ببر.", shape="zigzag"),
    ], 120),
    section("k_dollhouse", "خانه‌ی عروسکی", "dollhouse", "یک خانه‌ی کوچک برای عروسک‌ها!", [
        count("box", 4, "dollhouse", "اتاق‌ها را روی هم بچین.", sound=S + "thunk.mp3"),
        paint("dollhouse", "دیوارها را رنگ کن.", parts=4),
        tap("bulb", 3, "چراغ اتاق‌ها را روشن کن.", S + "light_switch.mp3"),
    ], 110),
    section("k_rocket", "موشک", "rocket", "به فضا برویم!", [
        assemble("rocket", [("tube", .5, .5)], "بدنه‌ی موشک را بگذار.", "rocket"),
        paint("rocket", "موشک را رنگ کن.", parts=4),
        order(["star", "star", "star", "star", "star"], "شمارش معکوس: ستاره‌ها را از بزرگ به کوچک بزن!"),
        collect("star", 5, "در فضا ستاره جمع کن.", sound="audio/ui/sparkle.mp3"),
    ], 130),
    section("k_submarine", "زیردریایی", "submarine", "زیر دریا چه خبر است؟", [
        assemble("submarine", [("lens", .62, .45)], "پنجره‌ی زیردریایی را بگذار.", "submarine"),
        paint("submarine", "زیردریایی را رنگ کن.", parts=3),
        dark("fish", 4, "با چراغ زیردریایی ماهی‌ها را پیدا کن."),
    ], 120),
    section("k_train", "قطار", "train", "چووو چووو! یک قطار بسازیم.", [
        count("rail", 5, "train", "ریل‌ها را بچین.", sound=S + "thunk.mp3"),
        count("wheel", 4, "train", "چرخ‌های قطار را بگذار.", sound=S + "gear.mp3"),
        paint("train", "قطار را رنگ کن.", parts=4),
        trace("train", "قطار را روی ریل ببر.", shape="wave"),
    ], 130),
]
KIT_STARS = {"k_bubbles": 5, "k_necklace": 10, "k_kite": 18, "k_robot": 28, "k_dollhouse": 38,
             "k_rocket": 50, "k_submarine": 65, "k_train": 80}

# Tool shop: tools bought with coins, each unlocking recipes (short sections).
TOOLS = [
    {"id": "magnifier", "title": "ذره‌بین", "price": 30, "sound": "audio/ui/sparkle.mp3",
     "safety": "ذره‌بین را هیچ‌وقت رو به خورشید نگیر.",
     "recipes": [section("r_bug_book", "دفترچه‌ی حشره‌ها", "bug_book", "با ذره‌بین حشره‌ها را پیدا کنیم!", [
         dark("ladybug", 4, "حشره‌های کوچک را با ذره‌بین پیدا کن."),
     ], 60)]},
    {"id": "saw", "title": "اره", "price": 40, "sound": S + "saw.mp3",
     "safety": "با اره همیشه با یک بزرگ‌تر کار می‌کنیم.",
     "recipes": [section("r_bird_house", "خانه‌ی پرنده", "bird_house", "برای پرنده‌ها خانه بسازیم.", [
         cut("plank", "تخته را با اره ببُر.", lines=2),
         count("plank", 3, "bird_house", "دیوارها را بچین.", sound=S + "thunk.mp3"),
         paint("bird_house", "خانه را رنگ کن.", parts=3),
     ], 90)]},
    {"id": "glue_gun", "title": "چسب‌تفنگی", "price": 50, "sound": S + "squeak.mp3",
     "safety": "سر چسب‌تفنگی داغ است؛ به آن دست نمی‌زنیم.",
     "recipes": [section("r_photo_frame", "قاب عکس", "photo_frame", "یک قاب برای عکس یادگاری!", [
         count("star", 4, "photo_frame", "ستاره‌ها را دور قاب بچسبان.", sound="audio/ui/pop.mp3"),
         paint("photo_frame", "قاب را رنگ کن.", parts=4),
     ], 70)]},
    {"id": "big_oven", "title": "فر بزرگ", "price": 60, "sound": S + "kettle.mp3",
     "safety": "در فر داغ است؛ با دستکش بازش می‌کنیم.",
     "recipes": [
         section("r_pizza", "پیتزا", "pizza", "بیا پیتزا بپزیم!", [
             count("tomato", 3, "dough", "گوجه‌ها را روی خمیر بگذار."),
             count("cheese", 2, "dough", "پنیر بریز."),
             timing("big_oven", "وقتی پنیر آب شد بزن!", sound=S + "sizzle.mp3", result="pizza"),
         ], 80),
         section("r_cookie", "کلوچه", "cookie", "کلوچه‌ی تازه!", [
             rotate("bowl_mix", 2, "خمیر کلوچه را هم بزن."),
             timing("big_oven", "وقتی طلایی شد بزن!", sound=S + "kettle.mp3", result="cookie"),
         ], 70),
     ]},
    {"id": "sewing_machine", "title": "چرخ خیاطی", "price": 70, "sound": S + "sewing.mp3",
     "safety": "انگشت‌ها را از سوزن دور نگه می‌داریم.",
     "recipes": [section("r_rag_doll", "عروسک پارچه‌ای", "rag_doll", "یک عروسک نرم بدوزیم.", [
         tap("sewing_machine", 8, "پدال را بزن تا چرخ بدوزد: تق تق تق!", S + "sewing.mp3"),
         paint("rag_doll", "لباس عروسک را رنگ کن.", parts=4),
     ], 80)]},
    {"id": "drill", "title": "دریل", "price": 80, "sound": S + "drill.mp3",
     "safety": "دریل را فقط بزرگ‌ترها روشن می‌کنند و ما کمک می‌کنیم.",
     "recipes": [section("r_windmill", "آسیاب بادی", "windmill", "یک آسیاب بادی بسازیم.", [
         tap("drill", 3, "با دریل سوراخ کن.", S + "drill.mp3"),
         assemble("windmill", [("flag", .5, .3)], "پره‌ها را وصل کن.", "windmill"),
         rotate("windmill", 2, "فوت کن تا بچرخد!", sound="audio/ambient/wind.ogg"),
     ], 80)]},
    {"id": "wrench", "title": "آچار", "price": 90, "sound": S + "gear.mp3",
     "safety": "آچار را محکم و آرام می‌چرخانیم.",
     "recipes": [section("r_bicycle", "دوچرخه", "bicycle", "یک دوچرخه برای پوپو!", [
         count("wheel", 2, "bicycle", "چرخ‌ها را وصل کن.", sound=S + "gear.mp3"),
         rotate("wrench", 3, "پیچ‌ها را با آچار سفت کن.", sound=S + "gear.mp3", result="bicycle"),
         paint("bicycle", "دوچرخه را رنگ کن.", parts=3),
     ], 90)]},
    {"id": "magnet", "title": "آهن‌ربا", "price": 100, "sound": S + "snap.mp3",
     "safety": "آهن‌ربا را نزدیک گوشی و تلویزیون نمی‌بریم.",
     "recipes": [section("r_magnet_fish", "ماهیگیری آهن‌ربایی", "magnet_fish", "بیا ماهیگیری کنیم!", [
         sort(["nail", "screw"], ["paper", "bread"], "چیزهایی که آهن‌ربا می‌کشد را جدا کن.", "آهنی", "غیرآهنی"),
         collect("fish", 4, "ماهی‌های آهنی را بگیر!", sound=S + "splash.mp3"),
     ], 80)]},
]

# Play room: two things together do something new (once: 25 coins).
COMBOS = [
    (["juice", "cake"], "مهمانی کوچک! دوستان آمدند.", "giggle"),
    (["robot", "watering_can"], "ربات گل‌ها را آب داد!", "splash"),
    (["drum", "xylophone"], "یک آهنگ دونفره!", "music"),
    (["lantern", "tent"], "چادر شب روشن شد.", "light"),
    (["bread", "cheese_none"], "", ""),
    (["toy_car", "invitation"], "ماشین نامه‌ها را رساند.", "drive"),
    (["flashlight", "telescope"], "تماشای شب پرستاره!", "sky"),
    (["kite", "windmill"], "باد هر دو را چرخاند!", "wind"),
    (["submarine", "magnet_fish"], "ماهی‌گیری زیر آب!", "splash"),
    (["soup", "bread"], "ناهار گرم و خوشمزه!", "eat"),
    (["mask", "concert"], "رقص با ماسک!", "music"),
    (["rocket", "telescope"], "موشک در آسمان دیده شد!", "sky"),
    (["flower_pot", "bird_house"], "پرنده‌ها در باغ لانه ساختند.", "bird"),
    (["paints", "photo_frame"], "یک نقاشی قاب‌شده!", "sparkle"),
    (["bicycle", "map"], "گردش با دوچرخه در جنگل!", "drive"),
]
COMBOS = [c for c in COMBOS if c[1]]

# Daily orders: a friend asks for something with a tag.
ORDERS = [
    ("bunny", "drink", "بانی تشنه است. چی بهش بدیم؟"),
    ("bear", "sweet", "خاله خرسی یک چیز شیرین می‌خواهد."),
    ("owl", "warm", "مادربزرگ جغد سردش است."),
    ("cat", "low", "میمی یک ساز با صدای بم می‌خواهد."),
    ("cat", "high", "میمی یک ساز با صدای زیر می‌خواهد."),
    ("squirrel", "light", "آقا سنجاب در تاریکی چیزی را گم کرده."),
    ("turtle", "vehicle", "لاکی یک وسیله‌ی نقلیه می‌خواهد."),
    ("parrot", "pretty", "کوکو یک چیز قشنگ برای تزئین می‌خواهد."),
    ("squirrel", "tool", "آقا سنجاب باید میخ بزند."),
    ("bunny", "water", "گل‌های بانی تشنه‌اند."),
    ("bear", "food", "خاله خرسی گرسنه است."),
    ("owl", "find", "مادربزرگ جغد راه را گم کرده."),
    ("parrot", "music", "کوکو دلش موسیقی می‌خواهد."),
]


def voice_lines(game) -> list[dict]:
    """Every sentence Popo says in the game. The id doubles as the file name (dots → _)."""
    out: list[dict] = []

    def add(id, text, screen):
        out.append({"id": id, "text": text, "event": id, "screen": screen, "file": f"voice/{id.replace('.', '_')}.mp3"})

    def sec_lines(s, screen):
        add(f"{s['id']}.mission", s["mission"], screen)
        for i, st in enumerate(s["steps"]):
            add(f"{s['id']}.s{i + 1}", st["say"], screen)
            if st["engine"] == "use":
                add(f"{s['id']}.s{i + 1}.done", st["done"], screen)
                add(f"{s['id']}.s{i + 1}.why", st["why"], screen)
        it = ITEMS[s["makes"]]
        add(f"item.{it['id']}.made", f"آفرین! {it['title']} آماده شد!", screen)

    for ch in game["chapters"]:
        add(f"{ch['id']}.intro", ch["intro"], "chapter")
        for i, line in enumerate(ch["film"]):
            add(f"{ch['id']}.film.{i + 1}", line, "film")
        if ch["next"]:
            add(f"{ch['id']}.next", ch["next"], "film")
        for s in ch["sections"]:
            sec_lines(s, ch["id"])
    for k in game["kits"]:
        sec_lines(k, "workshop")
    for t in game["tools"]:
        add(f"tool.{t['id']}.safety", t["safety"], "shop")
        for r in t["recipes"]:
            sec_lines(r, "shop")
    for it in ITEMS.values():
        add(f"item.{it['id']}.use", it["use"], "discover")
        add(f"item.{it['id']}.quiz", it["quiz"]["q"], "discover")
        if it["taste"]:
            add(f"item.{it['id']}.taste", f"مزه‌اش {it['taste']} است!", "discover")
    for i, (_, _, text) in enumerate(ORDERS):
        add(f"order.{i + 1}", text, "playroom")
    for i, (_, text, _) in enumerate(COMBOS):
        add(f"combo.{i + 1}", text, "playroom")
    for id, text in [
        ("game.hint.1", "این‌جا را ببین..."),
        ("game.hint.2", "بیا با هم انجامش بدهیم."),
        ("game.wrong", "نه این یکی نه؛ دوباره امتحان کن!"),
        ("game.quiz.right", "درست گفتی!"),
        ("game.quiz.wrong", "نه عزیزم، به این دقت کن."),
        ("game.play", "حالا باهاش بازی کن!"),
        ("game.backpack", "گذاشتمش در کوله‌پشتی."),
        ("game.stars.3", "عالی بود! سه ستاره!"),
        ("game.stars.2", "خیلی خوب بود!"),
        ("game.stars.1", "تمامش کردی، آفرین!"),
        ("game.fast", "چه سریع!"),
        ("game.locked", "این بخش برای بعد است. اول بخش قبلی را تمام کن."),
        ("game.coins.low", "سکه‌هایت کم است. بیا یک بخش را دوباره بازی کنیم!"),
        ("game.secret", "یک چیز پنهان پیدا کردی!"),
        ("game.daily", "جایزه‌ی امروز! سکه گرفتی."),
        ("home.hello", "سلام! امروز چی بسازیم؟"),
        ("workshop.hello", "به کارگاه ستاره خوش آمدی! با ستاره‌هایت کیت‌های تازه باز می‌شوند."),
        ("shop.hello", "این‌جا با سکه ابزار می‌خری و چیزهای تازه می‌سازی."),
        ("shop.bought", "ابزار تازه! بیا ببینیم چطور کار می‌کند."),
        ("playroom.hello", "این اتاق بازی توست. همه‌ی ساخته‌هایت این‌جاست!"),
        ("playroom.combo", "یک ترکیب تازه کشف کردی!"),
        ("playroom.order.done", "دقیقاً همین را می‌خواستم! ممنون!"),
        ("playroom.order.wrong", "این را نمی‌خواهم؛ یک چیز دیگر بده."),
        ("film.end", "یک تکه‌ی تازه از نقشه‌ی جشن روشن شد!"),
        ("kit.open", "یک کیت تازه باز شد!"),
    ]:
        add(id, text, "game")
    return out


def main():
    game = {
        "version": 1,
        "friends": {k: {"name": n, "emoji": e} for k, (n, e, _) in FRIENDS.items()},
        "items": ITEMS,
        "chapters": CHAPTERS,
        "kits": [{**k, "stars": KIT_STARS[k["id"]]} for k in KITS],
        "tools": TOOLS,
        "combos": [{"items": a, "text": t, "fx": fx} for a, t, fx in COMBOS],
        "orders": [{"friend": f, "tag": tag, "text": t} for f, tag, t in ORDERS],
        "art": {k: v[0] for k, v in sorted(ART.items())},
    }
    # every picture a step, item or quiz shows must have an entry
    used: set[str] = set(ITEMS)
    for s in [x for ch in CHAPTERS for x in ch["sections"]] + KITS + [r for t in TOOLS for r in t["recipes"]]:
        for st in s["steps"]:
            for k in ("target", "result", "base", "into", "source", "need", "spot"):
                if isinstance(st.get(k), str) and not st[k].startswith("#"):
                    used.add(st[k])
            for k in ("distract", "good", "bad", "items"):
                used.update(st.get(k, []))
            used.update(p["art"] for p in st.get("parts", []) + st.get("pads", []))
            used.update(p["item"] for p in st.get("pairs", []))
            for p in st.get("pairs", []):
                assert p["item"] in ITEMS, p
            if st["engine"] in ("use",):
                assert st["need"] in ITEMS, st["need"]
    for it in ITEMS.values():
        used.update(o["art"] for o in it["quiz"]["options"])
    used.update(t["id"] for t in TOOLS)
    missing = sorted(u for u in used if u not in ART and u not in ITEMS)
    assert not missing, f"no picture for {missing}"
    missing_items = sorted(i for i in ITEMS if i not in ART)
    assert not missing_items, f"no picture for items {missing_items}"

    (ROOT / "assets/content/game.json").write_text(json.dumps(game, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")

    # voice lines: keep everything not generated here (app.*, praise.*, idle.*, …) and their fields
    vpath = ROOT / "assets/content/voice_lines.json"
    voice = json.loads(vpath.read_text(encoding="utf-8"))
    mine = voice_lines(game)
    ids = {l["id"] for l in mine}
    prefixes = tuple(f"{p}." for p in ["c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8", "k_bubbles", "k_necklace", "k_kite",
                                       "k_robot", "k_dollhouse", "k_rocket", "k_submarine", "k_train", "item", "tool", "order",
                                       "combo", "game", "home", "workshop", "shop", "playroom", "film", "kit"]) + ("r_",)
    old = {l["id"]: l for l in voice["lines"]}
    kept = [l for l in voice["lines"] if l["id"] not in ids and not l["id"].startswith(prefixes)]
    for l in mine:  # a respelling added in the studio survives a rebuild
        if old.get(l["id"], {}).get("spoken") and old[l["id"]]["text"] == l["text"]:
            l["spoken"] = old[l["id"]]["spoken"]
    voice["lines"] = kept + mine
    vpath.write_text(json.dumps(voice, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")

    (ROOT / "art").mkdir(exist_ok=True)
    (ROOT / "art/game_art.json").write_text(json.dumps({
        "objects": {k: v[1] for k, v in ART.items()},  # story order: early chapters render first
        "friends": {k: v[2] for k, v in FRIENDS.items()},
    }, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    n_sec = sum(len(c["sections"]) for c in CHAPTERS)
    print(f"{len(CHAPTERS)} chapters, {n_sec} sections, {len(ITEMS)} items, {len(KITS)} kits, {len(TOOLS)} tools, "
          f"{len(ART)} pictures, {len(mine)} new voice lines ({len(kept)} kept)")


if __name__ == "__main__":
    main()
