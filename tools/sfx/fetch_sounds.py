#!/usr/bin/env python3
"""Real recordings for POPO (animals, water, doorbell…), from Wikimedia Commons.

General sounds are synthesised by tools/sfx/synth.py; only things a synthesiser can't fake come from
here. tools/sfx/picks.json names, for each destination (e.g. "animals/cow" → assets/audio/animals/cow.mp3), one Commons file chosen by hand (by its title, description, categories and
length — search ranking alone brings up songs and word pronunciations), and optionally which
part of it to keep ("start"/"seconds"; without a start, a long recording keeps its loudest
stretch). This script downloads each pick, reads its licence and author from Commons,
cleans it with the same ffmpeg chain the voice studio uses for effects (silence trimmed, a few
seconds with a fade-out, mono, −14 LUFS, MP3), writes it over the file the app already plays,
and records source, licence and author in docs/audio/sfx_sources.json.

    python3 tools/sfx/fetch_sounds.py                  # every pick not yet applied
    python3 tools/sfx/fetch_sounds.py cow dog --force  # these again
    python3 tools/sfx/fetch_sounds.py --search "cow moo"   # look for candidates

Freesound is not used: it answers 403 to scripted requests. Commons asks for a slow pace
(it answers 429 with Retry-After), which is honoured.

Needs network access to commons.wikimedia.org and upload.wikimedia.org, and ffmpeg on PATH.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PICKS = Path(__file__).resolve().parent / "picks.json"
SOURCES = ROOT / "docs/audio/sfx_sources.json"
UA = "PopoSoundFetcher/1.0 (kids play app; https://github.com/mojtaba-pourasghar/pokpok)"
FREE = re.compile(r"^(cc0|public domain|pd|cc[ -]by(-sa)?( \d\.\d)?)", re.I)


class Deferred(RuntimeError):
    """Commons asked for a long pause on this one file; the others go on and it comes back last."""


def fetch(url: str, *, timeout: int = 60, patience: int = 120) -> bytes:
    for _ in range(40):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=timeout) as res:
                return res.read()
        except urllib.error.HTTPError as err:
            if err.code != 429:
                raise
            wait = int(err.headers.get("Retry-After") or 30) + 2
            if wait > patience:
                raise Deferred(f"Commons asks to wait {wait}s for this file") from err
            print(f"   (Commons asks to wait {wait}s)", file=sys.stderr, flush=True)
            time.sleep(wait)
    raise RuntimeError("Commons kept answering 429")


def api(**params) -> dict:
    return json.loads(fetch("https://commons.wikimedia.org/w/api.php?"
                            + urllib.parse.urlencode({**params, "format": "json"})))


def plain(meta: dict, key: str) -> str:
    return re.sub(r"<[^>]+>", "", (meta.get(key) or {}).get("value", "")).strip()


def info(titles: list[str]) -> dict[str, dict]:
    """url, length, licence and author for Commons files, 40 at a time."""
    out = {}
    for i in range(0, len(titles), 40):
        d = api(action="query", titles="|".join(titles[i:i + 40]), prop="videoinfo",
                viprop="url|size|extmetadata",
                viextmetadatafilter="LicenseShortName|LicenseUrl|Artist|ImageDescription")
        norm = {n["to"]: n["from"] for n in d.get("query", {}).get("normalized", [])}
        for page in d.get("query", {}).get("pages", {}).values():
            vi = (page.get("videoinfo") or [{}])[0]
            meta = vi.get("extmetadata") or {}
            title = norm.get(page.get("title"), page.get("title"))
            out[title] = {
                "url": vi.get("url"),
                "page": vi.get("descriptionurl"),
                "duration": vi.get("duration"),
                "licence": plain(meta, "LicenseShortName"),
                "licence_url": plain(meta, "LicenseUrl"),
                "author": plain(meta, "Artist"),
                "missing": "missing" in page,
            }
        time.sleep(2)
    return out


def search(query: str) -> None:
    d = api(action="query", generator="search", gsrsearch=f"{query} filetype:audio", gsrnamespace=6,
            gsrlimit=30, prop="videoinfo", viprop="size|extmetadata",
            viextmetadatafilter="LicenseShortName|ImageDescription")
    pages = sorted(d.get("query", {}).get("pages", {}).values(), key=lambda p: p.get("index", 99))
    for p in pages:
        vi = (p.get("videoinfo") or [{}])[0]
        meta = vi.get("extmetadata") or {}
        print(f"{vi.get('duration') or 0:7.1f}s  {plain(meta, 'LicenseShortName'):14}  {p['title']}")
        print(f"          {plain(meta, 'ImageDescription')[:120]}")


def clean(src: Path, dst: Path, start: float, seconds: float, loop: bool = False) -> None:
    if loop:
        # صدای محیط حلقه‌ای: بدون بریدن سکوت، محو آرام اول و آخر تا تکرارش پرش نداشته باشد، آرام‌تر از جلوه‌ها
        chain = (f"atrim=0:{seconds},afade=t=in:d=1.2,afade=t=out:st={max(0, seconds - 1.2)}:d=1.2,"
                 "loudnorm=I=-24:TP=-3:LRA=11")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", str(start), "-t", str(seconds + 1), "-i", str(src),
                        "-vn", "-ac", "1", "-ar", "44100", "-af", chain, "-c:a", "libmp3lame", "-b:a", "96k",
                        str(dst)], check=True, stdin=subprocess.DEVNULL, timeout=180)
        return
    chain = ("silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02,"
             "areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.05,areverse,"
             f"atrim=0:{seconds},afade=t=out:st={max(0, seconds - 0.4)}:d=0.4,"
             "apad=pad_dur=0.1,loudnorm=I=-14:TP=-1.5:LRA=11")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", str(start), "-t", "60", "-i", str(src),
                    "-vn", "-ac", "1", "-ar", "44100", "-af", chain, "-c:a", "libmp3lame", "-b:a", "128k",
                    str(dst)], check=True, stdin=subprocess.DEVNULL, timeout=180)


def loudest(path: Path, seconds: float) -> float:
    """Start of the loudest `seconds`-long stretch: the whistle of a kettle, not the hiss before it."""
    import array
    rate, hop = 8000, 0.25
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(path), "-ac", "1", "-ar", str(rate),
                          "-f", "s16le", "-"], capture_output=True, check=True, timeout=180,
                         stdin=subprocess.DEVNULL).stdout
    pcm = array.array("h", raw[: len(raw) // 2 * 2])
    step = int(rate * hop)
    energy = [sum(x * x for x in pcm[i:i + step]) / step for i in range(0, len(pcm) - step + 1, step)]
    width = max(1, int(seconds / hop))
    if len(energy) <= width:
        return 0.0
    window = sum(energy[:width])
    best, best_at = window, 0
    for i in range(width, len(energy)):
        window += energy[i] - energy[i - width]
        if window > best:
            best, best_at = window, i - width + 1
    return round(max(0.0, best_at * hop - 0.15), 2)


def duration(path: Path) -> float:
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                          str(path)], capture_output=True, text=True, timeout=30)
    try:
        return float(out.stdout.strip())
    except ValueError:
        return 0.0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ids", nargs="*", help="sound ids (default: every pick not yet applied)")
    ap.add_argument("--force", action="store_true", help="apply even picks already applied")
    ap.add_argument("--search", metavar="QUERY", help="list Commons audio files for a query")
    args = ap.parse_args()

    if args.search:
        search(args.search)
        return 0

    sounds = {sid: {"title": sid, "audio": f"audio/{sid}.mp3"} for sid in json.loads(PICKS.read_text(encoding="utf-8"))["picks"]}
    picks = json.loads(PICKS.read_text(encoding="utf-8"))["picks"]
    sources = (json.loads(SOURCES.read_text(encoding="utf-8")) if SOURCES.exists() else
               {"note": "صدای حیوان‌ها و وسایل که با فایل واقعی جایگزین شده‌اند. صدایی که اینجا "
                        "نیست هنوز همان صدای سنتزیِ نسخه‌ی قبلی است.", "files": {}})

    todo = []
    for sid, pick in picks.items():
        if sid not in sounds:
            print(f"! {sid}: در levels.json نیست — رد شد")
            continue
        if args.ids and sid not in args.ids:
            continue
        applied = sources["files"].get(sid, {})
        if not args.force and applied.get("commons") == pick["file"]:
            continue
        todo.append((sid, pick))
    if not todo:
        print("چیزی برای انجام نیست.")
        return 0

    meta = info([p["file"] for _, p in todo])
    failed, deferred = [], []
    for sid, pick in todo:
        outcome = apply(sid, pick, sounds[sid], meta.get(pick["file"]) or {}, sources)
        if outcome == "deferred":
            deferred.append((sid, pick))
        elif outcome != "ok":
            failed.append(sid)

    # the files Commons held back get one more chance, with the full wait it asks for
    for sid, pick in deferred:
        if apply(sid, pick, sounds[sid], meta.get(pick["file"]) or {}, sources, patience=900) != "ok":
            failed.append(sid)

    print(f"\n{len(todo) - len(failed)} صدا جایگزین شد." + (f" نشد: {', '.join(failed)}" if failed else ""))
    return 1 if failed else 0


def transcodes(url: str) -> list[str]:
    """Commons' own converted copies of a file. When the original is held back from this
    address (429 with a long Retry-After), these are often still served."""
    base = url.split("?")[0]
    if "/wikipedia/commons/" not in base:
        return []
    head, name = base.rsplit("/", 1)
    folder = head.replace("/wikipedia/commons/", "/wikipedia/commons/transcoded/", 1)
    return [f"{folder}/{name}/{name}.{ext}" for ext in ("ogg", "mp3", "opus")
            if not name.lower().endswith("." + ext)]


def download(url: str, patience: int) -> tuple[bytes, str]:
    """The original if it comes, else a converted copy. Returns the bytes and the suffix."""
    try:
        return fetch(url, timeout=180, patience=patience), Path(urllib.parse.urlparse(url).path).suffix
    except Deferred:
        for alt in transcodes(url):
            try:
                print(f"   ↳ نسخه‌ی تبدیل‌شده: …{alt[-40:]}", flush=True)
                return fetch(alt, timeout=180, patience=30), "." + alt.rsplit(".", 1)[1]
            except Exception:  # noqa: BLE001 — try the next copy
                continue
        raise


def apply(sid: str, pick: dict, sound: dict, m: dict, sources: dict, *, patience: int = 120) -> str:
    """Downloads, cleans and writes one sound. Returns "ok", "deferred" or "failed"."""
    print(f"• {sid} ({sound['title']}) ← {pick['file']}", flush=True)
    if not m.get("url") or m.get("missing"):
        print("   ✗ روی Commons پیدا نشد")
        return "failed"
    if not FREE.match(m["licence"]):
        print(f"   ✗ مجوز آزاد نیست: {m['licence']}")
        return "failed"
    target = ROOT / "assets" / sound["audio"]
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "out.mp3"
        try:
            data, suffix = download(m["url"], patience)
            src = Path(tmp) / ("in" + suffix)
            src.write_bytes(data)
            seconds = float(pick.get("seconds", 5))
            # a long recording keeps its loudest stretch unless the pick names a start
            start = pick.get("start")
            if start is None:
                start = loudest(src, seconds) if duration(src) > seconds + 1 else 0.0
            clean(src, out, float(start), seconds, loop=bool(pick.get("loop")))
        except Deferred as err:
            print(f"   … {err} — بعد از بقیه دوباره", flush=True)
            return "deferred"
        except Exception as err:  # noqa: BLE001 — report it and go on with the next sound
            print(f"   ✗ {err}", flush=True)
            return "failed"
        length = duration(out)
        if length < 0.4:
            print(f"   ✗ خروجی خیلی کوتاه است ({length:.1f}s)")
            return "failed"
        target.write_bytes(out.read_bytes())
    sources["files"][sid] = {
        "file": sound["audio"],
        "commons": pick["file"],
        "source": m["page"],
        "license": m["licence"],
        "license_url": m["licence_url"],
        "author": m["author"],
        "kept": f"{start}s + {seconds}s",
        "via": "tools/sfx/fetch_sounds.py",
        "at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }
    SOURCES.parent.mkdir(parents=True, exist_ok=True)
    SOURCES.write_text(json.dumps({**sources, "files": dict(sorted(sources["files"].items()))},
                                  ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"   ✓ {m['licence']} · {m['author'][:40]} → {sound['audio']} ({length:.1f}s)", flush=True)
    time.sleep(1)
    return "ok"


if __name__ == "__main__":
    sys.exit(main())
