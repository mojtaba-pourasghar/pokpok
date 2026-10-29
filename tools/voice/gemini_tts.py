#!/usr/bin/env python3
"""Makes Popo's voice lines with Gemini TTS from the vowelled text (spoken), checks every clip by
transcribing it back, and installs it in assets/audio/voice/ in the app's format.

    python3 tools/voice/gemini_tts.py                 # every line without a good clip
    python3 tools/voice/gemini_tts.py --only c1s1.s1 c1s1.s2 --force
    python3 tools/voice/gemini_tts.py --voice Leda --workers 4

Needs GEMINI_API_KEYS (space or comma separated; .env or environment). Keys are used in turn and
a key that runs out of quota is rested. A real recording (a file not listed in
docs/voice/tts_generated.json) is never replaced. Clips made earlier by another TTS service are
replaced, because their pronunciation was not checked.

Check: the clip is transcribed with Gemini and compared word by word with the written text; a clip
under the threshold is made again (up to three tries) and the best one is kept, with its score and
what was heard in tts_generated.json, so weak lines can be listened to first.
"""
from __future__ import annotations

import argparse
import base64
import concurrent.futures as cf
import difflib
import json
import os
import re
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LINES = ROOT / "assets/content/voice_lines.json"
VOICE = ROOT / "assets/audio/voice"
LOG = ROOT / "docs/voice/tts_generated.json"
API = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
TTS_MODEL = "gemini-3.1-flash-tts-preview"
ASR_MODEL = "gemini-3.1-flash-lite"
GOOD = 0.9

STYLE = (
    "Read the Persian (Farsi) sentence between the guillemets aloud, exactly as written with its vowel marks, "
    "and nothing else. Voice: Popo, a little fox girl in a children's game — warm, cheerful, gentle and kind, "
    "smiling while she speaks, a little slower than normal and very clear for children aged 2 to 8. "
    "Questions rise at the end, exclamations are bright, never shouting.\n«{text}»"
)


def keys() -> list[str]:
    raw = os.environ.get("GEMINI_API_KEYS", "")
    env = ROOT / ".env"
    if not raw and env.exists():
        for line in env.read_text().splitlines():
            if line.startswith("GEMINI_API_KEYS="):
                raw = line.split("=", 1)[1]
    return [k for k in re.split(r"[\s,]+", raw.strip().strip('"')) if k]


class Keys:
    """Hands out keys in turn; a key that hit its quota rests for a while."""

    def __init__(self, ks: list[str]):
        self.ks = ks
        self.rest: dict[str, float] = {}
        self.i = 0
        self.lock = threading.Lock()

    def get(self) -> str | None:
        with self.lock:
            now = time.time()
            for _ in range(len(self.ks)):
                k = self.ks[self.i % len(self.ks)]
                self.i += 1
                if self.rest.get(k, 0) <= now:
                    return k
            return None

    def tired(self, k: str, seconds: float) -> None:
        with self.lock:
            self.rest[k] = time.time() + seconds

    def all_tired_for(self) -> float:
        with self.lock:
            return min(self.rest.get(k, 0) for k in self.ks) - time.time()


def call(pool: Keys, model: str, body: dict, timeout: int = 60) -> dict:
    for attempt in range(40):
        k = pool.get()
        if k is None:
            wait = pool.all_tired_for()
            if wait > 900:
                raise RuntimeError("every key is out of quota (or not valid)")
            time.sleep(max(5, wait))
            continue
        req = urllib.request.Request(
            API.format(model=model), data=json.dumps(body).encode(), headers={"Content-Type": "application/json", "x-goog-api-key": k}
        )
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            msg = e.read()[:400].decode("utf-8", "ignore")
            if e.code in (401, 403):
                pool.tired(k, 10**9)  # a key that is not valid (any more) is never used again
                continue
            if e.code == 429:
                # per-minute limits clear fast; a daily limit says "per day"
                pool.tired(k, 3600 * 6 if "PerDay" in msg or "per day" in msg.lower() else 65)
                continue
            if e.code in (500, 502, 503, 504) and attempt < 8:
                time.sleep(3 + attempt * 2)
                continue
            raise RuntimeError(f"HTTP {e.code}: {msg[:200]}")
        except (urllib.error.URLError, TimeoutError):
            time.sleep(4 + attempt)
    raise RuntimeError("no answer after many tries")


