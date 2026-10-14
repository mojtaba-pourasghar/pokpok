#!/usr/bin/env python3
"""Original vector art for POPO, generated from code so every object shares one style.

Every object is drawn on a 200×200 canvas with the same "clay" recipe:
  * a radial gradient per colour (light from the top-left, darker at the bottom-right),
  * an outline in a darker shade of the same colour (never black),
  * a soft white highlight on the upper-left of round shapes,
  * a soft ground shadow under things that stand on the floor.

Output: assets/art/<group>/<id>.svg, then tools/build_manifest.py refreshes
assets/content/asset_manifest.json (id, path, version, size, sha256). The app reads the manifest; a finished raster illustration (WebP) with the same
logical id can later replace an SVG through a content pack without code changes.

    python3 tools/art/build_art.py            # rebuild everything
    python3 tools/art/build_art.py --list     # list ids

No network, no image model: the drawings are original and reproducible.
"""

from __future__ import annotations

import argparse
import colorsys
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/art"

# Palette (matches lib/app/theme/tokens.dart)
ORANGE = "#FF9D37"
TURQ = "#16B9D1"
BLUE = "#3778F6"
GREEN = "#A6D943"
YELLOW = "#FFD34F"
PURPLE = "#A77BEF"
RED = "#F2574E"
PINK = "#FF8FB8"
BROWN = "#B9784A"
WOOD = "#D99A5B"
CREAM = "#FFF1DC"
WHITE = "#FFFFFF"
GREY = "#B8C3D6"
DARK = "#3A3550"
LEAF = "#5DBB46"
SKY = "#BFE6FF"
WATER = "#5CC8F2"


def _hex(c: str) -> tuple[float, float, float]:
    c = c.lstrip("#")
    return tuple(int(c[i : i + 2], 16) / 255 for i in (0, 2, 4))  # type: ignore[return-value]


def _to_hex(rgb) -> str:
    return "#" + "".join(f"{max(0, min(255, round(v * 255))):02X}" for v in rgb)


def shade(c: str, amount: float) -> str:
    """amount > 0 lightens, < 0 darkens (in HLS lightness)."""
    h, l, s = colorsys.rgb_to_hls(*_hex(c))
    return _to_hex(colorsys.hls_to_rgb(h, max(0, min(1, l + amount)), s))


