#!/usr/bin/env python3
"""Synthesised general sounds for POPO: interface sounds, instrument notes, toy/vehicle/kitchen
effects and two background music loops. Everything here is made from code, so it is original and
free of licence terms.

Real-world recordings (animals, water, doorbell…) are NOT synthesised: they come from Wikimedia
Commons with their licences recorded in docs/audio/sfx_sources.json (see tools/sfx/README.md).
Narrator voice lines are not made here either: they are produced in tools/voice-studio.

    python3 tools/sfx/synth.py           # write every sound
    python3 tools/sfx/synth.py pop boing # only these

Needs numpy and ffmpeg (mono, 44.1 kHz, MP3, loudness-normalised).
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
AUDIO = ROOT / "assets/audio"
SR = 44100
RNG = np.random.default_rng(7)


# ── building blocks ─────────────────────────────────────────────────────────
def t(sec: float) -> np.ndarray:
    return np.arange(int(sec * SR)) / SR


def env(n: int, attack=.005, decay=.3, sustain=0.0, release=.05) -> np.ndarray:
    """Attack then exponential decay towards [sustain], with a short release at the end."""
    x = np.arange(n) / SR
    a = np.clip(x / max(attack, 1e-4), 0, 1)
    d = sustain + (1 - sustain) * np.exp(-np.maximum(x - attack, 0) / max(decay, 1e-4))
    r = np.clip((n / SR - x) / max(release, 1e-4), 0, 1)
    return a * d * r


def sine_sweep(f0, f1, sec, curve="exp"):
    x = t(sec)
    if curve == "exp":
        f = f0 * (f1 / f0) ** (x / sec)
    else:
        f = f0 + (f1 - f0) * x / sec
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def onepole_lp(sig, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    out = np.empty_like(sig)
    y = 0.0
    for i, v in enumerate(sig):
        y = (1 - a) * v + a * y
        out[i] = y
    return out


def hp(sig, cutoff):
    return sig - onepole_lp(sig, cutoff)


def bandpass(sig, lo, hi):
    return onepole_lp(hp(sig, lo), hi)


def noise(sec):
    return RNG.uniform(-1, 1, int(sec * SR))


def square(freq, sec, duty=.5):
    x = t(sec)
    return np.where((x * freq) % 1 < duty, 1.0, -1.0)


def saw(freq, sec):
    x = t(sec)
    if np.ndim(freq):
        ph = np.cumsum(freq) / SR
    else:
        ph = x * freq
    return 2 * (ph % 1) - 1


def mix(*parts, length=None):
    n = length or max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p[:n]
    return out


def at(sig, sec, total):
    out = np.zeros(int(total * SR))
    i = int(sec * SR)
    out[i : i + len(sig)] += sig[: max(0, len(out) - i)]
    return out


def midi(n):
    return 440 * 2 ** ((n - 69) / 12)


# ── instruments ─────────────────────────────────────────────────────────────
def piano(freq, sec=1.8):
    x = t(sec)
    s = sum((1 / k ** 1.4) * np.sin(2 * np.pi * freq * k * (1 + .0004 * k * k) * x) * np.exp(-x * (1.6 + k * .9)) for k in range(1, 8))
    hammer = np.zeros_like(s)
    hammer[: int(.012 * SR)] = bandpass(noise(.012), 800, 4000) * .12
    return (s + hammer) * env(len(x), .003, 10, 1, .08)


def xylophone(freq, sec=1.1):
    x = t(sec)
    s = np.sin(2 * np.pi * freq * x) * np.exp(-x * 5) + .35 * np.sin(2 * np.pi * freq * 3.93 * x) * np.exp(-x * 14)
    s += .12 * np.sin(2 * np.pi * freq * 9.5 * x) * np.exp(-x * 30)
    return s * env(len(x), .002, 10, 1, .05)


def bell(freq, sec=1.6, bright=1.0):
    x = t(sec)
    partials = ((1, 1, 2.2), (2.76, .5 * bright, 3.5), (5.4, .25 * bright, 6), (8.93, .12 * bright, 9))
    return sum(a * np.sin(2 * np.pi * freq * r * x) * np.exp(-x * d) for r, a, d in partials) * env(len(x), .002, 10, 1, .05)


def kick():
    s = sine_sweep(160, 42, .45) * np.exp(-t(.45) * 7)
    click = np.zeros_like(s)
    click[:200] = noise(200 / SR) * .4
    return s + click


def snare():
    n = bandpass(noise(.3), 900, 7000) * np.exp(-t(.3) * 16)
    tone = np.sin(2 * np.pi * 190 * t(.3)) * np.exp(-t(.3) * 22)
    return n * 1.4 + tone * .6


def hihat():
    return hp(noise(.12), 6000) * np.exp(-t(.12) * 45) * 2.2


def tom(f0=230):
    return sine_sweep(f0, f0 * .6, .5) * np.exp(-t(.5) * 7)


def cymbal():
    return hp(noise(1.4), 5000) * np.exp(-t(1.4) * 3.2) * 1.6


def shaker():
    return bandpass(noise(.18), 3000, 9000) * np.sin(np.pi * t(.18) / .18) ** 2 * 1.8


# ── effects ─────────────────────────────────────────────────────────────────
def tap():
    return np.sin(2 * np.pi * 1200 * t(.05)) * np.exp(-t(.05) * 90)


def pop():
    return sine_sweep(380, 1100, .12) * env(int(.12 * SR), .002, .05, 0, .02)


def success():
    total = .9
    notes = [72, 76, 79, 84]
    return sum(at(bell(midi(n), .7, .6) * .6, i * .09, total) for i, n in enumerate(notes))


def sparkle():
    total = 1.1
    notes = [88, 91, 93, 96, 100]
    return sum(at(bell(midi(n), .5, .4) * .35, i * .07 + RNG.uniform(0, .02), total) for i, n in enumerate(notes))


def whoosh():
    n = noise(.5)
    sweep = np.sin(np.pi * t(.5) / .5) ** 2
    return bandpass(n, 400, 2500) * sweep * 1.4


def toggle():
    return mix(tap() * .8, at(np.sin(2 * np.pi * 1700 * t(.04)) * np.exp(-t(.04) * 100) * .6, .06, .12))


def soft_no():
    return mix(np.sin(2 * np.pi * 330 * t(.18)) * env(int(.18 * SR), .01, .1), at(np.sin(2 * np.pi * 262 * t(.25)) * env(int(.25 * SR), .01, .14), .15, .45))


def boing():
    x = t(.6)
    f = 160 + 260 * np.exp(-x * 6) + 30 * np.sin(2 * np.pi * 14 * x) * np.exp(-x * 3)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(x), .004, .35)


def squeak():
    x = t(.35)
    f = 1050 + 280 * np.sin(np.pi * x / .35) + 40 * np.sin(2 * np.pi * 30 * x)
    s = np.sign(np.sin(2 * np.pi * np.cumsum(f) / SR)) * .3 + np.sin(2 * np.pi * np.cumsum(f) / SR) * .5
    return onepole_lp(s, 4000) * env(len(x), .02, 10, 1, .05)


def jump():
    return sine_sweep(300, 900, .22) * env(int(.22 * SR), .005, .12)


def light_switch():
    c = bandpass(noise(.015), 2000, 9000) * 1.5
    return mix(c, at(c * .7, .04, .1))


def tv_on():
    whine = np.sin(2 * np.pi * np.cumsum(np.linspace(2000, 6000, int(.3 * SR))) / SR) * .15
    static = bandpass(noise(.5), 1000, 8000) * np.exp(-t(.5) * 6) * .5
    return mix(whine, static, light_switch())


def splash():
    n = bandpass(noise(.7), 300, 5000) * np.exp(-t(.7) * 6)
    drops = sum(at(sine_sweep(RNG.uniform(600, 1200), RNG.uniform(1500, 2500), .05) * .2 * np.exp(-t(.05) * 40), RNG.uniform(.05, .5), .7) for _ in range(10))
    return n * 1.3 + drops


def bubbles():
    total = 1.0
    return sum(at(sine_sweep(f, f * 2.2, .07) * np.exp(-t(.07) * 25) * .5, i * .09 + RNG.uniform(0, .03), total)
               for i, f in enumerate(RNG.uniform(400, 900, 10)))


def sizzle():
    n = bandpass(noise(1.4), 2500, 9000) * (.5 + .5 * np.abs(np.sin(2 * np.pi * 3 * t(1.4))))
    crackle = np.zeros_like(n)
    for _ in range(40):
        i = RNG.integers(0, len(n) - 200)
        crackle[i : i + 200] += noise(200 / SR) * np.exp(-np.arange(200) / 30)
    return (n * .7 + crackle * .6) * env(len(n), .05, 10, 1, .3)


def stir():
    x = t(1.0)
    return bandpass(noise(1.0), 300, 2000) * (.4 + .6 * np.abs(np.sin(2 * np.pi * 2 * x))) * env(len(x), .05, 10, 1, .2)


def car_horn():
    s = square(392, .45, .5) + square(494, .45, .5)
    return onepole_lp(s, 1800) * env(int(.45 * SR), .01, 10, 1, .06) * .35


def bus_horn():
    s = square(262, .7) + square(330, .7)
    return onepole_lp(s, 1300) * env(int(.7 * SR), .02, 10, 1, .1) * .35


def truck_horn():
    s = saw(196, .8) + saw(233, .8) + saw(147, .8)
    return onepole_lp(s, 1200) * env(int(.8 * SR), .02, 10, 1, .12) * .3


def engine():
    x = t(1.1)
    f = 55 + 70 * np.sin(np.pi * np.clip(x / .8, 0, 1)) ** 2
    s = saw(f, 1.1) * .6 + bandpass(noise(1.1), 80, 600) * .5
    return onepole_lp(s, 900) * env(len(x), .05, 10, 1, .3)


def bike_bell():
    return mix(bell(2100, .8, .9), at(bell(2100, .9, .9), .14, 1.0))


def cash():
    return mix(light_switch() * .7, at(bell(1568, 1.0, .8), .05, 1.1))


def buzz():
    x = t(1.0)
    f = 210 + 15 * np.sin(2 * np.pi * 5 * x)
    s = saw(f, 1.0) * (.6 + .4 * np.sin(2 * np.pi * 9 * x))
    return onepole_lp(s, 2200) * env(len(x), .05, 10, 1, .2) * .6


def bloop():
    x = t(.35)
    f = 500 - 250 * np.sin(np.pi * x / .35)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(x), .01, .2)


def rustle():
    total = 1.0
    return sum(at(bandpass(noise(.08), 1500, 7000) * np.exp(-t(.08) * 30) * RNG.uniform(.4, 1), RNG.uniform(0, .9), total) for _ in range(18))


def pour():
    x = t(1.4)
    s = bandpass(noise(1.4), 600, 4000) * (.6 + .4 * np.sin(2 * np.pi * 7 * x) ** 2)
    return s * env(len(x), .1, 10, 1, .3)


def grow():
    total = 1.2
    return sum(at(xylophone(midi(n), .6) * .6, i * .12, total) for i, n in enumerate([67, 71, 74, 79, 83]))


def thunk():
    s = np.sin(2 * np.pi * 120 * t(.25)) * np.exp(-t(.25) * 18)
    return mix(s, bandpass(noise(.02), 500, 3000) * .5)


def gear():
    x = t(1.2)
    s = saw(90, 1.2) * .3
    ticks = np.zeros_like(s)
    for i in range(0, len(s), int(SR / 18)):
        ticks[i : i + 150] += bandpass(noise(150 / SR), 2000, 8000) * .6
    return onepole_lp(s, 700) + ticks * env(len(x), .05, 10, 1, .2)


def hammer():
    hit = bandpass(noise(.04), 1000, 6000) * np.exp(-t(.04) * 60)
    ring = bell(1300, .4, .5) * .3
    return mix(hit, ring)


def crane():
    x = t(1.3)
    f = 140 + 30 * np.sin(2 * np.pi * .8 * x)
    return onepole_lp(saw(f, 1.3), 800) * .5 * env(len(x), .1, 10, 1, .3)


def chime():
    return bell(midi(84), 1.4, .8) * .7


def page():
    return bandpass(noise(.25), 2000, 8000) * np.sin(np.pi * t(.25) / .25) * .9


def camera():
    return mix(light_switch(), at(bandpass(noise(.12), 1500, 6000) * np.exp(-t(.12) * 20), .05, .2))


def eraser():
    x = t(.4)
    return bandpass(noise(.4), 800, 3000) * (.5 + .5 * np.sin(2 * np.pi * 12 * x) ** 2) * .7


def yawn():
    x = t(1.2)
    f = 260 + 120 * np.sin(np.pi * x / 1.2) - 80 * x
    s = sum((1 / k) * np.sin(2 * k * np.pi * np.cumsum(f) / SR) for k in range(1, 5))
    return onepole_lp(s, 1500) * env(len(x), .15, 10, 1, .4) * .4


def giggle():
    total = .8
    return sum(at(np.sin(2 * np.pi * np.cumsum(np.full(int(.07 * SR), f)) / SR) * env(int(.07 * SR), .005, .04) * .5, i * .1, total)
               for i, f in enumerate([700, 820, 760, 900, 840, 980]))


def snap():
    return mix(thunk() * .6, at(tap(), .01, .1))


# ── music ───────────────────────────────────────────────────────────────────
def music_loop(tempo=96, inst=xylophone, prog=((60, 64, 67), (55, 59, 62), (57, 60, 64), (53, 57, 60)), bars=8, melody=None):
    beat = 60 / tempo
    total = bars * 4 * beat
    out = np.zeros(int(total * SR) + SR)
    for b in range(bars):
        chord = prog[b % len(prog)]
        for i in range(8):  # eighth-note arpeggio
            n = chord[[0, 1, 2, 1][i % 4]] + (12 if i >= 4 else 0)
            out += at(inst(midi(n), .9) * .22, (b * 4 + i * .5) * beat, total + 1)
        out += at(piano(midi(chord[0] - 12), 2.4) * .25, b * 4 * beat, total + 1)
    if melody:
        for (start, n, dur) in melody:
            out += at(bell(midi(n), max(.5, dur * beat), .5) * .3, start * beat, total + 1)
    # crossfade the tail into the start so the loop is seamless
    n = int(total * SR)
    tail = out[n:]
    out = out[:n]
    out[: len(tail)] += tail
    return out


MELODY = [(0, 79, 1), (1, 76, 1), (2, 77, 1), (3, 74, 1), (4, 76, 2), (6, 72, 2), (8, 74, 1), (9, 71, 1), (10, 72, 1),
          (11, 74, 1), (12, 76, 4), (16, 79, 1), (17, 81, 1), (18, 79, 1), (19, 76, 1), (20, 77, 2), (22, 74, 2),
          (24, 72, 1), (25, 74, 1), (26, 76, 1), (27, 74, 1), (28, 72, 4)]


SOUNDS = {
    # ui
    "ui/tap": tap, "ui/pop": pop, "ui/success": success, "ui/sparkle": sparkle, "ui/whoosh": whoosh,
    "ui/toggle": toggle, "ui/soft_no": soft_no, "ui/chime": chime, "ui/page": page, "ui/camera": camera,
    # toys & home
    "sfx/boing": boing, "sfx/squeak": squeak, "sfx/jump": jump, "sfx/light_switch": light_switch, "sfx/tv_on": tv_on,
    "sfx/splash": splash, "sfx/bubbles": bubbles, "sfx/sizzle": sizzle, "sfx/stir": stir, "sfx/yawn": yawn,
    "sfx/giggle": giggle,
    # city
    "sfx/car_horn": car_horn, "sfx/bus_horn": bus_horn, "sfx/truck_horn": truck_horn, "sfx/engine": engine,
    "sfx/bike_bell": bike_bell, "sfx/cash": cash,
    # nature
    "sfx/buzz": buzz, "sfx/bloop": bloop, "sfx/rustle": rustle, "sfx/pour": pour, "sfx/grow": grow,
    # construction & art
    "sfx/thunk": thunk, "sfx/gear": gear, "sfx/hammer": hammer, "sfx/crane": crane, "sfx/eraser": eraser, "sfx/snap": snap,
    # drums
    "instruments/drum_kick": kick, "instruments/drum_snare": snare, "instruments/drum_hihat": hihat,
    "instruments/drum_tom": tom, "instruments/drum_cymbal": cymbal, "instruments/shaker": shaker,
}
# piano and xylophone: C major scale, C4..E5 (10 notes)
SCALE = [("c4", 60), ("d4", 62), ("e4", 64), ("f4", 65), ("g4", 67), ("a4", 69), ("b4", 71), ("c5", 72), ("d5", 74), ("e5", 76)]
for name, n in SCALE:
    SOUNDS[f"instruments/piano_{name}"] = (lambda n=n: piano(midi(n)))
    SOUNDS[f"instruments/xylo_{name}"] = (lambda n=n: xylophone(midi(n + 12)))
    SOUNDS[f"instruments/bell_{name}"] = (lambda n=n: bell(midi(n + 12), 1.2, .7) * .8)
SOUNDS["music/menu_loop"] = lambda: music_loop(84, xylophone, melody=MELODY)
SOUNDS["music/play_loop"] = lambda: music_loop(108, lambda f, s: bell(f, s, .3), prog=((53, 57, 60), (55, 59, 62), (60, 64, 67), (57, 60, 64)))

LOUDNESS = {"music": -24, "instruments": -16, "ui": -18, "sfx": -16}


def write(name: str, sig: np.ndarray) -> Path:
    sig = np.asarray(sig, dtype=np.float64)
    peak = np.max(np.abs(sig)) or 1
    pcm = (sig / peak * .9 * 32767).astype(np.int16)
    out = AUDIO / f"{name}.mp3"
    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "x.wav"
        with wave.open(str(wav), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
        lufs = LOUDNESS[name.split("/")[0]]
        # short sounds can't be measured reliably by loudnorm; peak-normalise them and only
        # loudness-normalise what is longer than a second
        filt = [] if len(sig) < SR else ["-af", f"loudnorm=I={lufs}:TP=-1.5:LRA=11"]
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), *filt, "-ac", "1", "-ar", str(SR),
                        "-codec:a", "libmp3lame", "-b:a", "96k" if not name.startswith("music") else "128k", str(out)], check=True)
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("only", nargs="*", help="short names, e.g. pop boing piano_c4")
    a = ap.parse_args()
    todo = {k: v for k, v in SOUNDS.items() if not a.only or k.split("/")[-1] in a.only}
    for name, fn in todo.items():
        p = write(name, fn())
        print(f"{p.relative_to(ROOT)}  {p.stat().st_size // 1024} KB")
    print(f"{len(todo)} sounds")


if __name__ == "__main__":
    sys.exit(main())