def speak(pool: Keys, text: str, voice: str) -> bytes:
    body = {
        "contents": [{"parts": [{"text": STYLE.format(text=text)}]}],
        "generationConfig": {"responseModalities": ["AUDIO"], "speechConfig": {"voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}}}},
    }
    for _ in range(4):
        d = call(pool, TTS_MODEL, body)
        try:
            return base64.b64decode(d["candidates"][0]["content"]["parts"][0]["inlineData"]["data"])
        except (KeyError, IndexError):
            continue  # sometimes an answer comes back with no audio; ask again
    raise RuntimeError("no audio in the answer after four tries")


def hear(pool: Keys, mp3: bytes) -> str:
    body = {
        "contents": [
            {
                "parts": [
                    {"inline_data": {"mime_type": "audio/mp3", "data": base64.b64encode(mp3).decode()}},
                    {"text": "Transcribe this Persian speech exactly, in Persian script without vowel marks. Output only the words."},
                ]
            }
        ],
        "generationConfig": {"temperature": 0},
    }
    d = call(pool, ASR_MODEL, body)
    return "".join(p.get("text", "") for p in d["candidates"][0]["content"]["parts"])


def words(s: str) -> list[str]:
    s = re.sub(r"[\u064B-\u0652\u0670]", "", s)
    s = s.replace("ي", "ی").replace("ك", "ک").replace("ۀ", "ه").replace("أ", "ا").replace("آ", "ا")
    s = s.replace("\u200c", "")  # «می‌دهد» و «میدهد» یکی‌اند
    return re.findall(r"[\u0621-\u06FF]+", s)


def score(written: str, heard: str) -> float:
    """Share of the written words found in what was heard (spaces ignored, so «آب‌میوه» = «آب میوه»);
    a mispronounced word counts as missing."""
    w = words(written)
    if not w:
        return 1.0
    stream = "".join(words(heard))
    return sum(1 for x in w if x in stream) / len(w)


def to_mp3(pcm: bytes) -> bytes:
    """24 kHz 16-bit PCM → the app's MP3: trimmed, 80 ms head, 150 ms tail, −16 LUFS, 44.1 kHz mono 96 kbps."""
    with tempfile.TemporaryDirectory() as d:
        src, dst = Path(d, "in.pcm"), Path(d, "out.mp3")
        src.write_bytes(pcm)
        af = (
            "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02,areverse,"
            "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02,areverse,"
            "adelay=80,apad=pad_dur=0.15,loudnorm=I=-16:TP=-1.5:LRA=11"
        )
        subprocess.run(
            ["ffmpeg", "-loglevel", "error", "-y", "-f", "s16le", "-ar", "24000", "-ac", "1", "-i", str(src), "-ac", "1", "-ar", "44100", "-af", af,
             "-b:a", "96k", str(dst)],
            check=True,
        )
        return dst.read_bytes()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", nargs="*", default=[], help="line ids")
    ap.add_argument("--force", action="store_true", help="make again even if a checked clip exists")
    ap.add_argument("--voice", default="Leda")
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()

    ks = keys()
    if not ks:
        sys.exit("GEMINI_API_KEYS is missing (.env or environment)")
    pool = Keys(ks)
    lines = json.loads(LINES.read_text(encoding="utf-8"))["lines"]
    log = json.loads(LOG.read_text(encoding="utf-8")) if LOG.exists() else {"files": {}}
    log.setdefault("note", "clips made with a TTS service — temporary until a voice actor records them")
    files = log["files"]
    lock = threading.Lock()

    def wanted(l: dict) -> bool:
        key = Path(l["file"]).stem
        if args.only:
            return l["id"] in args.only
        path = VOICE / Path(l["file"]).name
        if not path.exists():
            return True
        entry = files.get(key)
        if entry is None:
            return False  # a real recording
        if args.force:
            return True
        return not str(entry.get("speaker", "")).startswith("gemini:") or entry.get("text") != l["text"]

    todo = [l for l in lines if wanted(l)]
    if args.limit:
        todo = todo[: args.limit]
    print(f"{len(todo)} lines to make with {len(ks)} keys, voice {args.voice}", flush=True)
    done = 0

    def work(l: dict) -> tuple[str, float]:
        text = l.get("spoken") or l["text"]
        best: tuple[float, bytes, str] | None = None
        for _ in range(3):
            mp3 = to_mp3(speak(pool, text, args.voice))
            heard = hear(pool, mp3)
            sc = score(l["text"], heard)
            if best is None or sc > best[0]:
                best = (sc, mp3, heard)
            if sc >= GOOD:
                break
        sc, mp3, heard = best
        (VOICE / Path(l["file"]).name).write_bytes(mp3)
        with lock:
            files[Path(l["file"]).stem] = {
                "speaker": f"gemini:{args.voice}",
                "model": TTS_MODEL,
                "text": l["text"],
                "score": round(sc, 3),
                "heard": heard.strip(),
                "at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            }
            LOG.write_text(json.dumps(log, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        return l["id"], sc

    with cf.ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(work, l): l for l in todo}
        for f in cf.as_completed(futs):
            l = futs[f]
            try:
                i, sc = f.result()
                done += 1
                flag = "" if sc >= GOOD else "  ← listen"
                print(f"[{done}/{len(todo)}] {i}  {sc:.2f}{flag}", flush=True)
            except Exception as e:  # noqa: BLE001
                print(f"! {l['id']}: {e}", flush=True)
    weak = sorted((v["score"], k) for k, v in files.items() if str(v.get("speaker", "")).startswith("gemini:") and v.get("score", 1) < GOOD)
    print(f"done: {done}/{len(todo)}; clips under {GOOD}: {len(weak)}")
    for s, k in weak[:40]:
        print(f"  {s:.2f} {k}")


if __name__ == "__main__":
    main()
