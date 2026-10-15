#!/usr/bin/env python3
"""Writes the scene, world and activity JSON files in assets/content.

The JSON is what the app reads; this script is only a convenient, commented way of writing it
(shorter than hand-editing positions in JSON). Editing the JSON directly works too — the app has
no idea this script exists. After a change, `flutter test` checks every reference
(test/content_integrity_test.dart).

Coordinates: x, y are the object's centre as a fraction of the stage (0..1); size is a fraction of
the stage's shorter side. Rooms have their floor line at y = 0.6, outdoor scenes their horizon
at 0.5.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/content"

A = "audio/animals/"
S = "audio/sfx/"
U = "audio/ui/"


def o(id, art, x, y, size, label=None, **kw):
    d = {"id": id, "art": art, "x": x, "y": y, "size": size}
    if label:
        d["label"] = label
    d.update(kw)
    return d


def tap(anim="bounce", sound=None, **kw):
    d = {"anim": anim}
    if sound:
        d["sound"] = sound
    d.update(kw)
    return d


def acc(tag, anim="jump", sound=None, then="stay", **kw):
    d = {"tag": tag, "anim": anim, "then": then}
    if sound:
        d["sound"] = sound
    d.update(kw)
    return d


HOME = [
    {"id": "home.living", "world": "home", "title": "پذیرایی", "icon": "sofa", "background": "living", "intro": "scene.home.living",
     "objects": [
         o("rug", "rug", .5, .84, .55, "فرش", z=-1, persist=False),
         o("clock", "clock", .16, .2, .16, "ساعت", tap=tap("wiggle", S + "clock.mp3")),
         o("sofa", "sofa", .3, .58, .42, "مبل", drag="free", tap=tap("squash", S + "boing.mp3")),
         o("lamp", "lamp", .86, .47, .36, "چراغ", glow=True, tap=tap("pop", S + "light_switch.mp3", toggle=True)),
         o("tv", "tv", .64, .5, .3, "تلویزیون", glow=True, tap=tap("pop", S + "tv_on.mp3", toggle=True)),
         o("plant", "plant", .08, .53, .24, "گلدان", drag="free", tap=tap("wiggle", S + "rustle.mp3")),
         o("ball", "ball", .72, .86, .15, "توپ", drag="free", tags=["toy"], tap=tap("jump", S + "boing.mp3")),
         o("bunny", "teddy", .45, .8, .18, "عروسک خرگوش", drag="free", tags=["toy"], tap=tap("jump", S + "giggle.mp3")),
         o("blocks", "toy_blocks", .2, .86, .19, "مکعب‌ها", drag="free", tags=["toy"], tap=tap("squash", S + "thunk.mp3")),
     ]},
    {"id": "home.kitchen", "world": "home", "title": "آشپزخانه", "icon": "pot", "background": "kitchen", "intro": "scene.home.kitchen",
     "objects": [
         o("fridge", "fridge", .12, .44, .44, "یخچال", tap=tap("wiggle", S + "door.mp3")),
         o("stove", "stove", .78, .52, .34, "اجاق", tap=tap("wiggle", S + "sizzle.mp3")),
         o("pot", "pot", .78, .36, .2, "قابلمه", z=1, tap=tap("jump", S + "bubbles.mp3"),
           accepts=[acc("food", "jump", S + "bubbles.mp3", then="hide")]),
         o("table", "table", .44, .72, .44, "میز", z=-1, persist=False),
         o("plate", "plate", .44, .6, .24, "بشقاب", accepts=[acc("fruit", "jump", U + "pop.mp3")]),
         o("cup", "cup", .6, .57, .12, "لیوان", drag="free", tap=tap("wiggle", S + "pour.mp3")),
         o("kettle_tap", "cup", .3, .57, .1, "لیوان آب", drag="free", tap=tap("wiggle", S + "water_tap.mp3")),
         o("apple", "apple", .28, .88, .12, "سیب", drag="free", tags=["fruit", "food"], tap=tap("jump", U + "pop.mp3")),
         o("banana", "banana", .46, .9, .13, "موز", drag="free", tags=["fruit", "food"], tap=tap("jump", U + "pop.mp3")),
         o("carrot", "carrot", .62, .88, .12, "هویج", drag="free", tags=["food"], tap=tap("jump", U + "pop.mp3")),
         o("bread", "bread", .14, .9, .13, "نان", drag="free", tags=["food"], tap=tap("squash", U + "pop.mp3")),
     ]},
    {"id": "home.bedroom", "world": "home", "title": "اتاق خواب", "icon": "bed", "background": "bedroom", "intro": "scene.home.bedroom",
     "objects": [
         o("clock", "clock", .2, .2, .15, "ساعت", tap=tap("wiggle", S + "clock.mp3")),
         o("bookshelf", "bookshelf", .88, .44, .38, "کتابخانه", tap=tap("wiggle", U + "page.mp3")),
         o("bed", "bed", .55, .58, .5, "تخت", tap=tap("squash", S + "boing.mp3"),
           accepts=[acc("toy", "squash", S + "yawn.mp3")]),
         o("lamp", "lamp", .12, .46, .3, "چراغ خواب", glow=True, tap=tap("pop", S + "light_switch.mp3", toggle=True)),
         o("bunny", "teddy", .42, .84, .18, "عروسک خرگوش", drag="free", tags=["toy"], tap=tap("jump", S + "giggle.mp3")),
         o("ball", "ball", .76, .86, .14, "توپ", drag="free", tags=["toy"], tap=tap("jump", S + "boing.mp3")),
         o("blocks", "toy_blocks", .2, .88, .18, "مکعب‌ها", drag="free", tags=["toy"], tap=tap("squash", S + "thunk.mp3")),
     ]},
    {"id": "home.bathroom", "ambient": "audio/ambient/bathroom.mp3", "world": "home", "title": "حمام", "icon": "bathtub", "background": "bathroom", "intro": "scene.home.bathroom",
     "objects": [
         o("towel", "towel", .88, .34, .26, "حوله", tap=tap("wiggle", S + "rustle.mp3")),
         o("bathtub", "bathtub", .52, .62, .56, "وان", tap=tap("wiggle", S + "splash.mp3"),
           accepts=[acc("duck", "wiggle", S + "splash.mp3"), acc("soap", "jump", S + "bubbles.mp3", then="return")]),
         o("brush", "toothbrush", .14, .44, .18, "مسواک", drag="free", tap=tap("wiggle", S + "eraser.mp3")),
         o("duck", "rubber_duck", .2, .86, .16, "اردک پلاستیکی", drag="free", tags=["duck"], tap=tap("jump", S + "squeak.mp3")),
         o("soap", "soap", .84, .86, .15, "صابون", drag="free", tags=["soap"], tap=tap("wiggle", S + "bubbles.mp3")),
         o("water", "cup", .66, .88, .11, "لیوان", drag="free", tap=tap("wiggle", S + "water_tap.mp3")),
     ]},
]

ROAD = [[-.05, .72], [.25, .66], [.55, .78], [.8, .7], [1.05, .74]]
CITY = [
    {"id": "city.street", "ambient": "audio/ambient/street.mp3", "world": "city", "title": "خیابان", "icon": "car", "background": "street", "intro": "scene.city.street",
     "paths": {"road": ROAD},
     "objects": [
         o("house", "house", .13, .44, .26, "خانه", tap=tap("wiggle", S + "doorbell.mp3")),
         o("shop", "shop", .43, .42, .28, "فروشگاه", tap=tap("wiggle", S + "cash.mp3")),
         o("house2", "house_blue", .74, .42, .26, "خانه‌ی آبی", tap=tap("wiggle", S + "door.mp3")),
         o("light", "traffic_light", .94, .5, .22, "چراغ راهنما", glow=True, tap=tap("pop", U + "toggle.mp3", toggle=True)),
         o("stop", "bus_stop", .28, .53, .16, "ایستگاه اتوبوس", tap=tap("wiggle", S + "bus_horn.mp3")),
         o("car", "car", .2, .67, .19, "ماشین قرمز", drag="path:road", z=2, tap=tap("jump", S + "car_horn.mp3")),
         o("bus", "bus", .5, .76, .24, "اتوبوس", drag="path:road", z=2, tap=tap("jump", S + "bus_horn.mp3")),
         o("taxi", "taxi", .82, .7, .18, "تاکسی", drag="path:road", z=2, tap=tap("jump", S + "car_horn.mp3")),
         o("truck", "truck", .05, .72, .2, "کامیون", drag="path:road", z=2, tap=tap("jump", S + "truck_horn.mp3")),
         o("bike", "bicycle", .64, .9, .17, "دوچرخه", drag="free", tap=tap("wiggle", S + "bike_bell.mp3")),
     ]},
    {"id": "city.park", "ambient": "audio/ambient/park.mp3", "world": "city", "title": "پارک", "icon": "fountain", "background": "park", "intro": "scene.city.park",
     "objects": [
         o("tree1", "tree", .12, .46, .32, "درخت", tap=tap("wiggle", S + "rustle.mp3")),
         o("tree2", "tree", .88, .48, .3, "درخت", tap=tap("wiggle", S + "rustle.mp3")),
         o("fountain", "fountain", .5, .6, .32, "فواره", tap=tap("wiggle", S + "splash.mp3")),
         o("bench", "bench", .22, .72, .26, "نیمکت", tap=tap("squash", S + "thunk.mp3")),
         o("dog", "dog", .4, .86, .22, "سگ", tap=tap("jump", A + "dog.mp3"), accepts=[acc("toy", "jump", A + "dog.mp3", then="return")]),
         o("ball", "ball", .66, .88, .13, "توپ", drag="free", tags=["toy"], tap=tap("jump", S + "boing.mp3")),
         o("bird", "bird", .7, .24, .13, "پرنده", drag="free", tap=tap("jump", A + "bird.mp3")),
         o("butterfly", "butterfly", .32, .28, .12, "پروانه", drag="free", tap=tap("spin", U + "sparkle.mp3")),
         o("flower", "flower_red", .86, .84, .16, "گل", tap=tap("wiggle", U + "chime.mp3")),
         o("bike", "bicycle", .78, .7, .17, "دوچرخه", drag="free", tap=tap("wiggle", S + "bike_bell.mp3")),
     ]},
]

NATURE = [
    {"id": "nature.forest", "world": "nature", "title": "جنگل", "icon": "pine", "background": "forest", "intro": "scene.nature.forest",
     "ambient": "audio/ambient/forest.mp3",
     "objects": [
         o("pine1", "pine", .1, .44, .34, "کاج", tap=tap("wiggle", S + "rustle.mp3")),
         o("tree", "tree", .86, .44, .36, "درخت سیب", tap=tap("wiggle", S + "rustle.mp3")),
         o("bush", "bush", .42, .6, .28, "بوته", tap=tap("wiggle", S + "rustle.mp3")),
         o("rock", "rock", .7, .66, .2, "سنگ", tap=tap("squash", S + "thunk.mp3")),
         o("mushroom", "mushroom", .24, .84, .15, "قارچ", tap=tap("squash", S + "boing.mp3")),
         o("rabbit", "rabbit", .58, .84, .2, "خرگوش", drag="free", tap=tap("jump", S + "boing.mp3")),
         o("bird", "bird", .7, .2, .12, "پرنده", drag="free", tap=tap("jump", A + "bird.mp3")),
         o("butterfly", "butterfly", .3, .26, .12, "پروانه", drag="free", tap=tap("spin", U + "sparkle.mp3")),
         o("bee", "bee", .5, .36, .1, "زنبور", drag="free", tap=tap("wiggle", S + "buzz.mp3")),
     ]},
    {"id": "nature.garden", "ambient": "audio/ambient/garden.mp3", "world": "nature", "title": "باغ", "icon": "flower_red", "background": "garden", "intro": "scene.nature.garden",
     "sticker": "garden.bloom", "goals": [{"target": "plot1", "stage": 2}, {"target": "plot2", "stage": 2}, {"target": "plot3", "stage": 2}],
     "objects": [
         o("plot1", "seed", .22, .72, .2, "دانه", states=["seed", "sprout", "flower_red"], accepts=[acc("water", "grow", S + "grow.mp3", then="return", advance=True)], tap=tap("wiggle", U + "pop.mp3")),
         o("plot2", "seed", .5, .72, .2, "دانه", states=["seed", "sprout", "flower_yellow"], accepts=[acc("water", "grow", S + "grow.mp3", then="return", advance=True)], tap=tap("wiggle", U + "pop.mp3")),
         o("plot3", "seed", .78, .72, .2, "دانه", states=["seed", "sprout", "flower_purple"], accepts=[acc("water", "grow", S + "grow.mp3", then="return", advance=True)], tap=tap("wiggle", U + "pop.mp3")),
         o("can", "watering_can", .2, .9, .18, "آب‌پاش", drag="free", tags=["water"], tap=tap("wiggle", S + "pour.mp3")),
         o("carrot", "carrot", .62, .88, .13, "هویج", drag="free", tap=tap("jump", U + "pop.mp3")),
         o("bee", "bee", .7, .3, .1, "زنبور", drag="free", tap=tap("wiggle", S + "buzz.mp3")),
         o("butterfly", "butterfly", .3, .3, .12, "پروانه", drag="free", tap=tap("spin", U + "sparkle.mp3")),
     ]},
    {"id": "nature.pond", "world": "nature", "title": "برکه", "icon": "duck", "background": "pond", "intro": "scene.nature.pond",
     "ambient": "audio/ambient/pond.mp3",
     "objects": [
         o("lily1", "lily", .3, .76, .16, "برگ نیلوفر", z=-1, tap=tap("wiggle", S + "bloop.mp3")),
         o("lily2", "lily", .7, .82, .14, "برگ نیلوفر", z=-1, tap=tap("wiggle", S + "bloop.mp3")),
         o("fish", "fish", .46, .82, .15, "ماهی", drag="free", tap=tap("jump", S + "bloop.mp3")),
         o("duck", "duck", .62, .7, .2, "اردک", drag="free", tap=tap("wiggle", A + "duck.mp3")),
         o("frog", "frog", .28, .72, .14, "قورباغه", drag="free", tap=tap("jump", A + "frog.mp3")),
         o("tree", "tree", .88, .44, .3, "درخت", tap=tap("wiggle", S + "rustle.mp3")),
         o("bird", "bird", .2, .22, .12, "پرنده", drag="free", tap=tap("jump", A + "bird.mp3")),
         o("rock", "rock", .1, .6, .16, "سنگ", tap=tap("squash", S + "splash.mp3")),
     ]},
    {"id": "nature.farm", "ambient": "audio/ambient/farm.mp3", "world": "nature", "title": "مزرعه", "icon": "cow", "background": "farm", "intro": "scene.nature.farm",
     "sticker": "farm.feed", "goals": [{"target": "cow", "tag": "hay"}, {"target": "sheep", "tag": "hay"}, {"target": "horse", "tag": "hay"}],
     "objects": [
         o("barn", "barn", .16, .42, .34, "انبار", tap=tap("wiggle", S + "door.mp3")),
         o("horse", "horse", .82, .5, .26, "اسب", tap=tap("jump", A + "horse.mp3"), accepts=[acc("hay", "jump", A + "horse.mp3", then="return")]),
         o("cow", "cow", .5, .64, .3, "گاو", tap=tap("jump", A + "cow.mp3"), accepts=[acc("hay", "jump", A + "cow.mp3", then="return")]),
         o("sheep", "sheep", .8, .78, .24, "گوسفند", tap=tap("jump", A + "sheep.mp3"), accepts=[acc("hay", "jump", A + "sheep.mp3", then="return")]),
         o("hen", "hen", .36, .86, .17, "مرغ", tap=tap("jump", A + "rooster.mp3")),
         o("chick", "chick", .52, .9, .11, "جوجه", drag="free", tap=tap("jump", S + "giggle.mp3")),
         o("hay", "hay", .12, .84, .18, "یونجه", drag="free", tags=["hay"], tap=tap("squash", S + "rustle.mp3")),
         o("dog", "dog", .64, .9, .17, "سگ", tap=tap("jump", A + "dog.mp3")),
     ]},
]

PLAY = [
    {"id": "play.cook", "world": "play", "title": "آشپزی", "icon": "pot", "background": "kitchen", "intro": "play.cook.hello", "done": "play.cook.done",
     "hint": "سه چیز را در قابلمه بریز", "sticker": "chef",
     "goals": [{"target": "pot", "tag": "ingredient", "count": 3}],
     "objects": [
         o("stove", "stove", .5, .5, .4, "اجاق", tap=tap("wiggle", S + "sizzle.mp3")),
         o("pot", "pot", .5, .32, .26, "قابلمه", z=1, persist=False, tap=tap("jump", S + "stir.mp3"),
           accepts=[acc("ingredient", "jump", S + "bubbles.mp3", then="hide")]),
         o("carrot", "carrot", .15, .84, .14, "هویج", drag="free", tags=["ingredient"], persist=False),
         o("mushroom", "mushroom", .38, .86, .14, "قارچ", drag="free", tags=["ingredient"], persist=False),
         o("cheese", "cheese", .62, .86, .15, "پنیر", drag="free", tags=["ingredient"], persist=False),
         o("bread", "bread", .85, .86, .15, "نان", drag="free", tags=["ingredient"], persist=False),
     ]},
    {"id": "play.shop", "world": "play", "title": "خرید", "icon": "basket", "background": "shop", "intro": "play.shop.hello", "done": "play.shop.done",
     "hint": "سیب، شیر و نان را در سبد بگذار", "sticker": "shopper", "want": ["apple", "milk", "bread"],
     "goals": [{"target": "basket", "tag": "want", "count": 3}],
     "objects": [
         o("basket", "basket", .5, .7, .3, "سبد خرید", persist=False,
           accepts=[acc("want", "jump", S + "cash.mp3", then="hide"), acc("extra", "wiggle", U + "soft_no.mp3", then="return")]),
         o("apple", "apple", .14, .5, .13, "سیب", drag="free", tags=["want"], persist=False),
         o("milk", "milk", .38, .48, .14, "شیر", drag="free", tags=["want"], persist=False),
         o("bread", "bread", .86, .5, .14, "نان", drag="free", tags=["want"], persist=False),
         o("banana", "banana", .62, .5, .13, "موز", drag="free", tags=["extra"], persist=False),
         o("cheese", "cheese", .86, .88, .13, "پنیر", drag="free", tags=["extra"], persist=False),
     ]},
    {"id": "play.garden", "ambient": "audio/ambient/garden.mp3", "world": "play", "title": "باغبانی", "icon": "watering_can", "background": "garden", "intro": "play.garden.hello", "done": "play.garden.done",
     "hint": "با آب‌پاش دو بار به دانه آب بده", "sticker": "gardener",
     "goals": [{"target": "plot", "stage": 2}],
     "objects": [
         o("plot", "seed", .5, .7, .26, "دانه", persist=False, states=["seed", "sprout", "flower_yellow"],
           accepts=[acc("water", "grow", S + "grow.mp3", then="return", advance=True)]),
         o("can", "watering_can", .2, .88, .2, "آب‌پاش", drag="free", tags=["water"], persist=False, tap=tap("wiggle", S + "pour.mp3")),
         o("sun", "sun", .8, .2, .18, "خورشید", tap=tap("spin", U + "chime.mp3")),
     ]},
    {"id": "play.pet", "ambient": "audio/ambient/park.mp3", "world": "play", "title": "مراقبت از سگ", "icon": "dog", "background": "park", "intro": "play.pet.hello", "done": "play.pet.done",
     "hint": "به سگ غذا بده، بشویَش و با او توپ‌بازی کن", "sticker": "petcare",
     "goals": [{"target": "dog", "tag": "food"}, {"target": "dog", "tag": "soap"}, {"target": "dog", "tag": "toy"}],
     "objects": [
         o("dog", "dog", .5, .62, .34, "سگ", persist=False, tap=tap("jump", A + "dog.mp3"),
           accepts=[acc("food", "jump", A + "dog.mp3", then="return"), acc("soap", "wiggle", S + "bubbles.mp3", then="return"),
                    acc("toy", "spin", S + "giggle.mp3", then="return")]),
         o("bowl", "bowl", .16, .88, .17, "ظرف غذا", drag="free", tags=["food"], persist=False),
         o("soap", "soap", .5, .9, .14, "صابون", drag="free", tags=["soap"], persist=False),
         o("ball", "ball", .84, .88, .13, "توپ", drag="free", tags=["toy"], persist=False),
     ]},
    {"id": "play.tidy", "world": "play", "title": "مرتب کردن اتاق", "icon": "toy_blocks", "background": "playroom", "intro": "play.tidy.hello", "done": "play.tidy.done",
     "hint": "همه‌ی اسباب‌بازی‌ها را در سبد بگذار", "sticker": "tidy",
     "goals": [{"target": "box", "tag": "toy", "count": 5}],
     "objects": [
         o("box", "basket", .5, .52, .3, "سبد اسباب‌بازی", persist=False, accepts=[acc("toy", "jump", U + "pop.mp3", then="hide")]),
         o("ball", "ball", .14, .74, .13, "توپ", drag="free", tags=["toy"], persist=False),
         o("bunny", "teddy", .82, .76, .16, "عروسک", drag="free", tags=["toy"], persist=False),
         o("blocks", "toy_blocks", .3, .9, .16, "مکعب‌ها", drag="free", tags=["toy"], persist=False),
         o("duck", "rubber_duck", .66, .9, .13, "اردک", drag="free", tags=["toy"], persist=False),
         o("car", "car", .86, .9, .15, "ماشین", drag="free", tags=["toy"], persist=False),
     ]},
]

WORLDS = {
    "sceneFiles": ["home.json", "city.json", "nature.json", "play.json"],
    "worlds": [
        {"id": "home", "card": "card_home", "title": "خانه‌ی من", "subtitle": "پذیرایی، آشپزخانه، اتاق خواب، حمام", "art": "house", "route": "/world/home", "mapX": .26, "mapY": .2, "voice": "world.home.hello",
         "scenes": ["home.living", "home.kitchen", "home.bedroom", "home.bathroom"]},
        {"id": "city", "card": "card_city", "title": "شهر بازی", "subtitle": "ماشین‌ها، اتوبوس، فروشگاه، پارک", "art": "bus", "route": "/world/city", "mapX": .74, "mapY": .24, "voice": "world.city.hello",
         "scenes": ["city.street", "city.park"]},
        {"id": "nature", "card": "card_nature", "title": "طبیعت و حیوانات", "subtitle": "جنگل، باغ، برکه، مزرعه", "art": "cow", "route": "/world/nature", "mapX": .3, "mapY": .5, "voice": "world.nature.hello",
         "scenes": ["nature.forest", "nature.garden", "nature.pond", "nature.farm"]},
        {"id": "art", "card": "card_art", "title": "هنر و نقاشی", "subtitle": "رنگ‌ها، قلم‌مو، نقاشی‌های من", "art": "palette", "route": "/art", "mapX": .72, "mapY": .54, "voice": "world.art.hello"},
        {"id": "music", "card": "card_music", "title": "استودیوی موسیقی", "subtitle": "پیانو، زایلوفون، درام", "art": "drum", "route": "/music", "mapX": .28, "mapY": .8, "voice": "world.music.hello"},
        {"id": "build", "card": "card_build", "title": "کارگاه ساخت‌وساز", "subtitle": "بلوک، جاده، پل، چرخ‌دنده", "art": "crane", "route": "/build", "mapX": .72, "mapY": .82, "voice": "world.build.hello"},
    ],
}

ACTIVITIES = {
    "categories": [
        {"id": "explore", "title": "کاوش", "art": "house", "color": "#FF9D37"},
        {"id": "nature", "title": "طبیعت", "art": "tree", "color": "#6CC24A"},
        {"id": "build", "title": "ساختن", "art": "gear", "color": "#F2B33D"},
        {"id": "art", "title": "هنر", "art": "palette", "color": "#FF8FB8"},
        {"id": "music", "title": "موسیقی", "art": "note", "color": "#A77BEF"},
        {"id": "roleplay", "title": "نقش‌آفرینی", "art": "basket", "color": "#16B9D1"},
        {"id": "puzzles", "title": "پازل", "art": "toy_blocks", "color": "#3778F6"},
    ],
    "activities": [
        *[{"id": s["id"], "title": s["title"], "category": "explore", "art": s["icon"], "route": f"/world/{s['world']}?scene={s['id']}"} for s in HOME + CITY],
        *[{"id": s["id"], "title": s["title"], "category": "nature", "art": s["icon"], "route": f"/world/nature?scene={s['id']}"} for s in NATURE],
        {"id": "build", "title": "کارگاه", "category": "build", "art": "crane", "route": "/build"},
        {"id": "art.draw", "title": "نقاشی", "category": "art", "art": "brush", "route": "/art"},
        {"id": "art.gallery", "title": "نقاشی‌های من", "category": "art", "art": "palette", "route": "/art/gallery"},
        {"id": "music.studio", "title": "استودیو", "category": "music", "art": "drum", "route": "/music"},
        {"id": "music.songs", "title": "آهنگ‌های من", "category": "music", "art": "note", "route": "/music?tab=songs"},
        *[{"id": s["id"], "title": s["title"], "category": "roleplay", "art": s["icon"], "route": f"/play/{s['id']}"} for s in PLAY],
        {"id": "puzzle.shapes", "title": "شکل‌ها", "category": "puzzles", "art": "toy_blocks", "route": "/puzzle/shapes"},
        {"id": "puzzle.sort", "title": "رنگ‌ها", "category": "puzzles", "art": "basket", "route": "/puzzle/sort"},
        {"id": "puzzle.pattern", "title": "الگو", "category": "puzzles", "art": "flower_yellow", "route": "/puzzle/pattern", "minAge": 4},
        {"id": "puzzle.match", "title": "جفت‌ها", "category": "puzzles", "art": "cat", "route": "/puzzle/match", "minAge": 3},
    ],
    "stickers": [
        {"id": "world.home", "art": "house", "title": "خانه‌ی من"},
        {"id": "world.city", "art": "bus", "title": "شهر بازی"},
        {"id": "world.nature", "art": "cow", "title": "طبیعت"},
        {"id": "world.art", "art": "palette", "title": "نقاش کوچولو"},
        {"id": "world.music", "art": "drum", "title": "نوازنده"},
        {"id": "world.build", "art": "crane", "title": "سازنده"},
        {"id": "chef", "art": "pot", "title": "آشپز"},
        {"id": "shopper", "art": "basket", "title": "خریدار"},
        {"id": "gardener", "art": "flower_yellow", "title": "باغبان"},
        {"id": "petcare", "art": "dog", "title": "دوست حیوانات"},
        {"id": "tidy", "art": "toy_blocks", "title": "مرتب"},
        {"id": "puzzle.shapes", "art": "gear", "title": "شکل‌شناس"},
        {"id": "puzzle.sort", "art": "rug", "title": "رنگ‌شناس"},
        {"id": "puzzle.pattern", "art": "flower_purple", "title": "الگوساز"},
        {"id": "puzzle.match", "art": "cat", "title": "حافظه‌ی قوی"},
        {"id": "art.saved", "art": "brush", "title": "اولین نقاشی"},
        {"id": "music.saved", "art": "note", "title": "اولین آهنگ"},
        {"id": "build.gears", "art": "gear", "title": "چرخ‌دنده‌ها"},
        {"id": "garden.bloom", "art": "flower_red", "title": "گل شکفت"},
        {"id": "farm.feed", "art": "hay", "title": "غذای حیوانات"},
    ],
}


def main():
    (OUT / "scenes").mkdir(parents=True, exist_ok=True)
    for name, scenes in (("home", HOME), ("city", CITY), ("nature", NATURE), ("play", PLAY)):
        (OUT / "scenes" / f"{name}.json").write_text(json.dumps({"scenes": scenes}, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    (OUT / "worlds.json").write_text(json.dumps(WORLDS, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    (OUT / "activities.json").write_text(json.dumps(ACTIVITIES, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print("content written")


if __name__ == "__main__":
    main()
