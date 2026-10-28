#!/usr/bin/env python3
"""Makes POPO's sounds sit together: loops repeat without a gap, effects are equally loud.

    python3 tools/sfx/balance.py

1. **Loops** (assets/audio/ambient/*, assets/audio/music/*): MP3 always adds a little silence at the
   start and end, which is heard as a gap or click every time a loop restarts. Each loop is decoded,
   its tail is cross-faded into its head (so the end flows into the beginning), loudness-normalised
   (ambient −28 LUFS, music −24 LUFS) and written as OGG Vorbis, which loops gaplessly on Android.
   The MP3 is then removed.
2. **Effects** (sfx, ui, animals, instruments): each is brought to the same loudness, measured on its
   loudest 80 ms, so a Commons recording is not twice as loud as a synthesised click. Peaks are kept
   under −1 dBFS and the head/tail get 5 ms fades so no sound starts or stops with a click.

Needs numpy and ffmpeg. Safe to run again: it only touches what is not balanced yet
(docs/audio/balanced.json remembers the checksums it wrote).
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
AUDIO = ROOT / "assets/audio"
STATE = ROOT / "docs/audio/balanced.json"
SR = 44100

# loudness of the loudest 80 ms window, dBFS RMS
EFFECT_TARGET = {"sfx": -14.0, "animals": -15.0, "instruments": -14.0, "ui": -17.0}
LOOP_LUFS = {"ambient": -28, "music": -24}


def decode(path: Path) -> np.ndarray:
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(path), "-ac", "1", "-ar", str(SR), "-f", "s16le", "-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.int16).astype(np.float64) / 32768


def write_wav(sig: np.ndarray, path: Path) -> None:
    pcm = (np.clip(sig, -1, 1) * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def seamless(sig: np.ndarray, fade_s: float = 1.5) -> np.ndarray:
    """Cross-fades the last [fade_s] seconds into the first ones (equal-power), so the loop has no seam."""
    n = min(int(fade_s * SR), len(sig) // 4)
    if n < SR // 10:
        return sig
    head, body, tail = sig[:n], sig[n:-n], sig[-n:]
    x = np.linspace(0, np.pi / 2, n)
    return np.concatenate([tail * np.cos(x) + head * np.sin(x), body])


def loops(state: dict) -> None:
    for group, lufs in LOOP_LUFS.items():
        for src in sorted((AUDIO / group).glob("*.mp3")):
            sig = seamless(decode(src))
            out = src.with_suffix(".ogg")
            with tempfile.TemporaryDirectory() as tmp:
                wav = Path(tmp) / "x.wav"
                write_wav(sig / (np.max(np.abs(sig)) or 1) * .9, wav)
                subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-af", f"loudnorm=I={lufs}:TP=-2:LRA=11",
                                "-ac", "1", "-ar", str(SR), "-c:a", "libvorbis", "-q:a", "3", str(out)], check=True)
            src.unlink()
            state[out.relative_to(AUDIO).as_posix()] = sha(out)
            print(f"loop  {out.relative_to(ROOT)}  {out.stat().st_size // 1024} KB")


def effects(state: dict) -> None:
    for group, target in EFFECT_TARGET.items():
        for src in sorted((AUDIO / group).glob("*.mp3")):
            key = src.relative_to(AUDIO).as_posix()
            if state.get(key) == sha(src):
                continue
            sig = decode(src)
            if len(sig) == 0:
                continue
            win = int(.08 * SR)
            if len(sig) > win:
                rms = np.sqrt(np.convolve(sig ** 2, np.ones(win) / win, mode="valid")).max()
            else:
                rms = np.sqrt(np.mean(sig ** 2))
            gain = 10 ** (target / 20) / max(rms, 1e-6)
            out = sig * gain
            peak = np.max(np.abs(out))
            limit = 10 ** (-1 / 20)
            if peak > limit:  # soft-knee limiter instead of hard clipping
                out = np.tanh(out / limit) * limit
            fade = min(int(.005 * SR), len(out) // 4)
            if fade:
                out[:fade] *= np.linspace(0, 1, fade)
                out[-fade:] *= np.linspace(1, 0, fade)
            with tempfile.TemporaryDirectory() as tmp:
                wav = Path(tmp) / "x.wav"
                write_wav(out, wav)
                subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-ac", "1", "-ar", str(SR),
                                "-codec:a", "libmp3lame", "-b:a", "96k", str(src)], check=True)
            state[key] = sha(src)
            print(f"level {key}  {20 * np.log10(max(rms, 1e-6)):+.1f} → {target:+.1f} dB")


def main() -> None:
    state = json.loads(STATE.read_text()) if STATE.exists() else {}
    loops(state)
    effects(state)
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps(dict(sorted(state.items())), indent=1) + "\n")


if __name__ == "__main__":
    main()