class Svg:
    def __init__(self, w: int = 200, h: int = 200):
        self.w, self.h = w, h
        self.defs: dict[str, str] = {}
        self.body: list[str] = []

    # ── paint ───────────────────────────────────────────────────────────
    def g(self, color: str) -> str:
        gid = "g" + color.lstrip("#").lower()
        if gid not in self.defs:
            self.defs[gid] = (
                f'<radialGradient id="{gid}" cx="35%" cy="30%" r="80%">'
                f'<stop offset="0" stop-color="{shade(color, .12)}"/>'
                f'<stop offset=".55" stop-color="{color}"/>'
                f'<stop offset="1" stop-color="{shade(color, -.10)}"/></radialGradient>'
            )
        return f"url(#{gid})"

    def style(self, color: str, sw: float = 3.5, flat: bool = False) -> str:
        fill = color if flat else self.g(color)
        return f'fill="{fill}" stroke="{shade(color, -.22)}" stroke-width="{sw}" stroke-linejoin="round"'

    def add(self, s: str) -> "Svg":
        self.body.append(s)
        return self

    # ── shapes ──────────────────────────────────────────────────────────
    def circle(self, cx, cy, r, color, sw=3.5, flat=False):
        return self.add(f'<circle cx="{cx}" cy="{cy}" r="{r}" {self.style(color, sw, flat)}/>')

    def ellipse(self, cx, cy, rx, ry, color, sw=3.5, flat=False, rot=0):
        t = f' transform="rotate({rot} {cx} {cy})"' if rot else ""
        return self.add(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}"{t} {self.style(color, sw, flat)}/>')

    def rect(self, x, y, w, h, color, r=10, sw=3.5, flat=False, rot=0):
        t = f' transform="rotate({rot} {x + w / 2} {y + h / 2})"' if rot else ""
        return self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}"{t} {self.style(color, sw, flat)}/>')

    def path(self, d, color, sw=3.5, flat=False):
        return self.add(f'<path d="{d}" {self.style(color, sw, flat)}/>')

    def line(self, d, color, sw=4):
        return self.add(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"/>')

    def plain(self, shape: str, fill: str, opacity: float = 1):
        return self.add(shape.replace("/>", f' fill="{fill}" fill-opacity="{opacity}"/>', 1))

    def shine(self, cx, cy, rx, ry, rot=-25, a=.55):
        return self.add(
            f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" transform="rotate({rot} {cx} {cy})" fill="#FFFFFF" fill-opacity="{a}"/>'
        )

    def shadow(self, cx=100, cy=186, rx=62, ry=9):
        return self.add(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#2A2250" fill-opacity=".14"/>')

    def eye(self, cx, cy, r=6):
        self.add(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{DARK}"/>')
        return self.add(f'<circle cx="{cx - r * .35}" cy="{cy - r * .4}" r="{r * .38}" fill="#FFFFFF"/>')

    def cheek(self, cx, cy, r=6):
        return self.add(f'<ellipse cx="{cx}" cy="{cy}" rx="{r}" ry="{r * .65}" fill="{PINK}" fill-opacity=".55"/>')

    def smile(self, cx, cy, w=10):
        return self.line(f"M{cx - w} {cy} Q{cx} {cy + w * .9} {cx + w} {cy}", DARK, 3.2)

    def render(self) -> str:
        defs = "".join(self.defs.values())
        return (
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {self.w} {self.h}" width="{self.w}" height="{self.h}">'
            f"<defs>{defs}</defs>{''.join(self.body)}</svg>\n"
        )


ART: dict[str, tuple[str, callable]] = {}


def art(group: str):
    def deco(fn):
        ART[fn.__name__] = (group, fn)
        return fn

    return deco


# ═════════════════════════════ animals ══════════════════════════════════
@art("animals")
def cow(s: Svg):
    s.shadow()
    for x in (62, 84, 118, 140):
        s.rect(x - 8, 140, 16, 42, CREAM, r=7)
        s.rect(x - 8, 172, 16, 12, DARK, r=5, flat=True)
    s.ellipse(100, 128, 62, 40, WHITE)
    s.ellipse(80, 118, 18, 14, DARK, sw=0, flat=True)
    s.ellipse(126, 140, 14, 10, DARK, sw=0, flat=True)
    s.line("M162 122 Q178 132 172 152", shade(CREAM, -.3), 4)
    s.ellipse(52, 70, 13, 7, CREAM, rot=-25)
    s.ellipse(124, 70, 13, 7, CREAM, rot=25)
    s.path("M66 62 Q60 46 70 42 M110 62 Q116 46 106 42", YELLOW, 3)
    s.ellipse(88, 88, 34, 32, WHITE)
    s.ellipse(88, 106, 26, 17, PINK)
    s.add(f'<circle cx="80" cy="106" r="3.5" fill="{shade(PINK, -.3)}"/><circle cx="96" cy="106" r="3.5" fill="{shade(PINK, -.3)}"/>')
    s.eye(76, 80, 5.5)
    s.eye(100, 80, 5.5)
    s.shine(66, 102, 22, 10)


@art("animals")
def sheep(s: Svg):
    s.shadow()
    for x in (70, 92, 112, 132):
        s.rect(x - 6, 140, 12, 42, DARK, r=6)
    for (x, y) in ((70, 110), (95, 98), (122, 104), (142, 124), (120, 146), (90, 148), (64, 134), (100, 124)):
        s.circle(x, y, 24, WHITE, sw=3)
    s.ellipse(56, 104, 24, 28, shade(DARK, .25))
    s.ellipse(36, 90, 12, 6, shade(DARK, .25), rot=-20)
    s.circle(56, 80, 14, WHITE, sw=3)
    s.eye(50, 102, 4.5)
    s.eye(64, 102, 4.5)
    s.smile(57, 116, 6)
    s.shine(108, 92, 18, 8)


@art("animals")
def chick(s: Svg):
    s.shadow(100, 184, 44, 7)
    s.path("M86 160 l-6 22 M80 182 h12 M114 160 l6 22 M108 182 h12", ORANGE, 4)
    s.ellipse(100, 128, 48, 44, YELLOW)
    s.ellipse(132, 128, 18, 12, shade(YELLOW, -.06), rot=-30)
    s.circle(100, 76, 32, YELLOW)
    s.path("M94 46 q4 -14 10 0 q6 -10 8 4", ORANGE, 3)
    s.path("M98 82 l14 6 l-14 6 z", ORANGE, 2.5)
    s.eye(88, 72, 5)
    s.eye(110, 72, 5)
    s.cheek(84, 86, 5)
    s.shine(86, 110, 18, 9)


@art("animals")
def hen(s: Svg):
    s.shadow(100, 184, 54, 8)
    s.path("M92 160 l-6 22 M86 182 h12 M116 160 l6 22 M110 182 h12", ORANGE, 4)
    s.path("M150 92 q30 -20 26 20 q-2 30 -26 30 z", shade(BROWN, .1))
    s.ellipse(104, 130, 56, 40, WHITE)
    s.ellipse(110, 126, 26, 16, shade(CREAM, -.04), rot=-15)
    s.circle(70, 84, 26, WHITE)
    s.path("M58 60 q4 -16 12 -4 q6 -14 12 2 q8 -8 6 8 z", RED, 2.5)
    s.path("M46 84 l-16 6 l16 6 z", ORANGE, 2.5)
    s.path("M50 98 q4 14 10 2 z", RED, 2)
    s.eye(66, 80, 5)
    s.shine(84, 118, 22, 10)


@art("animals")
def rabbit(s: Svg):
    s.shadow(100, 184, 50, 8)
    s.ellipse(80, 40, 11, 32, WHITE, rot=-10)
    s.ellipse(80, 42, 5, 22, PINK, sw=0, flat=True, rot=-10)
    s.ellipse(116, 40, 11, 32, WHITE, rot=12)
    s.ellipse(116, 42, 5, 22, PINK, sw=0, flat=True, rot=12)
    s.ellipse(100, 140, 44, 42, WHITE)
    s.circle(146, 152, 12, WHITE)
    s.ellipse(80, 178, 16, 8, WHITE)
    s.ellipse(120, 178, 16, 8, WHITE)
    s.circle(98, 92, 34, WHITE)
    s.eye(86, 88, 5.5)
    s.eye(110, 88, 5.5)
    s.add(f'<ellipse cx="98" cy="100" rx="5" ry="3.5" fill="{PINK}"/>')
    s.smile(98, 106, 6)
    s.cheek(78, 102, 6)
    s.cheek(118, 102, 6)
    s.shine(84, 128, 18, 10)


@art("animals")
def duck(s: Svg):
    s.ellipse(100, 160, 70, 14, WATER, sw=0, flat=True)
    s.add('<ellipse cx="100" cy="160" rx="70" ry="14" fill="#FFFFFF" fill-opacity=".25"/>')
    s.path("M40 130 q0 -30 50 -28 l60 0 q24 0 22 18 q-4 32 -66 34 q-66 2 -66 -24 z", YELLOW)
    s.path("M156 106 q20 -14 22 4 q-6 10 -22 6 z", YELLOW, 3)
    s.path("M74 120 q20 -10 40 4 q-18 14 -40 -4 z", shade(YELLOW, -.06), 2.5)
    s.circle(62, 82, 26, YELLOW)
    s.path("M38 88 q-18 2 -20 8 q10 8 24 2 z", ORANGE, 2.5)
    s.eye(58, 76, 5)
    s.cheek(70, 92, 5)
    s.shine(56, 70, 10, 6)


@art("animals")
def frog(s: Svg):
    s.shadow(100, 182, 58, 8)
    s.ellipse(100, 140, 58, 40, GREEN)
    s.ellipse(100, 150, 34, 24, shade(GREEN, .2), sw=0, flat=True)
    s.ellipse(52, 172, 22, 10, GREEN)
    s.ellipse(148, 172, 22, 10, GREEN)
    s.circle(72, 92, 20, GREEN)
    s.circle(128, 92, 20, GREEN)
    s.circle(72, 90, 12, WHITE, sw=2)
    s.circle(128, 90, 12, WHITE, sw=2)
    s.eye(74, 92, 6)
    s.eye(126, 92, 6)
    s.line("M70 124 Q100 146 130 124", shade(GREEN, -.35), 4)
    s.cheek(60, 120, 7)
    s.cheek(140, 120, 7)


@art("animals")
def bird(s: Svg):
    s.ellipse(104, 104, 50, 40, BLUE)
    s.path("M150 96 l30 -10 l-18 26 z", BLUE)
    s.ellipse(106, 116, 30, 20, shade(BLUE, .25), sw=0, flat=True)
    s.path("M96 92 q30 -6 40 22 q-30 4 -40 -22 z", shade(BLUE, -.08), 3)
    s.path("M56 98 l-22 8 l22 6 z", ORANGE, 2.5)
    s.eye(74, 92, 5.5)
    s.cheek(78, 108, 5)
    s.path("M96 66 q2 -14 10 -10 q-2 6 -6 12", BLUE, 2.5)
    s.line("M92 142 l-4 14 M112 142 l4 14", ORANGE, 4)
    s.shine(84, 84, 14, 7)


@art("animals")
def butterfly(s: Svg):
    s.ellipse(70, 74, 36, 40, PURPLE, rot=-20)
    s.ellipse(130, 74, 36, 40, PURPLE, rot=20)
    s.ellipse(76, 130, 26, 28, PINK, rot=20)
    s.ellipse(124, 130, 26, 28, PINK, rot=-20)
    s.circle(66, 70, 10, YELLOW, sw=2)
    s.circle(134, 70, 10, YELLOW, sw=2)
    s.ellipse(100, 104, 10, 46, DARK, flat=True, sw=0)
    s.line("M96 60 q-10 -22 -22 -26 M104 60 q10 -22 22 -26", DARK, 3)
    s.eye(95, 66, 2.5)
    s.eye(105, 66, 2.5)


@art("animals")
def bee(s: Svg):
    s.ellipse(80, 66, 26, 20, "#E9F6FF", sw=2.5, rot=-30)
    s.ellipse(118, 62, 26, 20, "#E9F6FF", sw=2.5, rot=30)
    s.ellipse(100, 112, 54, 40, YELLOW)
    s.add(f'<path d="M84 76 q-8 36 0 72 h16 q-8 -36 0 -72 z" fill="{DARK}"/>')
    s.add(f'<path d="M116 76 q-8 36 0 72 h14 q-6 -36 2 -70 z" fill="{DARK}"/>')
    s.path("M154 112 l16 0 l-16 8 z", DARK, 2)
    s.eye(62, 104, 5)
    s.smile(64, 120, 6)
    s.cheek(54, 118, 5)


@art("animals")
def fish(s: Svg):
    s.path("M140 100 l40 -30 q-8 30 0 60 z", ORANGE)
    s.ellipse(96, 100, 56, 40, ORANGE)
    s.path("M86 62 q20 -24 40 2 z", shade(ORANGE, -.05), 3)
    s.path("M80 100 q14 -18 0 -36 M104 104 q14 -22 0 -42", WHITE, 0)
    s.line("M100 70 q12 30 0 60", shade(ORANGE, .2), 5)
    s.eye(62, 92, 6)
    s.smile(54, 112, 6)
    s.shine(76, 82, 18, 8)


@art("animals")
def dog(s: Svg):
    s.shadow()
    for x in (66, 88, 116, 138):
        s.rect(x - 8, 136, 16, 44, BROWN, r=7)
    s.ellipse(104, 128, 54, 34, WOOD)
    s.line("M156 118 q20 -20 14 -36", WOOD, 9)
    s.circle(66, 84, 34, WOOD)
    s.ellipse(38, 88, 12, 24, BROWN, rot=15)
    s.ellipse(96, 88, 12, 24, BROWN, rot=-15)
    s.ellipse(66, 100, 18, 13, CREAM)
    s.add(f'<ellipse cx="66" cy="94" rx="6" ry="4.5" fill="{DARK}"/>')
    s.eye(56, 78, 5)
    s.eye(78, 78, 5)
    s.smile(66, 104, 6)
    s.add(f'<path d="M62 110 q4 12 8 0" fill="{RED}"/>')
    s.shine(94, 114, 20, 8)


@art("animals")
def cat(s: Svg):
    s.shadow(100, 184, 50, 8)
    s.line("M140 160 q36 -10 24 -50", ORANGE, 9)
    s.ellipse(100, 146, 42, 36, shade(ORANGE, .08))
    s.path("M64 74 l6 -36 l24 20 z", shade(ORANGE, .08))
    s.path("M136 74 l-6 -36 l-24 20 z", shade(ORANGE, .08))
    s.circle(100, 92, 36, shade(ORANGE, .08))
    s.eye(86, 88, 5.5)
    s.eye(114, 88, 5.5)
    s.add(f'<path d="M96 100 h8 l-4 5 z" fill="{PINK}"/>')
    s.line("M92 110 q8 6 16 0", DARK, 3)
    s.line("M70 100 l-18 -3 M70 106 l-18 4 M130 100 l18 -3 M130 106 l18 4", shade(ORANGE, -.3), 2.4)
    s.cheek(78, 104, 5)
    s.cheek(122, 104, 5)


@art("animals")
def horse(s: Svg):
    s.shadow()
    for x in (62, 82, 120, 140):
        s.rect(x - 7, 132, 14, 48, BROWN, r=6)
        s.rect(x - 8, 172, 16, 10, DARK, r=4, flat=True)
    s.ellipse(102, 124, 56, 30, BROWN)
    s.line("M156 116 q22 6 18 40", DARK, 9)
    s.path("M52 120 l-6 -60 q4 -18 24 -16 l20 6 q8 22 -8 40 z", BROWN)
    s.ellipse(44, 64, 18, 28, BROWN, rot=30)
    s.ellipse(34, 80, 11, 9, shade(BROWN, .2), sw=0, flat=True)
    s.path("M70 44 q12 18 6 50 q14 -20 14 -46 z", DARK, 2)
    s.path("M58 40 l2 -16 l10 14 z", BROWN, 2.5)
    s.eye(52, 58, 4.5)
    s.shine(96, 112, 22, 8)


# ═════════════════════════════ plants & nature ══════════════════════════
@art("nature")
def tree(s: Svg):
    s.shadow(100, 188, 48, 7)
    s.path("M88 190 q4 -50 0 -80 h24 q-4 30 0 80 z", BROWN)
    for (x, y, r) in ((70, 92, 40), (130, 92, 40), (100, 58, 46), (100, 110, 40)):
        s.circle(x, y, r, LEAF)
    s.shine(84, 50, 22, 12)
    for (x, y) in ((76, 84), (122, 70), (118, 116)):
        s.circle(x, y, 7, RED, sw=2)


@art("nature")
def pine(s: Svg):
    s.shadow(100, 188, 40, 6)
    s.rect(90, 150, 20, 38, BROWN, r=5)
    s.path("M100 14 l44 64 h-20 l32 44 h-24 l28 40 h-120 l28 -40 h-24 l32 -44 h-20 z", shade(LEAF, -.08))
    s.shine(84, 70, 8, 22, rot=30, a=.35)


@art("nature")
def bush(s: Svg):
    s.shadow(100, 180, 70, 8)
    for (x, y, r) in ((60, 140, 34), (100, 120, 42), (140, 140, 34)):
        s.circle(x, y, r, LEAF)
    s.shine(86, 104, 16, 8)
    s.circle(70, 132, 6, PINK, sw=2)
    s.circle(126, 124, 6, YELLOW, sw=2)


@art("nature")
def flower_red(s: Svg):
    _flower(s, RED)


@art("nature")
def flower_yellow(s: Svg):
    _flower(s, YELLOW)


@art("nature")
def flower_purple(s: Svg):
    _flower(s, PURPLE)


def _flower(s: Svg, petal: str):
    s.line("M100 190 q-6 -50 0 -90", shade(LEAF, -.1), 7)
    s.ellipse(80, 150, 20, 8, LEAF, rot=-30)
    s.ellipse(120, 140, 20, 8, LEAF, rot=30)
    for i in range(6):
        import math

        a = i * math.pi / 3
        s.ellipse(100 + 26 * math.cos(a), 72 + 26 * math.sin(a), 18, 14, petal, rot=i * 60)
    s.circle(100, 72, 18, YELLOW if petal != YELLOW else ORANGE)
    s.eye(94, 70, 2.8)
    s.eye(106, 70, 2.8)
    s.smile(100, 78, 4)


@art("nature")
def sprout(s: Svg):
    s.ellipse(100, 176, 50, 12, BROWN)
    s.line("M100 172 q-2 -40 0 -64", LEAF, 6)
    s.ellipse(78, 104, 24, 12, LEAF, rot=-30)
    s.ellipse(122, 100, 24, 12, LEAF, rot=30)


@art("nature")
def seed(s: Svg):
    s.ellipse(100, 166, 56, 14, BROWN)
    s.ellipse(100, 140, 14, 20, shade(BROWN, .15))
    s.shine(95, 132, 4, 7)


@art("nature")
def mushroom(s: Svg):
    s.shadow(100, 186, 40, 6)
    s.path("M80 186 q-4 -40 4 -64 h32 q8 24 4 64 z", CREAM)
    s.path("M36 120 q4 -70 64 -70 q60 0 64 70 z", RED)
    for (x, y, r) in ((70, 92, 9), (106, 74, 11), (138, 100, 8)):
        s.circle(x, y, r, WHITE, sw=0, flat=True)
    s.eye(90, 152, 4)
    s.eye(110, 152, 4)


@art("nature")
def sun(s: Svg):
    import math

    for i in range(10):
        a = i * math.pi / 5
        x, y = 100 + 74 * math.cos(a), 100 + 74 * math.sin(a)
        s.ellipse(x, y, 14, 8, ORANGE, rot=math.degrees(a))
    s.circle(100, 100, 56, YELLOW)
    s.eye(82, 94, 6)
    s.eye(118, 94, 6)
    s.smile(100, 112, 14)
    s.cheek(74, 114, 8)
    s.cheek(126, 114, 8)
    s.shine(78, 72, 18, 9)


@art("nature")
def cloud(s: Svg):
    for (x, y, r) in ((64, 116, 30), (100, 96, 40), (140, 114, 32)):
        s.circle(x, y, r, WHITE, sw=3)
    s.rect(40, 112, 124, 32, WHITE, r=16, sw=0, flat=True)
    s.line("M38 128 q0 16 22 16 h88 q22 0 22 -18", shade(WHITE, -.22), 3)


@art("nature")
def watering_can(s: Svg):
    s.shadow(100, 182, 60, 7)
    s.path("M140 110 l44 -40 l8 8 l-36 50 z", TURQ)
    s.rect(52, 96, 92, 82, TURQ, r=18)
    s.path("M60 100 q30 -46 76 0", TURQ, 6)
    s.line("M60 100 q30 -46 76 0", shade(TURQ, .2), 4)
    s.shine(74, 116, 12, 22, rot=0)


@art("nature")
def carrot(s: Svg):
    s.path("M96 50 q-16 -26 -8 -36 q10 8 12 30 q4 -26 18 -30 q4 14 -14 38 z", LEAF)
    s.path("M70 56 q30 -14 60 0 q-10 70 -30 128 q-20 -58 -30 -128 z", ORANGE)
    s.line("M84 86 l12 4 M90 116 l10 4 M110 74 l-10 4", shade(ORANGE, -.25), 3)


@art("nature")
def pond(s: Svg):
    s.ellipse(100, 120, 92, 44, shade(WATER, -.05))
    s.ellipse(100, 116, 80, 34, WATER, sw=0)
    s.ellipse(70, 110, 22, 8, WHITE, sw=0, flat=True)
    s.plain('<ellipse cx="70" cy="110" rx="22" ry="8"/>', WHITE, .4)


@art("nature")
def lily(s: Svg):
    s.path("M100 100 l60 -10 a60 30 0 1 1 -10 -16 z", shade(LEAF, -.05))
    s.circle(120, 96, 14, PINK, sw=2.5)
    s.circle(120, 96, 6, YELLOW, sw=0, flat=True)


@art("nature")
def rock(s: Svg):
    s.shadow(100, 170, 62, 8)
    s.path("M36 166 q-6 -50 30 -70 q40 -22 74 6 q28 24 22 64 z", GREY)
    s.shine(76, 110, 20, 8)


@art("nature")
def hay(s: Svg):
    s.shadow(100, 182, 64, 8)
    s.rect(36, 96, 128, 84, YELLOW, r=20)
    s.line("M52 120 h96 M52 150 h96", shade(YELLOW, -.2), 4)
    s.line("M70 96 v84 M130 96 v84", shade(BROWN, -.05), 5)


@art("nature")
def barn(s: Svg):
    s.shadow(100, 188, 80, 8)
    s.rect(30, 86, 140, 100, RED, r=6)
    s.path("M20 92 l80 -60 l80 60 z", shade(RED, -.1))
    s.rect(74, 118, 52, 68, WHITE, r=4)
    s.line("M74 118 l52 68 M126 118 l-52 68", RED, 4)
    s.circle(100, 66, 12, WHITE)


# ═════════════════════════════ home ═════════════════════════════════════
@art("home")
def sofa(s: Svg):
    s.shadow(100, 176, 86, 8)
    s.rect(28, 72, 144, 64, PURPLE, r=24)
    s.rect(14, 104, 36, 64, PURPLE, r=16)
    s.rect(150, 104, 36, 64, PURPLE, r=16)
    s.rect(40, 116, 120, 44, shade(PURPLE, .08), r=14)
    s.line("M100 120 v36", shade(PURPLE, -.15), 3)
    s.rect(28, 164, 12, 14, BROWN, r=3)
    s.rect(160, 164, 12, 14, BROWN, r=3)
    s.circle(64, 100, 14, YELLOW)
    s.shine(60, 88, 30, 8, rot=0, a=.3)


@art("home")
def armchair(s: Svg):
    s.shadow(100, 180, 64, 8)
    s.rect(46, 50, 108, 84, TURQ, r=28)
    s.rect(30, 100, 34, 72, TURQ, r=14)
    s.rect(136, 100, 34, 72, TURQ, r=14)
    s.rect(56, 120, 88, 44, shade(TURQ, .1), r=14)
    s.shine(70, 70, 22, 8, rot=0, a=.3)


@art("home")
def lamp(s: Svg):
    s.shadow(100, 186, 34, 6)
    s.ellipse(100, 178, 30, 9, DARK)
    s.line("M100 176 V82", shade(DARK, .25), 7)
    s.path("M58 84 l18 -60 h48 l18 60 z", YELLOW)
    s.shine(84, 50, 8, 18, rot=10, a=.4)


@art("home")
def table(s: Svg):
    s.shadow(100, 186, 76, 7)
    s.rect(24, 92, 152, 22, WOOD, r=8)
    s.rect(40, 112, 14, 72, shade(WOOD, -.06), r=5)
    s.rect(146, 112, 14, 72, shade(WOOD, -.06), r=5)
    s.shine(80, 98, 40, 4, rot=0, a=.35)


@art("home")
def tv(s: Svg):
    s.shadow(100, 186, 60, 7)
    s.rect(70, 160, 60, 20, DARK, r=6)
    s.rect(18, 40, 164, 118, DARK, r=14)
    s.rect(28, 50, 144, 98, "#2B3D6E", r=8, sw=0)
    s.plain('<path d="M28 120 q50 -40 144 -10 v38 h-144 z"/>', "#4D6BB5", .9)
    s.shine(60, 66, 26, 8, a=.25)


@art("home")
def plant(s: Svg):
    s.shadow(100, 186, 38, 6)
    for rot in (-40, -15, 15, 40):
        s.ellipse(100 + rot, 86, 12, 40, LEAF, rot=rot)
    s.path("M64 120 h72 l-10 64 h-52 z", ORANGE)
    s.rect(58, 112, 84, 16, shade(ORANGE, -.05), r=6)


@art("home")
def bookshelf(s: Svg):
    s.shadow(100, 190, 66, 7)
    s.rect(40, 16, 120, 172, WOOD, r=8)
    for y in (24, 80, 136):
        s.rect(48, y, 104, 48, shade(WOOD, -.18), r=4, sw=0, flat=True)
        x = 52
        for i, c in enumerate((RED, BLUE, YELLOW, GREEN, PURPLE)):
            w = 14 + (i % 2) * 4
            s.rect(x, y + 8 + (i % 3) * 3, w, 40 - (i % 3) * 3, c, r=3, sw=2)
            x += w + 4


@art("home")
def rug(s: Svg):
    s.ellipse(100, 110, 94, 40, PINK)
    s.ellipse(100, 110, 70, 28, shade(PINK, .08), sw=2.5)
    s.ellipse(100, 110, 44, 16, YELLOW, sw=2.5)


@art("home")
def bed(s: Svg):
    s.shadow(100, 186, 92, 8)
    s.rect(14, 56, 30, 126, WOOD, r=10)
    s.rect(20, 110, 168, 44, WHITE, r=10)
    s.rect(60, 100, 128, 54, BLUE, r=14)
    s.line("M84 116 h80 M84 134 h80", shade(BLUE, .2), 4)
    s.ellipse(56, 100, 22, 14, WHITE)
    s.rect(18, 150, 170, 20, WOOD, r=6)


@art("home")
def teddy(s: Svg):
    """A toy bunny — kept clearly different from Popo so the mascot stays unique."""
    s.shadow(100, 184, 40, 6)
    s.ellipse(84, 48, 9, 24, PINK, rot=-12)
    s.ellipse(116, 48, 9, 24, PINK, rot=12)
    s.ellipse(100, 146, 34, 36, PINK)
    s.circle(100, 92, 30, PINK)
    s.ellipse(100, 150, 18, 20, shade(PINK, .15), sw=0, flat=True)
    s.eye(90, 88, 4)
    s.eye(110, 88, 4)
    s.smile(100, 100, 5)
    s.ellipse(68, 146, 10, 18, PINK, rot=-20)
    s.ellipse(132, 146, 10, 18, PINK, rot=20)


@art("home")
def ball(s: Svg):
    s.shadow(100, 182, 48, 7)
    s.circle(100, 112, 64, RED)
    s.add(f'<path d="M100 48 q-40 64 0 128 q-26 -64 0 -128 z" fill="{WHITE}" fill-opacity=".9"/>')
    s.add(f'<path d="M38 100 q64 -20 124 0 q-62 -8 -124 0 z" fill="{YELLOW}"/>')
    s.shine(74, 82, 18, 10)


@art("home")
def toy_blocks(s: Svg):
    s.shadow(100, 184, 62, 7)
    s.rect(40, 120, 56, 56, RED, r=8)
    s.rect(104, 120, 56, 56, BLUE, r=8)
    s.rect(72, 62, 56, 56, YELLOW, r=8)
    s.add('<text x="68" y="160" font-size="32" font-weight="900" text-anchor="middle" fill="#FFFFFF" font-family="sans-serif">A</text>')
    s.add('<text x="132" y="160" font-size="32" font-weight="900" text-anchor="middle" fill="#FFFFFF" font-family="sans-serif">B</text>')
    s.add('<text x="100" y="102" font-size="32" font-weight="900" text-anchor="middle" fill="#FFFFFF" font-family="sans-serif">C</text>')


@art("home")
def fridge(s: Svg):
    s.shadow(100, 190, 54, 7)
    s.rect(48, 10, 104, 178, "#E9F2FF", r=16)
    s.line("M50 76 h100", shade(GREY, -.1), 4)
    s.rect(62, 30, 8, 30, GREY, r=4, sw=2)
    s.rect(62, 90, 8, 40, GREY, r=4, sw=2)
    s.circle(122, 46, 10, RED, sw=2)
    s.circle(132, 110, 8, YELLOW, sw=2)


@art("home")
def stove(s: Svg):
    s.shadow(100, 190, 70, 7)
    s.rect(30, 70, 140, 116, WHITE, r=12)
    s.rect(46, 112, 108, 60, DARK, r=8)
    s.rect(54, 120, 92, 44, "#4A4A6A", r=6, sw=0)
    s.ellipse(70, 70, 22, 6, DARK, flat=True, sw=0)
    s.ellipse(130, 70, 22, 6, DARK, flat=True, sw=0)
    for x in (60, 84, 116, 140):
        s.circle(x, 92, 6, GREY, sw=2)


@art("home")
def pot(s: Svg):
    s.shadow(100, 176, 58, 7)
    s.rect(40, 88, 120, 84, RED, r=18)
    s.rect(30, 80, 140, 18, shade(RED, -.04), r=9)
    s.rect(14, 104, 30, 14, DARK, r=7)
    s.rect(156, 104, 30, 14, DARK, r=7)
    s.shine(66, 118, 10, 22, rot=0, a=.35)


@art("home")
def pan(s: Svg):
    s.ellipse(86, 116, 70, 30, DARK)
    s.ellipse(86, 110, 58, 20, "#5A5A7A", sw=0)
    s.rect(150, 104, 48, 14, BROWN, r=7)


@art("home")
def plate(s: Svg):
    s.ellipse(100, 120, 84, 36, WHITE)
    s.ellipse(100, 116, 56, 22, shade(WHITE, -.04), sw=2.5)


@art("home")
def cup(s: Svg):
    s.shadow(100, 176, 40, 6)
    s.path("M58 76 h84 l-8 96 h-68 z", TURQ)
    s.path("M140 96 q30 0 26 30 q-4 22 -30 20", TURQ, 6)
    s.line("M140 96 q30 0 26 30 q-4 22 -30 20", shade(TURQ, .2), 3)
    s.ellipse(100, 76, 42, 8, shade(BROWN, .1), sw=2)
    s.line("M84 60 q-6 -16 4 -28 M108 60 q-6 -16 4 -28", GREY, 4)


@art("home")
def bathtub(s: Svg):
    s.shadow(100, 186, 90, 8)
    s.rect(14, 92, 172, 76, WHITE, r=30)
    s.ellipse(100, 98, 84, 12, WATER, sw=2)
    for (x, y, r) in ((50, 90, 16), (76, 82, 18), (110, 86, 14), (140, 82, 18)):
        s.circle(x, y, r, WHITE, sw=2)
    s.rect(40, 164, 14, 20, GREY, r=5)
    s.rect(146, 164, 14, 20, GREY, r=5)
    s.path("M170 92 v-50 q0 -14 -14 -14 h-10", GREY, 6)


@art("home")
def rubber_duck(s: Svg):
    s.ellipse(102, 136, 62, 40, YELLOW)
    s.path("M150 122 q24 -10 22 10 q-14 6 -22 -4 z", YELLOW, 3)
    s.circle(78, 84, 34, YELLOW)
    s.path("M46 90 q-22 4 -22 10 q12 8 28 0 z", ORANGE, 2.5)
    s.eye(74, 76, 5.5)
    s.cheek(88, 94, 6)
    s.shine(70, 68, 12, 7)


@art("home")
def towel(s: Svg):
    s.rect(40, 30, 120, 12, GREY, r=6)
    s.rect(52, 36, 96, 140, TURQ, r=10)
    s.line("M52 150 h96 M52 158 h96", WHITE, 4)


@art("home")
def soap(s: Svg):
    s.ellipse(100, 140, 70, 18, TURQ)
    s.rect(52, 96, 96, 42, PINK, r=20)
    for (x, y, r) in ((70, 80, 12), (96, 66, 16), (124, 82, 10)):
        s.circle(x, y, r, "#E6F7FF", sw=2)


@art("home")
def toothbrush(s: Svg):
    s.rect(30, 110, 130, 18, BLUE, r=9, rot=-15)
    s.rect(130, 72, 40, 20, WHITE, r=4, rot=-15)
    for x in (134, 144, 154, 164):
        s.line(f"M{x} 72 l-4 -16", TURQ, 5)


@art("home")
def apple(s: Svg):
    s.line("M100 58 q2 -20 10 -28", BROWN, 5)
    s.ellipse(120, 44, 16, 8, LEAF, rot=-30)
    s.path("M100 62 q-40 -20 -60 20 q-14 50 26 82 q18 14 34 4 q16 10 34 -4 q40 -32 26 -82 q-20 -40 -60 -20 z", RED)
    s.shine(70, 86, 10, 18, rot=20)


@art("home")
def banana(s: Svg):
    s.path("M40 60 q10 100 120 96 q8 -4 -2 -10 q-90 -10 -100 -88 q-6 -8 -18 2 z", YELLOW)
    s.line("M40 60 l-6 -10", BROWN, 6)


@art("home")
def bread(s: Svg):
    s.shadow(100, 170, 70, 7)
    s.path("M30 110 q0 -50 70 -50 q70 0 70 50 v52 h-140 z", WOOD)
    s.line("M70 80 l14 22 M100 76 l14 22 M130 80 l14 22", shade(WOOD, .15), 5)


@art("home")
def milk(s: Svg):
    s.shadow(100, 186, 40, 6)
    s.path("M64 60 l14 -26 h44 l14 26 v122 h-72 z", WHITE)
    s.rect(64, 96, 72, 56, BLUE, r=0, sw=0)
    s.ellipse(100, 124, 16, 12, WHITE, sw=0, flat=True)
    s.rect(84, 22, 32, 14, RED, r=4)


@art("home")
def cheese(s: Svg):
    s.path("M30 150 l140 -50 v70 h-140 z", YELLOW)
    s.path("M30 150 l140 -50 l-50 -20 z", shade(YELLOW, .08))
    for (x, y, r) in ((70, 156, 8), (120, 140, 10), (150, 160, 6)):
        s.circle(x, y, r, shade(YELLOW, -.12), sw=0, flat=True)


@art("home")
def basket(s: Svg):
    s.path("M50 96 q50 -90 100 0", BROWN, 7)
    s.line("M50 96 q50 -90 100 0", shade(WOOD, .1), 4)
    s.path("M26 96 h148 l-18 80 h-112 z", WOOD)
    s.line("M38 120 h124 M44 146 h112", shade(WOOD, -.2), 4)


@art("home")
def bowl(s: Svg):
    s.path("M30 110 h140 q0 60 -70 60 q-70 0 -70 -60 z", BLUE)
    s.ellipse(100, 110, 70, 14, shade(BROWN, .05))
    s.circle(84, 104, 6, WOOD, sw=2)
    s.circle(104, 100, 6, WOOD, sw=2)
    s.circle(120, 106, 6, WOOD, sw=2)


@art("home")
def window(s: Svg):
    s.rect(30, 20, 140, 150, WHITE, r=14)
    s.rect(42, 32, 116, 126, SKY, r=8, sw=2)
    s.circle(126, 70, 18, YELLOW, sw=2)
    s.ellipse(76, 66, 22, 10, WHITE, sw=0, flat=True)
    s.line("M100 32 v126 M42 95 h116", WHITE, 7)


@art("home")
def clock(s: Svg):
    s.circle(100, 100, 76, ORANGE)
    s.circle(100, 100, 60, WHITE, sw=3)
    s.line("M100 100 V56 M100 100 L130 112", DARK, 6)
    s.circle(100, 100, 6, DARK, flat=True, sw=0)


# ═════════════════════════════ city ═════════════════════════════════════
def _wheels(s: Svg, xs, y=158, r=17):
    for x in xs:
        s.circle(x, y, r, DARK)
        s.circle(x, y, r * .45, GREY, sw=2)


@art("city")
def car(s: Svg):
    s.shadow(100, 176, 80, 7)
    s.path("M50 96 q14 -44 50 -44 q36 0 50 44 z", RED)
    s.rect(18, 92, 164, 58, RED, r=22)
    s.path("M64 92 q10 -28 32 -28 v28 z", SKY, 2.5)
    s.path("M106 92 v-28 q24 0 32 28 z", SKY, 2.5)
    s.circle(176, 112, 7, YELLOW, sw=2)
    _wheels(s, (58, 144))
    s.shine(60, 108, 30, 6, rot=0, a=.4)


@art("city")
def bus(s: Svg):
    s.shadow(100, 180, 92, 7)
    s.rect(10, 52, 180, 104, YELLOW, r=20)
    for x in (24, 66, 108):
        s.rect(x, 66, 34, 32, SKY, r=6, sw=2.5)
    s.rect(150, 66, 28, 66, SKY, r=6, sw=2.5)
    s.line("M14 112 h134", ORANGE, 6)
    _wheels(s, (48, 150), 158)
    s.shine(60, 60, 40, 5, rot=0, a=.4)


@art("city")
def truck(s: Svg):
    s.shadow(100, 180, 92, 7)
    s.rect(10, 60, 116, 92, BLUE, r=10)
    s.path("M126 82 h36 q22 0 28 30 v40 h-64 z", ORANGE)
    s.rect(140, 90, 30, 26, SKY, r=5, sw=2.5)
    _wheels(s, (44, 98, 160), 158)


@art("city")
def taxi(s: Svg):
    s.shadow(100, 176, 80, 7)
    s.path("M50 96 q14 -44 50 -44 q36 0 50 44 z", YELLOW)
    s.rect(18, 92, 164, 58, YELLOW, r=22)
    s.rect(80, 38, 40, 16, DARK, r=4)
    s.path("M64 92 q10 -28 32 -28 v28 z", SKY, 2.5)
    s.path("M106 92 v-28 q24 0 32 28 z", SKY, 2.5)
    for i in range(8):
        s.rect(26 + i * 19, 118, 9, 9, DARK if i % 2 else WHITE, r=1, sw=0, flat=True)
    _wheels(s, (58, 144))


@art("city")
def bicycle(s: Svg):
    for x in (52, 148):
        s.circle(x, 136, 34, DARK, sw=6, flat=True)
        s.circle(x, 136, 28, WHITE, sw=0, flat=True)
    s.line("M52 136 L88 84 L134 84 L148 136 M88 84 L100 136 L134 84 M100 136 L52 136", RED, 7)
    s.line("M84 74 h18 M134 84 l-6 -24 h16", DARK, 6)


@art("city")
def house(s: Svg):
    s.shadow(100, 190, 78, 7)
    s.rect(34, 86, 132, 100, CREAM, r=8)
    s.path("M20 94 l80 -70 l80 70 z", RED)
    s.rect(82, 122, 36, 64, WOOD, r=8)
    s.rect(46, 108, 28, 28, SKY, r=5, sw=2.5)
    s.rect(126, 108, 28, 28, SKY, r=5, sw=2.5)
    s.circle(110, 154, 3, DARK, sw=0, flat=True)


@art("city")
def house_blue(s: Svg):
    s.shadow(100, 190, 78, 7)
    s.rect(30, 70, 140, 116, shade(BLUE, .32), r=8)
    s.path("M20 78 h160 l-20 -54 h-120 z", BLUE)
    for x in (44, 84, 124):
        s.rect(x, 90, 30, 28, SKY, r=5, sw=2.5)
    s.rect(82, 136, 36, 50, ORANGE, r=8)


@art("city")
def shop(s: Svg):
    s.shadow(100, 190, 84, 7)
    s.rect(24, 60, 152, 126, WHITE, r=8)
    s.path("M16 60 h168 l-8 30 h-152 z", GREEN)
    for i in range(6):
        s.add(f'<path d="M{24 + i * 26} 90 q13 16 26 0" fill="{WHITE if i % 2 else GREEN}" stroke="{shade(GREEN, -.22)}" stroke-width="2.5"/>')
    s.rect(36, 108, 70, 50, SKY, r=6, sw=2.5)
    s.circle(56, 140, 8, RED, sw=2)
    s.circle(80, 140, 8, ORANGE, sw=2)
    s.rect(118, 108, 46, 78, WOOD, r=6)


@art("city")
def traffic_light(s: Svg):
    s.shadow(100, 192, 30, 5)
    s.rect(92, 110, 16, 80, GREY, r=5)
    s.rect(70, 14, 60, 112, DARK, r=14)
    s.circle(100, 42, 14, RED, sw=2)
    s.circle(100, 72, 14, YELLOW, sw=2)
    s.circle(100, 102, 14, LEAF, sw=2)


@art("city")
def fountain(s: Svg):
    s.ellipse(100, 160, 84, 22, GREY)
    s.ellipse(100, 154, 70, 14, WATER, sw=0)
    s.rect(88, 90, 24, 64, GREY, r=6)
    s.ellipse(100, 92, 40, 10, GREY)
    s.line("M100 86 q-30 -50 -56 30 M100 86 q30 -50 56 30 M100 86 v-50", WATER, 5)


@art("city")
def bench(s: Svg):
    s.shadow(100, 176, 76, 7)
    s.rect(24, 80, 152, 18, WOOD, r=6)
    s.rect(24, 104, 152, 18, WOOD, r=6)
    s.rect(24, 128, 152, 16, WOOD, r=6)
    s.rect(36, 140, 12, 36, DARK, r=4)
    s.rect(152, 140, 12, 36, DARK, r=4)


@art("city")
def bus_stop(s: Svg):
    s.shadow(100, 192, 40, 5)
    s.rect(94, 60, 12, 130, GREY, r=5)
    s.circle(100, 50, 34, BLUE)
    s.add('<rect x="84" y="36" width="32" height="26" rx="6" fill="#FFFFFF"/>')
    s.add(f'<rect x="88" y="40" width="24" height="12" rx="3" fill="{BLUE}"/>')


# ═════════════════════════════ music & art & construction ════════════════
@art("music")
def guitar(s: Svg):
    s.rect(92, 10, 16, 90, BROWN, r=4, rot=30)
    s.path("M58 116 q-30 -40 10 -56 q22 -6 30 14 q22 -6 30 14 q30 30 -6 70 q-34 34 -64 -42 z", ORANGE)
    s.circle(86, 112, 12, DARK, flat=True, sw=0)


@art("music")
def drum(s: Svg):
    s.shadow(100, 184, 70, 7)
    s.rect(32, 80, 136, 96, RED, r=14)
    s.ellipse(100, 80, 68, 20, WHITE)
    s.line("M36 100 l30 70 l32 -70 l32 70 l32 -70", YELLOW, 4)
    s.line("M150 30 l-30 44 M50 30 l30 44", WOOD, 7)


@art("music")
def trumpet(s: Svg):
    s.path("M30 90 h90 l50 -30 v80 l-50 -30 h-90 z", YELLOW)
    s.rect(70, 70, 10, 26, YELLOW, r=4, sw=2)
    s.rect(88, 70, 10, 26, YELLOW, r=4, sw=2)


@art("music")
def note(s: Svg):
    s.line("M120 40 v100", DARK, 9)
    s.path("M120 40 q40 10 40 40 q-10 -20 -40 -20 z", DARK, 2)
    s.ellipse(96, 144, 30, 22, PURPLE, rot=-20)


@art("art")
def palette(s: Svg):
    s.path("M100 30 q72 0 72 64 q0 40 -40 40 q-20 0 -20 18 q0 26 -22 26 q-62 0 -62 -76 q0 -72 72 -72 z", WOOD)
    for (x, y, c) in ((66, 70, RED), (100, 56, YELLOW), (136, 74, BLUE), (62, 112, GREEN), (88, 140, PURPLE)):
        s.circle(x, y, 13, c, sw=2.5)


@art("art")
def brush(s: Svg):
    s.rect(84, 20, 26, 110, BLUE, r=12, rot=20)
    s.rect(70, 112, 30, 26, GREY, r=4, rot=20)
    s.path("M66 132 q-20 30 -14 52 q30 -10 40 -40 z", RED)


@art("construction")
def gear(s: Svg):
    import math

    teeth = []
    for i in range(12):
        a = i * math.pi / 6
        teeth.append(f'<rect x="88" y="14" width="24" height="30" rx="5" transform="rotate({math.degrees(a)} 100 100)" '
                     f'{s.style(ORANGE)}/>')
    s.add("".join(teeth))
    s.circle(100, 100, 66, ORANGE)
    s.circle(100, 100, 24, WHITE)
    s.shine(78, 72, 20, 9)


@art("construction")
def crane(s: Svg):
    s.shadow(100, 192, 70, 6)
    s.rect(62, 160, 70, 28, YELLOW, r=8)
    s.rect(84, 30, 20, 132, YELLOW, r=4)
    s.rect(20, 26, 170, 16, YELLOW, r=6)
    s.line("M160 42 v70", DARK, 3)
    s.path("M152 112 h16 v8 q0 14 -10 14", GREY, 4)
    s.line("M88 40 l12 20 l-12 20 l12 20 l-12 20 l12 20", shade(YELLOW, -.25), 3)


@art("construction")
def wheel(s: Svg):
    s.circle(100, 100, 80, DARK)
    s.circle(100, 100, 46, GREY)
    s.circle(100, 100, 14, WHITE)


@art("construction")
def cone(s: Svg):
    s.shadow(100, 184, 54, 7)
    s.rect(46, 166, 108, 16, ORANGE, r=6)
    s.path("M82 30 h36 l26 140 h-88 z", ORANGE)
    s.add('<path d="M75 82 h50 l5 28 h-60 z M68 124 h64 l4 22 h-72 z" fill="#FFFFFF"/>')


@art("construction")
def bridge(s: Svg):
    s.rect(10, 110, 180, 22, WOOD, r=6)
    s.path("M16 112 q84 -90 168 0", BLUE, 7)
    s.line("M16 112 q84 -90 168 0", shade(BLUE, .25), 3)
    for x in (44, 72, 100, 128, 156):
        s.line(f"M{x} {112 - (1 - ((x - 100) / 84) ** 2) * 46} V112", shade(BLUE, -.1), 4)
    s.rect(16, 132, 14, 50, GREY, r=4)
    s.rect(170, 132, 14, 50, GREY, r=4)


@art("construction")
def road_piece(s: Svg):
    s.rect(6, 60, 188, 80, "#596079", r=10)
    s.line("M20 100 h30 M80 100 h40 M150 100 h34", WHITE, 7)


@art("construction")
def flag(s: Svg):
    s.line("M70 186 V20", GREY, 8)
    s.path("M74 24 h90 l-20 30 l20 30 h-90 z", RED)


def build() -> int:
    n = 0
    for aid, (group, fn) in sorted(ART.items(), key=lambda kv: (kv[1][0], kv[0])):
        svg = Svg()
        fn(svg)
        text = svg.render()
        path = OUT / group / f"{aid}.svg"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        n += 1
    subprocess.run([sys.executable, str(ROOT / "tools/build_manifest.py")], check=True)
    return n


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()
    if a.list:
        for k, (g, _) in sorted(ART.items()):
            print(g, k)
    else:
        print(f"{build()} drawings → {OUT.relative_to(ROOT)}")
