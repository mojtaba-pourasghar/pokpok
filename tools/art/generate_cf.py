#!/usr/bin/env python3
"""Makes POPO's illustrations with Cloudflare Workers AI (flux-1-schnell), the same "level 3"
generator goshyar_game uses (.claude/skills/level-3-image-generator), and installs them in the app.

    python3 tools/art/prompts.py                     # refresh art/art_manifest.json
    python3 tools/art/generate_cf.py                 # every image that is still missing
    python3 tools/art/generate_cf.py --only popo_welcome popo_happy
    python3 tools/art/generate_cf.py --kind character background
    python3 tools/art/generate_cf.py --process-only  # re-cut what is already in art/generated/

Needs CF_ACCOUNT_ID and CF_API_TOKEN (environment or the project's .env; see .env.example) and
network access to api.cloudflare.com. The token is only used here, on your machine; it never goes
into the app.

Steps per image:
  1. art/generated/<id>.jpg  — the raw 1024×1024 render (kept, so re-cutting is free)
  2. objects and character poses: the white background is removed (soft shadows stay as
     half-transparent grey), the subject is trimmed and centred on a square
  3. written as WebP to the item's target (assets/art/...), which the app prefers over the vector
     drawing with the same id — no code change needed
  4. tools/build_manifest.py refreshes the asset list and checksums
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "art/art_manifest.json"
RAW = ROOT / "art/generated"


def load_env() -> None:
    env = ROOT / ".env"
    if env.exists():
        for line in env.read_text(encoding="utf-8").splitlines():
            if "=" in line and not line.strip().startswith("#"):
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())


def generate(prompt: str, steps: int) -> bytes:
    account, token = os.environ.get("CF_ACCOUNT_ID"), os.environ.get("CF_API_TOKEN")
    if not account or not token:
        sys.exit("CF_ACCOUNT_ID / CF_API_TOKEN are not set (environment or .env).")
    url = f"https://api.cloudflare.com/client/v4/accounts/{account}/ai/run/@cf/black-forest-labs/flux-1-schnell"
    body = json.dumps({"prompt": prompt, "steps": steps}).encode()
    for attempt in range(4):
        req = urllib.request.Request(url, data=body, headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=120) as res:
                data = json.loads(res.read())
            image = (data.get("result") or {}).get("image")
            if image:
                return base64.b64decode(image)
            raise RuntimeError(data.get("errors") or data)
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503) and attempt < 3:
                time.sleep(5 * (attempt + 1))
                continue
            raise RuntimeError(f"HTTP {e.code}: {e.read()[:300]!r}") from e
    raise RuntimeError("no image")


def cut_out(img: Image.Image) -> Image.Image:
    """Removes the plain white background that is connected to the border."""
    rgb = np.asarray(img.convert("RGB")).astype(np.int16)
    lum = rgb.mean(axis=2)
    sat = rgb.max(axis=2) - rgb.min(axis=2)
    light = (lum > 200) & (sat < 28)
    bg = np.zeros_like(light)
    bg[0, :], bg[-1, :], bg[:, 0], bg[:, -1] = light[0, :], light[-1, :], light[:, 0], light[:, -1]
    while True:  # flood fill by repeated dilation, limited to light pixels
        grown = bg.copy()
        grown[1:, :] |= bg[:-1, :]
        grown[:-1, :] |= bg[1:, :]
        grown[:, 1:] |= bg[:, :-1]
        grown[:, :-1] |= bg[:, 1:]
        grown &= light
        if (grown == bg).all():
            break
        bg = grown
    alpha = np.full(lum.shape, 255.0)
    # pure white → transparent; light grey (soft shadow) → half-transparent
    alpha[bg] = np.clip((250 - lum[bg]) / 50 * 150, 0, 150)
    a = Image.fromarray(alpha.astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
    out = img.convert("RGBA")
    out.putalpha(a)
    return out


def square(img: Image.Image, size: int, margin: float = .06) -> Image.Image:
    box = img.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox() or (0, 0, *img.size)
    sub = img.crop(box)
    side = int(max(sub.size) * (1 + margin * 2))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(sub, ((side - sub.width) // 2, (side - sub.height) // 2))
    return canvas.resize((size, size), Image.LANCZOS)


def install(item: dict, raw: Path) -> Path:
    img = Image.open(raw)
    target = ROOT / item["target"]
    target.parent.mkdir(parents=True, exist_ok=True)
    if item["kind"] in ("object", "character"):
        square(cut_out(img), item["size"]).save(target, "WEBP", quality=90, method=6)
    else:
        img.convert("RGB").resize((item["size"], item["size"]), Image.LANCZOS).save(target, "WEBP", quality=84, method=6)
    return target


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", nargs="*", default=[], help="item ids")
    ap.add_argument("--kind", nargs="*", default=[], help="character, background, card, object")
    ap.add_argument("--force", action="store_true", help="render again even if a raw image exists")
    ap.add_argument("--process-only", action="store_true", help="only re-cut images already in art/generated/")
    ap.add_argument("--steps", type=int, default=6)
    a = ap.parse_args()
    load_env()
    items = json.loads(MANIFEST.read_text(encoding="utf-8"))["items"]
    if a.only:
        items = [i for i in items if i["id"] in a.only]
    if a.kind:
        items = [i for i in items if i["kind"] in a.kind]
    RAW.mkdir(parents=True, exist_ok=True)
    done = failed = 0
    for item in items:
        raw = RAW / f"{item['id']}.jpg"
        if not a.process_only and (a.force or not raw.exists()):
            try:
                raw.write_bytes(generate(item["prompt"], a.steps))
                print(f"✓ {item['id']}", flush=True)
            except Exception as e:  # noqa: BLE001 — report and go on with the rest
                print(f"✗ {item['id']}: {e}", flush=True)
                failed += 1
                continue
        if raw.exists():
            print(f"  → {install(item, raw).relative_to(ROOT)}")
            done += 1
    subprocess.run([sys.executable, str(ROOT / "tools/build_manifest.py")], check=True)
    print(f"{done} installed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
