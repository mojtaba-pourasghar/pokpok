#!/usr/bin/env python3
"""The whole POPO story in one place: chapters, sections, the things the child makes, kits, shop
tools, play-room combos and orders. Writes

    assets/content/game.json         what the app plays
    assets/content/voice_lines.json  every line Popo says (the studio reads this; recorded files stay),
                                     with its vowelled form from tools/content/spoken_fa.json

Every picture id is a living cartoon drawn in code (lib/ui/toons); the emoji here is only the
fallback for an id that has no cartoon yet (the content test requires one for every id).

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
    "catch", "feed", "stack", "blow", "steer", "connect", "memory", "whack",
}

# ── pictures: id → emoji fallback (the drawing itself is in lib/ui/toons) ─────────────────────────
ART: dict[str, str] = {}


def art(id: str, emoji: str) -> str:
    ART.setdefault(id, emoji)
    return id


for _id, _e in [
    # fruit, food, kitchen
    ("orange", "🍊"),
    ("orange_half", "🍊"),
    ("juicer", "🍋"),
    ("glass", "🥛"),
    ("juice", "🧃"),
    ("flour", "🌾"),
    ("water_jug", "💧"),
    ("bowl_mix", "🥣"),
    ("dough", "🫓"),
    ("oven", "🔥"),
    ("bread", "🍞"),
    ("carrot", "🥕"),
    ("potato", "🥔"),
    ("tomato", "🍅"),
    ("rotten_apple", "🍂"),
    ("old_shoe", "👞"),
    ("pot", "🍲"),
    ("soup", "🍲"),
    ("egg", "🥚"),
    ("eggs", "🥚"),
    ("candle", "🕯️"),
    ("cake", "🎂"),
    ("milk", "🥛"),
    ("fridge", "🧊"),
    ("cheese", "🧀"),
    ("lettuce", "🥬"),
    ("sandwich", "🥪"),
    ("honey", "🍯"),
    # garden, farm
    ("watering_can", "🚿"),
    ("can_body", "🪣"),
    ("can_spout", "🚿"),
    ("can_handle", "➰"),
    ("well", "⛲"),
    ("seed", "🌰"),
    ("flower_pot", "🌷"),
    ("empty_pot", "🪴"),
    ("sprout", "🌱"),
    ("bee", "🐝"),
    ("hay", "🌾"),
    ("nest", "🪺"),
    ("hen", "🐔"),
    ("cow", "🐄"),
    ("bucket", "🪣"),
    # workshop
    ("hammer", "🔨"),
    ("hammer_head", "🔩"),
    ("hammer_handle", "🪵"),
    ("screw", "🔩"),
    ("nail", "📍"),
    ("plank", "🪵"),
    ("flashlight", "🔦"),
    ("battery", "🔋"),
    ("bulb", "💡"),
    ("cart", "🛒"),
    ("wheel", "⚙️"),
    ("box", "📦"),
    ("toy_car", "🚗"),
    ("car_body", "🚙"),
    ("car_key", "🗝️"),
    ("junk_spoon", "🥄"),
    ("junk_sock", "🧦"),
    # art studio
    ("brush", "🖌️"),
    ("bristles", "🖌️"),
    ("paints", "🎨"),
    ("clay", "🟤"),
    ("clay_bowl", "🥣"),
    ("pottery_wheel", "🏺"),
    ("paper", "📄"),
    ("scissors", "✂️"),
    ("lantern", "🏮"),
    ("mask", "🎭"),
    ("bunting", "🎏"),
    ("flag", "🚩"),
    # night forest
    ("map_piece", "🗺️"),
    ("map", "🗺️"),
    ("tent", "⛺"),
    ("tent_cloth", "🟧"),
    ("pole", "🥢"),
    ("peg", "📌"),
    ("firefly", "✨"),
    ("firefly_jar", "🫙"),
    ("baby_owl", "🦉"),
    ("telescope", "🔭"),
    ("lens", "🔍"),
    ("tube", "🧻"),
    ("moon", "🌙"),
    ("star", "⭐"),
    # music
    ("drum", "🥁"),
    ("drum_skin", "⚪"),
    ("xylophone", "🎹"),
    ("bar_red", "🟥"),
    ("flute", "🪈"),
    ("reed", "🎋"),
    ("song", "🎶"),
    ("note", "🎵"),
    # city
    ("bridge", "🌉"),
    ("traffic_light", "🚦"),
    ("light_red", "🔴"),
    ("light_yellow", "🟡"),
    ("light_green", "🟢"),
    ("bus", "🚌"),
    ("tire", "🛞"),
    ("fuel", "⛽"),
    ("letter", "✉️"),
    ("mailbox", "📮"),
    ("invitation", "💌"),
    # festival
    ("feast", "🍱"),
    ("decorations", "🎊"),
    ("concert", "🎤"),
    ("medal", "🏅"),
    ("firework", "🎆"),
    # kits
    ("bubbles", "🫧"),
    ("soap_bottle", "🧴"),
    ("necklace", "📿"),
    ("bead", "🔵"),
    ("kite", "🪁"),
    ("robot", "🤖"),
    ("robot_head", "🤖"),
    ("robot_body", "🟦"),
    ("dollhouse", "🏠"),
    ("rocket", "🚀"),
    ("submarine", "🟡"),
    ("fish", "🐟"),
    ("train", "🚂"),
    ("rail", "🛤️"),
    # shop tools and recipes
    ("magnifier", "🔍"),
    ("ladybug", "🐞"),
    ("bug_book", "📔"),
    ("saw", "🪚"),
    ("bird_house", "🏡"),
    ("glue_gun", "🧴"),
    ("photo_frame", "🖼️"),
    ("big_oven", "♨️"),
    ("pizza", "🍕"),
    ("cookie", "🍪"),
    ("sewing_machine", "🧵"),
    ("rag_doll", "🧸"),
    ("drill", "🛠️"),
    ("windmill", "🌬️"),
    ("wrench", "🔧"),
    ("bicycle", "🚲"),
    ("magnet", "🧲"),
    ("magnet_fish", "🎣"),
    # quiz pictures
    ("q_thirsty", "🥵"),
    ("q_sleep", "😴"),
    ("q_paint", "🎨"),
    ("q_hungry", "😋"),
    ("q_cold", "🥶"),
    ("q_flowers", "🌼"),
    ("q_dark", "🌑"),
    ("q_carry", "📦"),
    ("q_nail", "🪵"),
    ("q_travel", "🛣️"),
    ("q_music", "🎵"),
    ("q_rain", "🌧️"),
    ("q_lost", "❓"),
    ("q_sky", "🌌"),
    ("q_party", "🎉"),
    ("q_swim", "🏊"),
    ("q_cross", "🚸"),
    ("q_eat", "🍽️"),
    ("q_wear", "😺"),
    ("q_water", "💧"),
    ("rock", "🪨"),
    ("cone", "🚧"),
    ("balloon", "🎈"),
]:
    art(_id, _e)

# ── characters ──────────────────────────────────────────────────────────────────────────────────
FRIENDS = {
    "bear": ("خاله خرسی", "🐻"),
    "bunny": ("بانی", "🐰"),
    "squirrel": ("آقا سنجاب", "🐿️"),
    "parrot": ("کوکو", "🦜"),
    "owl": ("مادربزرگ جغد", "🦉"),
    "cat": ("میمی", "🐱"),
    "turtle": ("لاکی", "🐢"),
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


def catch(target, n, say, distract=(), sound=None):
    """Things fall from the top; move the basket and catch only the right ones."""
    return step("catch", say, target=target, count=n, distract=list(distract), sound=sound)


def feed(friend, food, say, n=None, distract=(), sound=None):
    """A friend asks for [food] in turn; drag (or tap) it from the plate to their mouth."""
    return step("feed", say, friend=friend, food=list(food), count=n or max(3, len(food)), distract=list(distract), sound=sound)


def stack(target, n, say, sound=None):
    """A crane swings a block; tap to drop it on the tower."""
    return step("stack", say, target=target, count=n, sound=sound)


def blow(target, say, mode="out", n=1, result=None, sound=None):
    """Hold to blow. mode: out (candle flames), spin, inflate, cool (steam), music (notes)."""
    return step("blow", say, target=target, mode=mode, count=n, result=result or target, sound=sound)


def steer(target, good, bad, n, say, sound=None):
    """Three lanes: tap left/right to switch, collect [good], avoid [bad]."""
    return step("steer", say, target=target, good=list(good), bad=list(bad), count=n, sound=sound)


def connect(target, say, dots=6, shape="circle"):
    """Dot-to-dot in number order; the picture appears at the end."""
    return step("connect", say, target=target, dots=dots, shape=shape)


def memory(items, say):
    """Flip cards and find the pairs."""
    return step("memory", say, items=list(items))


def whack(target, n, say, distract=(), sound=None):
    """Things pop out of holes; tap only the right ones."""
    return step("whack", say, target=target, count=n, distract=list(distract), sound=sound)


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
     tags=["pretty", "plant"])
item("eggs", "تخم‌مرغ", "food", S + "cluck.mp3", "مرغ تخم می‌گذارد؛ با تخم‌مرغ کیک و نیمرو درست می‌کنیم.",
     ("تخم‌مرغ از کجا می‌آید؟", [("hen", "مرغ"), ("cow", "گاو"), ("bee", "زنبور")], 0),
     taste="نرم و خوشمزه", tags=["food"])
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
     taste="جورواجور و خوشمزه", tags=["food", "party"])
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
            "targetSec": max(target, 30 * len(steps)), "secret": secret}


CHAPTERS = [
    {
        "id": "c1", "title": "آشپزخانه‌ی خاله خرسی", "friend": "bear", "bg": "kitchen", "color": "#FF8A1F",
        "ambient": "audio/ambient/kitchen.ogg",
        "intro": "طوفان آشپزخانه‌ی خاله خرسی را به هم ریخته و برای جشن هیچ غذایی نمانده. بیا با هم آشپزی کنیم!",
        "film": ["آب‌پرتقال شیرین و ترش", "نان ترد و گرم", "سوپ داغ و خوشمزه", "و کیک تولد با شمع‌های روشن!"],
        "next": "بانی در باغ تشنه است... بیا برویم پیشش!",
        "sections": [
            section("c1s1", "آب‌پرتقال", "juice", "خاله خرسی تشنه است. بیا برایش آب‌پرتقال درست کنیم!", [
                catch("orange", 4, "پرتقال‌ها از بالا می‌افتند! سبد را با انگشت زیرشان ببر. سیب خراب را نگیر!", distract=["rotten_apple"]),
                collect("orange", 4, "روی پرتقال‌های درخت بزن تا در سبد بپرند. سیب خراب را نچین!", distract=["rotten_apple"]),
                scrub("orange", "پرتقال خاکی است. انگشتت را رویش بکش تا تمیز شود."),
                cut("orange", "انگشتت را روی خط‌چین بکش تا پرتقال نصف شود.", result="orange_half"),
                tap("juicer", 8, "روی آب‌گیری تند تند بزن تا آب پرتقال دربیاید!", S + "squeak.mp3", result="juice"),
                pour("juice", "glass", "پاکت آب‌میوه را نگه دار تا در لیوان بریزد. وقتی به پرچم رسید، ول کن!", color="#FFA726"),
                feed("bear", ["juice"], "خاله خرسی آب‌پرتقال می‌خواهد. آب‌پرتقال را بکش و به دهانش ببر!", n=2, sound=S + "sip.mp3"),
            ], 100, secret="magnifier"),
            section("c1s2", "نان", "bread", "برای ناهار نان لازم داریم. بیا نان بپزیم!", [
                memory(["flour", "egg", "milk", "water_jug"], "کارت‌ها را برگردان و دو تای مثل هم را پیدا کن."),
                pour("flour", "bowl_mix", "کیسه‌ی آرد را نگه دار تا در کاسه بریزد. سر پرچم ول کن!", sound=S + "rustle.mp3", color="#FFF3E0"),
                pour("water_jug", "bowl_mix", "حالا پارچ آب را نگه دار. وقتی آب به پرچم رسید، ول کن!", color="#4FC3F7"),
                tap("dough", 10, "روی خمیر بزن و ورزش بده! هر ضربه نرم‌ترش می‌کند.", S + "thunk.mp3"),
                cut("dough", "انگشتت را روی خط‌چین‌ها بکش و خمیر را تکه‌تکه کن.", lines=2),
                timing("oven", "نان در فر است. وقتی حلقه به جای طلایی رسید، بزن!", sound=S + "kettle.mp3", result="bread"),
                feed("bear", ["bread"], "خاله خرسی نان می‌خواهد. نان گرم را به دهانش ببر.", n=2, sound=S + "crunch.mp3"),
            ], 110, secret="big_oven"),
            section("c1s3", "سوپ سبزیجات", "soup", "باد سرد می‌آید. یک سوپ گرم بپزیم!", [
                catch("carrot", 4, "هویج‌ها می‌افتند! سبد را زیرشان ببر. کفش و سیب خراب را نگیر!", distract=["rotten_apple", "old_shoe"]),
                sort(["carrot", "potato", "tomato"], ["rotten_apple", "old_shoe"], "هر چه روی نوار می‌آید را بکش: سالم‌ها در سبد سبز، خراب‌ها در سطل قرمز.", "سالم", "خراب"),
                scrub("potato", "سیب‌زمینی گلی است. انگشتت را رویش بکش تا تمیز شود."),
                cut("carrot", "انگشتت را روی هر خط‌چین بکش تا هویج خرد شود.", lines=3),
                count("carrot", 3, "pot", "سه تا هویج در قابلمه بینداز. بشمار: یک، دو، سه!", sound=S + "splash.mp3"),
                rotate("pot", 3, "انگشتت را دور قابلمه بچرخان تا سوپ هم بخورد.", result="soup"),
                blow("soup", "سوپ داغ است! دکمه‌ی فوت را نگه دار تا خنک شود.", mode="cool"),
            ], 120),
            section("c1s4", "کیک تولد", "cake", "امروز تولد خاله خرسی است! بیا کیک بپزیم.", [
                tap("egg", 3, "روی تخم‌مرغ بزن تا بشکند و در کاسه بریزد.", S + "snap.mp3", result="bowl_mix"),
                pour("flour", "bowl_mix", "کیسه‌ی آرد را نگه دار تا در کاسه بریزد. سر پرچم ول کن.", sound=S + "rustle.mp3", color="#FFF3E0"),
                rotate("bowl_mix", 3, "انگشتت را دور کاسه بچرخان تا خمیر کیک درست شود.", result="cake"),
                paint("cake", "یک رنگ بردار و روی دایره‌های سفید کیک بزن.", parts=4),
                count("candle", 4, "cake", "چهار شمع روی کیک بگذار. بشمار!", sound="audio/ui/chime.mp3"),
                blow("candle", "تولدت مبارک! دکمه‌ی فوت را نگه دار تا شمع‌ها خاموش شوند.", mode="out", n=4),
                feed("bear", ["cake"], "خاله خرسی کیک می‌خواهد. کیک را به دهانش ببر.", n=2),
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
                use("juice", "q_thirsty", "بانی تشنه است. از کوله‌پشتی چیزی بکش که تشنگی را برطرف کند.", "به به! بانی سرحال شد.", "این برای رفع تشنگی نیست."),
                connect("watering_can", "نقطه‌ها را به ترتیب بزن: یک، دو، سه… ببین چه پیدا می‌شود!", dots=6),
                assemble("watering_can", [("can_body", .5, .6), ("can_spout", .2, .45), ("can_handle", .78, .38)], "تکه‌های آب‌پاش را بکش و روی جای کم‌رنگشان بگذار.", "watering_can"),
                rotate("well", 3, "انگشتت را دور چاه بچرخان تا سطل آب بالا بیاید.", sound=S + "water_tap.mp3"),
                pour("water_jug", "watering_can", "پارچ را نگه دار تا آب‌پاش پر شود. سر پرچم ول کن!", color="#4FC3F7"),
                trace("watering_can", "آب‌پاش را با انگشت روی جاده تا پرچم ببر.", shape="wave"),
            ], 110, secret="magnifier"),
            section("c2s2", "گلدان گل", "flower_pot", "بانی می‌خواهد یک گل قشنگ بکارد.", [
                catch("seed", 3, "دانه‌ها از بالا می‌افتند! سبد را زیرشان ببر. کفش را نگیر!", distract=["old_shoe"]),
                tap("empty_pot", 5, "روی گلدان بزن تا خاکش نرم شود.", S + "rustle.mp3"),
                count("seed", 3, "empty_pot", "سه دانه در گلدان بگذار. بشمار!"),
                use("watering_can", "empty_pot", "دانه‌ها تشنه‌اند! از کوله‌پشتی چیزی بکش که با آن آب بدهیم.", "آفرین! دانه‌ها آب خوردند.", "با این نمی‌شود آب داد."),
                timing("sprout", "جوانه دارد بزرگ می‌شود. وقتی حلقه به جای طلایی رسید، بزن!", sound=S + "grow.mp3", result="flower_pot"),
                paint("flower_pot", "یک رنگ بردار و روی دایره‌های سفید گلدان بزن.", parts=3),
            ], 110),
            section("c2s3", "لانه‌ی مرغ", "eggs", "مرغ‌های بانی لانه ندارند و گم شده‌اند!", [
                collect("hay", 5, "روی کاه‌ها بزن تا در سبد بپرند. کفش را برندار!", distract=["old_shoe"], sound=S + "rustle.mp3"),
                count("hay", 4, "nest", "چهار تا کاه در لانه بگذار. بشمار!"),
                whack("hen", 4, "مرغ‌ها از سوراخ‌ها سر بیرون می‌آورند. زود رویشان بزن! سیب خراب را نزن.", distract=["rotten_apple"], sound=S + "cluck.mp3"),
                feed("hen", ["seed"], "مرغ دانه می‌خواهد. دانه را به نوکش ببر. کفش نه!", n=3, distract=["old_shoe"], sound=S + "cluck.mp3"),
                catch("egg", 4, "تخم‌مرغ‌ها می‌افتند! سبد را زیرشان ببر. کفش را نگیر!", distract=["old_shoe"]),
                count("egg", 3, "nest", "سه تخم‌مرغ در لانه بگذار. بشمار!"),
            ], 100, secret="saw"),
            section("c2s4", "ساندویچ پیک‌نیک", "sandwich", "وقت پیک‌نیک است! یک ساندویچ خوشمزه درست کنیم.", [
                tap("cow", 6, "روی گاو بزن تا شیر بدهد. هر ضربه، کمی شیر!", "audio/animals/cow.mp3", result="milk"),
                rotate("bucket", 3, "انگشتت را دور سطل بچرخان تا شیر پنیر شود.", result="cheese"),
                use("bread", "q_hungry", "برای ساندویچ نان لازم داریم. نان را از کوله‌پشتی بکش.", "نان رسید!", "این نان نیست."),
                scrub("lettuce", "کاهو خاکی است. انگشتت را رویش بکش تا تمیز شود."),
                cut("cheese", "انگشتت را روی خط‌چین‌ها بکش تا پنیر برش بخورد.", lines=2),
                order(["bread", "lettuce", "cheese", "bread"], "به ترتیب بزن: نان، کاهو، پنیر، نان."),
                feed("bunny", ["sandwich"], "بانی ساندویچ می‌خواهد. ساندویچ را به دهانش ببر.", n=2, sound=S + "crunch.mp3"),
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
                collect("hammer_head", 1, "سر چکش را پیدا کن و رویش بزن. قاشق و جوراب نه!", distract=["junk_spoon", "junk_sock"]),
                collect("hammer_handle", 1, "حالا دسته‌ی چوبی را پیدا کن و رویش بزن.", distract=["junk_spoon", "junk_sock"]),
                scrub("hammer_head", "سر چکش کثیف است. انگشتت را رویش بکش تا برق بزند."),
                assemble("hammer", [("hammer_head", .5, .25), ("hammer_handle", .5, .65)], "سر و دسته را بکش و روی جای کم‌رنگشان بگذار.", "hammer"),
                rotate("screw", 2, "انگشتت را دور پیچ بچرخان تا سفت شود.", sound=S + "gear.mp3", result="hammer"),
                whack("nail", 5, "میخ‌ها از سوراخ‌ها بیرون می‌آیند. زود رویشان بزن! جوراب را نزن.", distract=["junk_sock"], sound=S + "hammer.mp3"),
            ], 100, secret="wrench"),
            section("c3s2", "چراغ‌قوه", "flashlight", "گوشه‌ی کارگاه خیلی تاریک است!", [
                catch("battery", 3, "باتری‌ها می‌افتند! سبد را زیرشان ببر. قاشق را نگیر!", distract=["junk_spoon"]),
                memory(["battery", "bulb", "flashlight", "screw"], "کارت‌ها را برگردان و دو تای مثل هم را پیدا کن."),
                assemble("flashlight", [("battery", .35, .5), ("battery", .6, .5)], "باتری‌ها را بکش و روی جای کم‌رنگشان در چراغ‌قوه بگذار.", "flashlight"),
                rotate("bulb", 2, "انگشتت را دور لامپ بچرخان تا پیچ شود.", sound=S + "gear.mp3"),
                tap("flashlight", 1, "روی چراغ‌قوه بزن تا روشن شود!", S + "light_switch.mp3"),
                dark("box", 3, "جایی تاریک است. انگشتت را بکش تا نور جعبه‌های گم‌شده را پیدا کند."),
            ], 100, secret="magnifier"),
            section("c3s3", "گاری", "cart", "جعبه‌ها خیلی سنگین‌اند. یک گاری لازم داریم!", [
                connect("cart", "نقطه‌ها را به ترتیب بزن تا گاری پیدا شود.", dots=6),
                use("hammer", "q_nail", "تخته‌ها باید میخ بخورند. از کوله‌پشتی وسیله‌ی درست را بکش.", "تق تق! تخته‌ها وصل شدند.", "با این نمی‌شود میخ زد."),
                tap("nail", 4, "روی میخ تند تند بزن تا در چوب فرو برود!", S + "hammer.mp3"),
                count("wheel", 2, "cart", "دو چرخ در گاری بگذار. بشمار!", sound=S + "gear.mp3"),
                paint("cart", "یک رنگ بردار و روی دایره‌های سفید گاری بزن.", parts=3),
                stack("box", 4, "جرثقیل جعبه را تکان می‌دهد. وقتی جعبه بالای خط سبز بود، بزن تا بیفتد!", sound=S + "thunk.mp3"),
                steer("cart", ["box"], ["rock"], 4, "چپ یا راست صفحه را بزن تا گاری راهش را عوض کند. جعبه‌ها را بگیر، به سنگ نخور!"),
            ], 100, secret="drill"),
            section("c3s4", "ماشین اسباب‌بازی", "toy_car", "آقا سنجاب یک ماشین قدیمی دارد. بیا درستش کنیم!", [
                puzzle("toy_car", "تکه‌های عکس را بکش و سر جایشان بگذار."),
                count("wheel", 4, "car_body", "چهار چرخ به ماشین بده. بشمار: یک، دو، سه، چهار!", sound=S + "gear.mp3"),
                scrub("toy_car", "ماشین گلی است. انگشتت را رویش بکش تا تمیز شود."),
                paint("toy_car", "یک رنگ بردار و روی دایره‌های سفید ماشین بزن.", parts=3),
                rotate("car_key", 3, "انگشتت را دور کلید بچرخان تا ماشین روشن شود!", sound=S + "engine.mp3", result="toy_car"),
                steer("toy_car", ["star"], ["cone", "rock"], 5, "برووووم! چپ یا راست صفحه را بزن. ستاره‌ها را بگیر، به سنگ و مخروط نخور!", sound="audio/ui/sparkle.mp3"),
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
                assemble("brush", [("bristles", .5, .2), ("brush", .5, .6)], "موهای قلم‌مو را بکش و روی جای کم‌رنگش بگذار.", "brush"),
                memory(["paints", "brush", "paper", "bristles"], "کارت‌ها را برگردان و دو تای مثل هم را پیدا کن."),
                mix("#F44336", "#FFEB3B", "#FF9800", "نارنجی", "روی شیشه‌ی قرمز و زرد بزن، بعد با انگشت هم بزن. چه رنگی شد؟"),
                mix("#2196F3", "#FFEB3B", "#4CAF50", "سبز", "حالا آبی و زرد را بریز و هم بزن!"),
                mix("#F44336", "#2196F3", "#9C27B0", "بنفش", "قرمز و آبی را بریز و هم بزن. چه می‌شود؟"),
                paint("paper", "یک رنگ بردار و روی دایره‌های سفید کاغذ بزن.", parts=4),
            ], 90, secret="glue_gun"),
            section("c4s2", "کاسه‌ی گلی", "clay_bowl", "کوکو یک کاسه برای آب رنگ‌ها می‌خواهد.", [
                use("watering_can", "clay", "گل رس خشک است! از کوله‌پشتی چیزی بکش که خیسش کند.", "شُر شُر! گل نرم شد.", "با این نمی‌شود خیس کرد."),
                sort(["clay", "clay", "clay"], ["old_shoe", "junk_sock"], "هر چه روی نوار می‌آید را بکش: گل در سبد سبز، آشغال در سطل قرمز.", "گل", "آشغال"),
                tap("clay", 6, "روی گل بزن و ورزش بده!", S + "thunk.mp3"),
                rotate("pottery_wheel", 3, "انگشتت را دور چرخ بچرخان تا کاسه درست شود.", result="clay_bowl"),
                blow("clay_bowl", "کاسه خیس است. دکمه‌ی فوت را نگه دار تا خشک شود!", mode="cool"),
                paint("clay_bowl", "یک رنگ بردار و روی دایره‌های سفید کاسه بزن.", parts=3),
            ], 120),
            section("c4s3", "فانوس", "lantern", "برای شب جشن فانوس رنگی لازم داریم.", [
                connect("lantern", "نقطه‌ها را به ترتیب بزن تا فانوس پیدا شود.", dots=6),
                cut("paper", "انگشتت را روی خط‌چین‌ها بکش تا کاغذ بریده شود.", lines=2),
                tap("paper", 4, "روی کاغذ بزن تا تا بخورد و فانوس شود!", S + "rustle.mp3", result="lantern"),
                paint("lantern", "یک رنگ بردار و روی دایره‌های سفید فانوس بزن.", parts=4),
                use("flashlight", "lantern", "فانوس خاموش است! از کوله‌پشتی چیزی بکش که لامپ دارد.", "روشن شد! چه قشنگ.", "این نور ندارد."),
                count("lantern", 3, "bunting", "سه فانوس به نخ بده. بشمار!", sound="audio/ui/chime.mp3"),
            ], 110, secret="glue_gun"),
            section("c4s4", "ماسک و پرچم", "mask", "برای جشن ماسک و پرچم درست کنیم!", [
                memory(["mask", "flag", "lantern", "paints"], "کارت‌ها را برگردان و دو تای مثل هم را پیدا کن."),
                cut("paper", "انگشتت را روی خط‌چین‌ها بکش تا ماسک بریده شود.", lines=2, result="mask"),
                paint("mask", "یک رنگ بردار و روی دایره‌های سفید ماسک بزن.", parts=4),
                connect("mask", "نقطه‌ها را به ترتیب بزن تا ماسک پیدا شود.", dots=8, shape="star"),
                catch("flag", 4, "پرچم‌ها می‌افتند! سبد را زیرشان ببر. جوراب را نگیر!", distract=["junk_sock"]),
                count("flag", 5, "bunting", "پنج پرچم به نخ بده. بشمار!"),
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
                catch("map_piece", 3, "تکه‌های نقشه می‌افتند! سبد را زیرشان ببر.", distract=["junk_sock"]),
                puzzle("map", "تکه‌های نقشه را بکش و سر جایشان بگذار."),
                use("flashlight", "q_dark", "هوا تاریک است. از کوله‌پشتی چیزی بکش که نور دارد.", "حالا نقشه را می‌بینیم!", "این نور ندارد."),
                dark("star", 3, "انگشتت را در تاریکی بکش تا نور ستاره‌ها را پیدا کند."),
                connect("map", "نقطه‌ها را به ترتیب بزن تا نقشه پیدا شود.", dots=6, shape="star"),
                trace("map", "نقشه را با انگشت روی جاده تا پرچم ببر.", shape="wave"),
            ], 100, secret="magnifier"),
            section("c5s2", "چادر", "tent", "باران دارد می‌آید! یک چادر بزنیم.", [
                sort(["tent_cloth", "pole", "peg"], ["old_shoe", "rotten_apple"], "هر چه روی نوار می‌آید را بکش: وسایل چادر در سبد سبز، آشغال در سطل قرمز.", "چادر", "آشغال"),
                assemble("tent", [("tent_cloth", .5, .45), ("pole", .25, .6), ("pole", .75, .6)], "پارچه و ستون‌ها را بکش و روی جای کم‌رنگشان بگذار.", "tent"),
                use("hammer", "peg", "میخ‌های چادر را باید کوبید. از کوله‌پشتی وسیله‌ی درست را بکش.", "تق تق! چادر محکم شد.", "با این نمی‌شود میخ زد."),
                whack("peg", 4, "میخ‌ها از سوراخ‌ها بیرون می‌آیند. زود رویشان بزن! جوراب نه.", distract=["junk_sock"], sound=S + "hammer.mp3"),
                blow("tent", "دکمه‌ی فوت را نگه دار تا چادر بزرگ شود و بایستد!", mode="inflate"),
                memory(["tent", "pole", "peg", "lantern"], "کارت‌ها را برگردان و دو تای مثل هم را پیدا کن."),
            ], 110),
            section("c5s3", "مسیر نورانی", "firefly_jar", "مسیر خیلی تاریک است و مادربزرگ سردش است.", [
                use("flashlight", "q_dark", "خیلی تاریک است! از کوله‌پشتی چیزی بکش که نور دارد.", "روشن شد!", "این نور ندارد."),
                catch("firefly", 4, "کرم‌های شب‌تاب پایین می‌آیند! سبد را زیرشان ببر. کفشدوزک را نگیر.", distract=["ladybug"]),
                dark("firefly", 4, "انگشتت را در تاریکی بکش تا نور کرم‌های شب‌تاب را پیدا کند."),
                connect("firefly_jar", "نقطه‌ها را به ترتیب بزن تا شیشه‌ی شب‌تاب‌ها پیدا شود.", dots=5),
                trace("firefly", "کرم شب‌تاب را با انگشت روی جاده تا پرچم ببر.", shape="wave"),
                use("soup", "q_cold", "مادربزرگ جغد سردش است. از کوله‌پشتی چیزی بکش که گرمش کند.", "آخیش! گرم شدم، ممنون عزیزم.", "این گرم نمی‌کند."),
            ], 120),
            section("c5s4", "تلسکوپ", "telescope", "مادربزرگ جغد می‌خواهد ستاره‌ها را نشانت بدهد.", [
                rotate("tube", 2, "انگشتت را دور مقوا بچرخان تا لوله شود.", sound=S + "rustle.mp3"),
                scrub("lens", "عدسی خاکی است. انگشتت را رویش بکش تا تمیز شود."),
                order(["lens", "lens", "lens"], "اول عدسی بزرگ را بزن، بعد کوچک‌تر، بعد از همه کوچک‌تر."),
                rotate("telescope", 2, "انگشتت را دور تلسکوپ بچرخان تا تنظیم شود.", sound=S + "gear.mp3"),
                connect("star", "نقطه‌ها را به ترتیب بزن تا ستاره پیدا شود.", dots=5, shape="star"),
                memory(["moon", "star", "telescope", "lens"], "کارت‌ها را برگردان و دو تای مثل هم را پیدا کن."),
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
                use("clay_bowl", "drum_skin", "برای طبل یک کاسه لازم داریم. کاسه را از کوله‌پشتی بکش.", "این کاسه عالی است!", "این کاسه نیست."),
                cut("drum_skin", "انگشتت را روی خط‌چین بکش تا پوست طبل بریده شود.", lines=1),
                assemble("drum", [("drum_skin", .5, .3)], "پوست طبل را بکش و روی جای کم‌رنگش بگذار.", "drum"),
                tap("drum", 5, "روی طبل بزن تا طناب‌هایش سفت شود. بوم بوم!", I + "drum_tom.mp3"),
                paint("drum", "یک رنگ بردار و روی دایره‌های سفید طبل بزن.", parts=4),
                whack("note", 5, "نُت‌ها از سوراخ‌ها بیرون می‌آیند. زود رویشان بزن! جوراب نه.", distract=["junk_sock"], sound=I + "drum_tom.mp3"),
            ], 90, secret="drill"),
            section("c6s2", "زایلوفون", "xylophone", "زایلوفون تیغه‌های رنگی دارد.", [
                order(["bar_red", "bar_red", "bar_red", "bar_red"], "اول تیغه‌ی بلند را بزن، بعد کوتاه‌تر و کوتاه‌تر.", sound=I + "xylo_c4.mp3"),
                use("hammer", "q_nail", "تیغه‌ها باید میخ بخورند. از کوله‌پشتی وسیله‌ی درست را بکش.", "تق تق!", "با این نمی‌شود میخ زد."),
                count("bar_red", 4, "xylophone", "چهار تیغه روی زایلوفون بگذار. بشمار!", sound=I + "xylo_e4.mp3"),
                paint("xylophone", "یک رنگ بردار و روی دایره‌های سفید زایلوفون بزن.", parts=4),
                memory(["drum", "xylophone", "flute", "note"], "کارت‌ها را برگردان و دو تای مثل هم را پیدا کن."),
                rhythm([("bar_red", I + "xylo_c4.mp3"), ("bar_red", I + "xylo_e4.mp3"), ("bar_red", I + "xylo_g4.mp3")], "اول گوش کن، بعد همان تیغه‌ها را به همان ترتیب بزن!", rounds=2),
            ], 110),
            section("c6s3", "نی", "flute", "نی صدای پرنده‌ها را دارد.", [
                scrub("reed", "نی خاکی است. انگشتت را رویش بکش تا تمیز شود."),
                cut("reed", "انگشتت را روی خط‌چین بکش تا نی بریده شود.", lines=1, result="flute"),
                tap("flute", 4, "روی نی بزن تا سوراخ‌هایش باز شود!", "audio/ui/pop.mp3"),
                blow("flute", "دکمه‌ی فوت را نگه دار تا نی بنوازد!", mode="music", sound=I + "flute.mp3"),
                timing("flute", "وقتی حلقه به جای طلایی رسید، بزن تا نی بلند بخواند!", sound=I + "flute.mp3"),
                catch("note", 4, "نُت‌ها می‌افتند! سبد را زیرشان ببر. جوراب را نگیر!", distract=["junk_sock"], sound=I + "xylo_g4.mp3"),
            ], 90, secret="saw"),
            section("c6s4", "آهنگ جشن", "song", "با سازهایی که ساختی آهنگ جشن را بسازیم!", [
                whack("note", 6, "نُت‌ها از سوراخ‌ها بیرون می‌آیند. زود رویشان بزن!", distract=["junk_sock"], sound=I + "xylo_c5.mp3"),
                memory(["drum", "xylophone", "flute", "note"], "کارت‌ها را برگردان و دو تای مثل هم را پیدا کن."),
                count("note", 5, "song", "پنج نُت به آهنگ بده. بشمار!", sound=I + "xylo_g4.mp3"),
                connect("song", "نقطه‌ها را به ترتیب بزن تا آهنگ جشن پیدا شود.", dots=6, shape="star"),
                blow("flute", "دکمه‌ی فوت را نگه دار و با نی بنواز!", mode="music", sound=I + "flute.mp3"),
                rhythm([("drum", I + "drum_tom.mp3"), ("xylophone", I + "xylo_e4.mp3"), ("flute", I + "flute.mp3")], "اول گوش کن، بعد طبل و زایلوفون و نی را به همان ترتیب بزن!", rounds=3),
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
                use("cart", "plank", "تخته‌ها سنگین‌اند. از کوله‌پشتی چیزی بکش که بار ببرد.", "گاری تخته‌ها را آورد!", "این بار نمی‌برد."),
                stack("plank", 4, "جرثقیل تخته را تکان می‌دهد. وقتی بالای خط سبز بود، بزن تا بیفتد!", sound=S + "thunk.mp3"),
                count("plank", 3, "bridge", "سه تخته به پل بده. بشمار!"),
                use("hammer", "q_nail", "تخته‌های پل باید میخ بخورند. از کوله‌پشتی وسیله‌ی درست را بکش.", "تق تق! پل محکم شد.", "با این نمی‌شود میخ زد."),
                whack("nail", 5, "میخ‌ها از سوراخ‌ها بیرون می‌آیند. زود رویشان بزن! جوراب نه.", distract=["junk_sock"], sound=S + "hammer.mp3"),
                steer("toy_car", ["star"], ["rock", "cone"], 4, "چپ یا راست صفحه را بزن تا ماشین راهش را عوض کند. ستاره‌ها را بگیر!", sound="audio/ui/sparkle.mp3"),
            ], 110, secret="drill"),
            section("c7s2", "چراغ راهنمایی", "traffic_light", "چراغ راهنمایی خاموش است و ماشین‌ها گیج شده‌اند.", [
                order(["light_red", "light_yellow", "light_green"], "به ترتیب بزن: قرمز، زرد، سبز."),
                use("paints", "traffic_light", "رنگ چراغ رفته! از کوله‌پشتی چیزی بکش که رنگ دارد.", "رنگی شد!", "این رنگ ندارد."),
                connect("traffic_light", "نقطه‌ها را به ترتیب بزن تا چراغ راهنمایی پیدا شود.", dots=6),
                tap("traffic_light", 3, "روی چراغ بزن تا رنگش عوض شود: قرمز، زرد، سبز!", "audio/ui/toggle.mp3"),
                memory(["light_red", "light_yellow", "light_green", "traffic_light"], "کارت‌ها را برگردان و دو تای مثل هم را پیدا کن."),
                whack("light_green", 5, "هر وقت چراغ سبز بیرون آمد بزن! قرمز را نزن.", distract=["light_red"], sound="audio/ui/toggle.mp3"),
            ], 100),
            section("c7s3", "تعمیر اتوبوس", "bus", "اتوبوس لاکی پنچر و کثیف و بی‌بنزین است!", [
                blow("tire", "لاستیک پنچر است! دکمه‌ی فوت را نگه دار تا باد شود.", mode="inflate"),
                rotate("tire", 2, "انگشتت را دور لاستیک بچرخان تا پیچ‌هایش بسته شود.", sound=S + "gear.mp3"),
                scrub("bus", "اتوبوس گلی است. انگشتت را رویش بکش تا تمیز شود."),
                pour("fuel", "bus", "قوطی بنزین را نگه دار تا بریزد. سر پرچم ول کن!", color="#E53935"),
                rotate("car_key", 2, "انگشتت را دور کلید بچرخان تا اتوبوس روشن شود!", sound=S + "engine.mp3", result="bus"),
                steer("bus", ["star"], ["rock", "cone"], 5, "چپ یا راست صفحه را بزن. ستاره‌ها را بگیر، به سنگ و مخروط نخور!", sound=S + "bus_horn.mp3"),
            ], 130, secret="wrench"),
            section("c7s4", "کارت دعوت", "invitation", "باید همه را به جشن دعوت کنیم!", [
                puzzle("invitation", "تکه‌های کارت را بکش و سر جایشان بگذار."),
                paint("invitation", "یک رنگ بردار و روی دایره‌های سفید کارت بزن.", parts=4),
                catch("letter", 4, "نامه‌ها می‌افتند! سبد را زیرشان ببر. جوراب را نگیر!", distract=["junk_sock"], sound="audio/ui/page.mp3"),
                count("letter", 3, "mailbox", "سه نامه در صندوق بینداز. بشمار!", sound="audio/ui/page.mp3"),
                use("toy_car", "q_travel", "خانه‌ها دورند. از کوله‌پشتی چیزی بکش که حرکت می‌کند.", "برووووم! نامه‌ها رسیدند.", "این حرکت نمی‌کند."),
                trace("toy_car", "ماشین را با انگشت روی جاده تا پرچم ببر.", shape="zigzag"),
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
                catch("cookie", 4, "کلوچه‌ها می‌افتند! سبد را زیرشان ببر. کفش را نگیر!", distract=["old_shoe"]),
                sort(["pizza", "cake", "cookie"], ["old_shoe", "junk_sock"], "هر چه روی نوار می‌آید را بکش: غذا روی میز سبز، آشغال در سطل قرمز.", "میز", "سطل"),
                memory(["cake", "juice", "soup", "sandwich"], "کارت‌ها را برگردان و دو تای مثل هم را پیدا کن."),
                serve([("bear", "cake"), ("bunny", "juice"), ("owl", "soup"), ("squirrel", "sandwich")], "ببین هر مهمان چه می‌خواهد و همان را از کوله‌پشتی برایش بکش."),
                feed("owl", ["soup", "bread"], "مادربزرگ جغد گرسنه است. هر چه خواست، به دهانش ببر. کفش نه!", n=3, distract=["old_shoe"]),
                count("cookie", 4, "feast", "چهار کلوچه روی میز جشن بگذار. بشمار!"),
            ], 90),
            section("c8s2", "تزئین میدان", "decorations", "میدان جشن را قشنگ کنیم!", [
                memory(["lantern", "mask", "flag", "balloon"], "کارت‌ها را برگردان و دو تای مثل هم را پیدا کن."),
                serve([("parrot", "lantern"), ("cat", "mask"), ("bunny", "flower_pot")], "ببین هر دوست چه می‌خواهد و همان را از کوله‌پشتی برایش بکش."),
                blow("balloon", "دکمه‌ی فوت را نگه دار تا بادکنک‌ها باد شوند!", mode="inflate", n=3),
                stack("box", 5, "وقتی جعبه بالای خط سبز بود، بزن تا روی برج بیفتد!", sound=S + "thunk.mp3"),
                count("flag", 4, "bunting", "چهار پرچم به نخ بده. بشمار!"),
                paint("decorations", "یک رنگ بردار و روی دایره‌های سفید بزن.", parts=4),
            ], 100),
            section("c8s3", "کنسرت", "concert", "وقت کنسرت میمی است!", [
                serve([("cat", "drum"), ("parrot", "xylophone"), ("owl", "flute")], "ببین هر نوازنده چه سازی می‌خواهد و همان را برایش بکش."),
                connect("concert", "نقطه‌ها را به ترتیب بزن تا صحنه‌ی کنسرت پیدا شود.", dots=6),
                blow("flute", "دکمه‌ی فوت را نگه دار و با نی بنواز!", mode="music", sound=I + "flute.mp3"),
                rhythm([("drum", I + "drum_tom.mp3"), ("xylophone", I + "xylo_e4.mp3"), ("flute", I + "flute.mp3")], "اول گوش کن، بعد سازها را به همان ترتیب بزن!", rounds=3),
                catch("note", 5, "نُت‌ها می‌افتند! سبد را زیرشان ببر. جوراب را نگیر!", distract=["junk_sock"], sound=I + "xylo_g4.mp3"),
                feed("cat", ["juice"], "میمی تشنه است. آب‌پرتقال را به دهانش ببر.", n=2, sound=S + "sip.mp3"),
            ], 110),
            section("c8s4", "جشن نهایی", "medal", "آخرین کار: مهمان‌ها را بیاوریم و آتش‌بازی کنیم!", [
                use("bus", "q_travel", "مهمان‌ها دورند. از کوله‌پشتی چیزی بکش که همه را بیاورد.", "بوق بوق! همه رسیدند.", "این همه را نمی‌آورد."),
                steer("bus", ["star"], ["rock", "cone"], 4, "چپ یا راست صفحه را بزن. ستاره‌ها را بگیر، به سنگ و مخروط نخور!", sound=S + "bus_horn.mp3"),
                use("telescope", "q_sky", "می‌خواهیم ستاره‌ها را از نزدیک ببینیم. از کوله‌پشتی وسیله‌ی درست را بکش.", "وای! ستاره‌ها!", "با این نمی‌شود دور را دید."),
                whack("firework", 6, "آتش‌بازی‌ها از سوراخ‌ها بیرون می‌آیند. زود رویشان بزن!", sound="audio/ui/whoosh.mp3"),
                catch("star", 5, "ستاره‌ها می‌افتند! سبد را زیرشان ببر.", sound="audio/ui/sparkle.mp3"),
                connect("medal", "نقطه‌ها را به ترتیب بزن تا مدال قهرمانی پیدا شود!", dots=8, shape="star"),
            ], 120),
        ],
    },
]

# Star Workshop: a kit opens itself when the total stars reach [stars]. Same section format.
KITS = [
    section("k_bubbles", "حباب‌ساز", "bubbles", "بیا یک حباب‌ساز بسازیم!", [
        pour("soap_bottle", "bowl_mix", "شیشه‌ی صابون را نگه دار تا در کاسه بریزد. سر پرچم ول کن!", color="#B3E5FC"),
        rotate("bowl_mix", 2, "انگشتت را دور کاسه بچرخان تا کف کند.", result="bubbles"),
        blow("bubbles", "دکمه‌ی فوت را نگه دار تا حباب درست شود!", mode="inflate", n=3),
        collect("bubbles", 6, "روی حباب‌ها بزن تا بترکند!", sound=S + "bloop.mp3"),
        whack("bubbles", 6, "حباب‌ها از سوراخ‌ها بیرون می‌آیند. زود رویشان بزن!", sound=S + "bloop.mp3"),
    ], 80),
    section("k_necklace", "گردنبند مهره‌ای", "necklace", "یک گردنبند رنگی بسازیم.", [
        catch("bead", 5, "مهره‌ها می‌افتند! سبد را زیرشان ببر. جوراب را نگیر!", distract=["junk_sock"], sound="audio/ui/chime.mp3"),
        order(["bead", "bead", "bead", "bead"], "اول مهره‌ی بزرگ را بزن، بعد کوچک‌تر و کوچک‌تر."),
        count("bead", 6, "necklace", "شش مهره به گردنبند بده. بشمار!", sound="audio/ui/chime.mp3"),
        connect("necklace", "نقطه‌ها را به ترتیب بزن تا گردنبند پیدا شود.", dots=6),
        paint("necklace", "یک رنگ بردار و روی دایره‌های سفید بزن.", parts=4),
    ], 80),
    section("k_kite", "بادبادک", "kite", "روز بادی است! بادبادک بسازیم.", [
        connect("kite", "نقطه‌ها را به ترتیب بزن تا بادبادک پیدا شود.", dots=4),
        cut("paper", "انگشتت را روی خط‌چین‌ها بکش تا کاغذ بریده شود.", lines=2),
        paint("kite", "یک رنگ بردار و روی دایره‌های سفید بادبادک بزن.", parts=4),
        blow("kite", "دکمه‌ی فوت را نگه دار تا بادبادک بچرخد!", mode="spin"),
        trace("kite", "بادبادک را با انگشت روی جاده تا پرچم ببر.", shape="wave"),
    ], 100),
    section("k_robot", "ربات", "robot", "یک ربات دوست بسازیم!", [
        memory(["robot", "robot_head", "robot_body", "battery"], "کارت‌ها را برگردان و دو تای مثل هم را پیدا کن."),
        assemble("robot", [("robot_head", .5, .25), ("robot_body", .5, .6)], "سر و بدنه را بکش و روی جای کم‌رنگشان بگذار.", "robot"),
        count("battery", 2, "robot", "دو باتری به ربات بده. بشمار!", sound=S + "gear.mp3"),
        paint("robot", "یک رنگ بردار و روی دایره‌های سفید ربات بزن.", parts=4),
        trace("robot", "ربات را با انگشت روی جاده تا پرچم ببر.", shape="zigzag"),
    ], 120),
    section("k_dollhouse", "خانه‌ی عروسکی", "dollhouse", "یک خانه‌ی کوچک برای عروسک‌ها!", [
        stack("box", 4, "وقتی جعبه بالای خط سبز بود، بزن تا روی برج بیفتد!", sound=S + "thunk.mp3"),
        connect("dollhouse", "نقطه‌ها را به ترتیب بزن تا خانه پیدا شود.", dots=5),
        scrub("dollhouse", "خانه خاکی است. انگشتت را رویش بکش تا تمیز شود."),
        paint("dollhouse", "یک رنگ بردار و روی دایره‌های سفید خانه بزن.", parts=4),
        tap("bulb", 3, "روی لامپ بزن تا روشن شود!", S + "light_switch.mp3"),
    ], 110),
    section("k_rocket", "موشک", "rocket", "به فضا برویم!", [
        assemble("rocket", [("tube", .5, .5)], "بدنه‌ی موشک را بکش و روی جای کم‌رنگش بگذار.", "rocket"),
        paint("rocket", "یک رنگ بردار و روی دایره‌های سفید موشک بزن.", parts=4),
        order(["star", "star", "star", "star", "star"], "اول ستاره‌ی بزرگ را بزن، بعد کوچک‌تر و کوچک‌تر!"),
        steer("rocket", ["star"], ["rock"], 5, "چپ یا راست صفحه را بزن. ستاره‌ها را بگیر، به سنگ نخور!", sound="audio/ui/sparkle.mp3"),
        collect("star", 5, "روی ستاره‌ها بزن تا در سبد بپرند!", sound="audio/ui/sparkle.mp3"),
    ], 130),
    section("k_submarine", "زیردریایی", "submarine", "زیر دریا چه خبر است؟", [
        assemble("submarine", [("lens", .62, .45)], "پنجره را بکش و روی جای کم‌رنگش بگذار.", "submarine"),
        paint("submarine", "یک رنگ بردار و روی دایره‌های سفید زیردریایی بزن.", parts=3),
        dark("fish", 4, "انگشتت را در تاریکی بکش تا نور ماهی‌ها را پیدا کند."),
        steer("submarine", ["fish"], ["rock"], 4, "چپ یا راست صفحه را بزن. ماهی‌ها را بگیر، به سنگ نخور!"),
        whack("fish", 5, "ماهی‌ها از سوراخ‌ها بیرون می‌آیند. زود رویشان بزن! کفش نه.", distract=["old_shoe"], sound=S + "bloop.mp3"),
    ], 120),
    section("k_train", "قطار", "train", "چووو چووو! یک قطار بسازیم.", [
        count("rail", 5, "train", "پنج ریل به قطار بده. بشمار!", sound=S + "thunk.mp3"),
        count("wheel", 4, "train", "چهار چرخ به قطار بده. بشمار!", sound=S + "gear.mp3"),
        connect("train", "نقطه‌ها را به ترتیب بزن تا قطار پیدا شود.", dots=6),
        paint("train", "یک رنگ بردار و روی دایره‌های سفید قطار بزن.", parts=4),
        trace("train", "قطار را با انگشت روی جاده تا پرچم ببر.", shape="wave"),
    ], 130),
]
KIT_STARS = {"k_bubbles": 5, "k_necklace": 10, "k_kite": 18, "k_robot": 28, "k_dollhouse": 38,
             "k_rocket": 50, "k_submarine": 65, "k_train": 80}

# Tool shop: tools bought with coins, each unlocking recipes (short sections).
TOOLS = [
    {"id": "magnifier", "title": "ذره‌بین", "price": 30, "sound": "audio/ui/sparkle.mp3",
     "safety": "ذره‌بین را هیچ‌وقت رو به خورشید نگیر.",
     "recipes": [section("r_bug_book", "دفترچه‌ی حشره‌ها", "bug_book", "با ذره‌بین حشره‌ها را پیدا کنیم!", [
         dark("ladybug", 4, "انگشتت را بکش تا ذره‌بین کفشدوزک‌های پنهان را پیدا کند."),
     ], 60)]},
    {"id": "saw", "title": "اره", "price": 40, "sound": S + "saw.mp3",
     "safety": "با اره همیشه با یک بزرگ‌تر کار می‌کنیم.",
     "recipes": [section("r_bird_house", "خانه‌ی پرنده", "bird_house", "برای پرنده‌ها خانه بسازیم.", [
         cut("plank", "انگشتت را روی خط‌چین‌ها بکش تا تخته بریده شود.", lines=2),
         count("plank", 3, "bird_house", "سه تخته به خانه‌ی پرنده بده. بشمار!", sound=S + "thunk.mp3"),
         paint("bird_house", "یک رنگ بردار و روی دایره‌های سفید خانه بزن.", parts=3),
     ], 90)]},
    {"id": "glue_gun", "title": "چسب‌تفنگی", "price": 50, "sound": S + "squeak.mp3",
     "safety": "سر چسب‌تفنگی داغ است؛ به آن دست نمی‌زنیم.",
     "recipes": [section("r_photo_frame", "قاب عکس", "photo_frame", "یک قاب برای عکس یادگاری!", [
         count("star", 4, "photo_frame", "چهار ستاره به قاب بده. بشمار!", sound="audio/ui/pop.mp3"),
         paint("photo_frame", "یک رنگ بردار و روی دایره‌های سفید قاب بزن.", parts=4),
     ], 70)]},
    {"id": "big_oven", "title": "فر بزرگ", "price": 60, "sound": S + "kettle.mp3",
     "safety": "در فر داغ است؛ با دستکش بازش می‌کنیم.",
     "recipes": [
         section("r_pizza", "پیتزا", "pizza", "بیا پیتزا بپزیم!", [
             count("tomato", 3, "dough", "سه گوجه روی خمیر بگذار. بشمار!"),
             count("cheese", 2, "dough", "دو تکه پنیر روی خمیر بگذار."),
             timing("big_oven", "پیتزا در فر است. وقتی حلقه به جای طلایی رسید، بزن!", sound=S + "sizzle.mp3", result="pizza"),
         ], 80),
         section("r_cookie", "کلوچه", "cookie", "کلوچه‌ی تازه!", [
             rotate("bowl_mix", 2, "انگشتت را دور کاسه بچرخان تا خمیر کلوچه درست شود."),
             timing("big_oven", "کلوچه در فر است. وقتی حلقه به جای طلایی رسید، بزن!", sound=S + "kettle.mp3", result="cookie"),
         ], 70),
     ]},
    {"id": "sewing_machine", "title": "چرخ خیاطی", "price": 70, "sound": S + "sewing.mp3",
     "safety": "انگشت‌ها را از سوزن دور نگه می‌داریم.",
     "recipes": [section("r_rag_doll", "عروسک پارچه‌ای", "rag_doll", "یک عروسک نرم بدوزیم.", [
         tap("sewing_machine", 8, "روی چرخ خیاطی تند تند بزن تا بدوزد: تق تق تق!", S + "sewing.mp3"),
         paint("rag_doll", "یک رنگ بردار و روی دایره‌های سفید عروسک بزن.", parts=4),
     ], 80)]},
    {"id": "drill", "title": "دریل", "price": 80, "sound": S + "drill.mp3",
     "safety": "دریل را فقط بزرگ‌ترها روشن می‌کنند و ما کمک می‌کنیم.",
     "recipes": [section("r_windmill", "آسیاب بادی", "windmill", "یک آسیاب بادی بسازیم.", [
         tap("drill", 3, "روی دریل بزن تا سوراخ کند!", S + "drill.mp3"),
         assemble("windmill", [("flag", .5, .3)], "پره را بکش و روی جای کم‌رنگش بگذار.", "windmill"),
         rotate("windmill", 2, "انگشتت را دور آسیاب بچرخان تا پره‌هایش بچرخند!", sound="audio/ambient/wind.ogg"),
     ], 80)]},
    {"id": "wrench", "title": "آچار", "price": 90, "sound": S + "gear.mp3",
     "safety": "آچار را محکم و آرام می‌چرخانیم.",
     "recipes": [section("r_bicycle", "دوچرخه", "bicycle", "یک دوچرخه برای پوپو!", [
         count("wheel", 2, "bicycle", "دو چرخ به دوچرخه بده. بشمار!", sound=S + "gear.mp3"),
         rotate("wrench", 3, "انگشتت را دور آچار بچرخان تا پیچ‌ها سفت شوند.", sound=S + "gear.mp3", result="bicycle"),
         paint("bicycle", "یک رنگ بردار و روی دایره‌های سفید دوچرخه بزن.", parts=3),
     ], 90)]},
    {"id": "magnet", "title": "آهن‌ربا", "price": 100, "sound": S + "snap.mp3",
     "safety": "آهن‌ربا را نزدیک گوشی و تلویزیون نمی‌بریم.",
     "recipes": [section("r_magnet_fish", "ماهیگیری آهن‌ربایی", "magnet_fish", "بیا ماهیگیری کنیم!", [
         sort(["nail", "screw"], ["paper", "bread"], "هر چه روی نوار می‌آید را بکش: آهنی‌ها در سبد سبز، بقیه در سطل قرمز.", "آهنی", "غیرآهنی"),
         collect("fish", 4, "روی ماهی‌ها بزن تا با آهن‌ربا در سبد بپرند!", sound=S + "splash.mp3"),
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
        "friends": {k: {"name": n, "emoji": e} for k, (n, e) in FRIENDS.items()},
        "items": ITEMS,
        "chapters": CHAPTERS,
        "kits": [{**k, "stars": KIT_STARS[k["id"]]} for k in KITS],
        "tools": TOOLS,
        "combos": [{"items": a, "text": t, "fx": fx} for a, t, fx in COMBOS],
        "orders": [{"friend": f, "tag": tag, "text": t} for f, tag, t in ORDERS],
        "art": dict(sorted(ART.items())),
    }
    # every picture a step, item or quiz shows must have an entry
    used: set[str] = set(ITEMS)
    for s in [x for ch in CHAPTERS for x in ch["sections"]] + KITS + [r for t in TOOLS for r in t["recipes"]]:
        for st in s["steps"]:
            for k in ("target", "result", "base", "into", "source", "need", "spot"):
                if isinstance(st.get(k), str) and not st[k].startswith("#"):
                    used.add(st[k])
            for k in ("distract", "good", "bad", "items", "food"):
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
    prefixes = tuple(f"c{n}s" for n in range(1, 9)) + tuple(f"{p}." for p in ["c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8", "k_bubbles", "k_necklace", "k_kite",
                                       "k_robot", "k_dollhouse", "k_rocket", "k_submarine", "k_train", "item", "tool", "order",
                                       "combo", "game", "home", "workshop", "shop", "playroom", "film", "kit"]) + ("r_",)
    old = {l["id"]: l for l in voice["lines"]}
    kept = [l for l in voice["lines"] if l["id"] not in ids and not l["id"].startswith(prefixes)]
    for l in mine:  # a respelling added in the studio survives a rebuild
        if old.get(l["id"], {}).get("spoken") and old[l["id"]]["text"] == l["text"]:
            l["spoken"] = old[l["id"]]["spoken"]
    # every line gets its fully vowelled form (اعراب) for the voice studio: tools/content/spoken_fa.json,
    # keyed by the written text, so a rewritten sentence needs a new entry (the content test checks).
    spoken = json.loads((ROOT / "tools/content/spoken_fa.json").read_text(encoding="utf-8"))
    for l in kept + mine:
        if l["text"] in spoken:
            l["spoken"] = spoken[l["text"]]
    voice["lines"] = kept + mine
    vpath.write_text(json.dumps(voice, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")

    n_sec = sum(len(c["sections"]) for c in CHAPTERS)
    print(f"{len(CHAPTERS)} chapters, {n_sec} sections, {len(ITEMS)} items, {len(KITS)} kits, {len(TOOLS)} tools, "
          f"{len(ART)} pictures, {len(mine)} new voice lines ({len(kept)} kept)")


if __name__ == "__main__":
    main()
