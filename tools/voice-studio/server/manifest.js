// Reading what پوپو says.
//
// The Flutter app keeps every line in assets/content/voice_lines.json:
//   { "id": "who.01.q", "text": "…", "file": "voice/who_01_q.mp3", "event": "…", … }
// The studio works with the file name as the key (who_01_q), because that is the name the
// app plays: a clip saved as <key>.mp3 in assets/audio/voice is found with no other step.
// An optional "spoken" field holds a respelling for the TTS service (vowels, stress); the
// app never reads it — it only shows "text".
//
// The legacy audio_manifest.txt («key | written | spoken») is still read if it is pointed at,
// so an old checkout keeps working.

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

// Groups follow the id prefixes of voice_lines.json.
const CHAPTER_TITLES = {
  1: "فصل ۱ — آشپزخانه‌ی خاله خرسی", 2: "فصل ۲ — باغ و مزرعه‌ی بانی", 3: "فصل ۳ — کارگاه آقا سنجاب",
  4: "فصل ۴ — آتلیه‌ی رنگی کوکو", 5: "فصل ۵ — شب جنگل", 6: "فصل ۶ — گروه موسیقی میمی",
  7: "فصل ۷ — شهر و راننده لاکی", 8: "فصل ۸ — جشن بزرگ جنگل",
};
const GROUPS = [
  ...Object.entries(CHAPTER_TITLES).map(([n, label]) => ({ id: `c${n}`, test: (id) => id.startsWith(`c${n}`), label })),
  { id: "items",    test: (id) => id.startsWith("item."),     label: "ساخته‌ها: کاربرد، مزه، سؤال" },
  { id: "kits",     test: (id) => /^(k_|kit\.|workshop\.)/.test(id), label: "کارگاه ستاره (کیت‌ها)" },
  { id: "shop",     test: (id) => /^(r_|tool\.|shop\.)/.test(id), label: "فروشگاه ابزار و دستورهای ساخت" },
  { id: "playroom", test: (id) => /^(playroom|order|combo)\./.test(id), label: "اتاق بازی، سفارش‌ها و ترکیب‌ها" },
  { id: "game",     test: (id) => /^(game|home|film)\./.test(id), label: "راهنما، ستاره، جایزه" },
  { id: "app",      test: (id) => id.startsWith("app."),      label: "صفحه‌ها و خوشامد" },
  { id: "feedback", test: (id) => /^(praise|idle)\./.test(id), label: "تشویق و راهنمایی" },
  { id: "session",  test: (id) => /^(session|parent|full|notice)\./.test(id), label: "توقف، ادامه، والدین" },
  { id: "old",      test: (id) => /^(world|scene|art|music|build|puzzle|play|sticker|rewards|library)\./.test(id), label: "نسخه‌ی قبل (دیگر پخش نمی‌شود)" },
];

function groupOf(id) {
  return (GROUPS.find((g) => g.test(id)) || { id: "other" }).id;
}

/** Chapter number (1–8) for chapter lines, so the studio can filter by chapter. */
function levelOf(id) {
  const m = /^c(\d)/.exec(id);
  return m ? Number(m[1]) : null;
}

/** The studio's key for a line: the base name of the file the app plays. */
export function keyOf(line) {
  return path.basename(line.file || `voice/${line.id.replace(/\./g, "_")}.mp3`, ".mp3");
}

function readJson(manifestPath) {
  const data = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  return (data.lines || []).map((l) => ({
    key: keyOf(l),
    id: l.id,
    written: l.text,
    spoken: l.spoken && l.spoken.trim() ? l.spoken.trim() : l.text,
    event: l.event || "",
    note: l.note || "",
    group: groupOf(l.id),
    chapter: levelOf(l.id),
  }));
}

function readText(manifestPath) {
  const lines = [];
  for (const raw of fs.readFileSync(manifestPath, "utf8").split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith("#") || !line.includes("|")) continue;
    const cols = line.split("|").map((c) => c.trim());
    const [key, written] = cols;
    if (!key || !written) continue;
    lines.push({ key, id: key, written, spoken: cols[2] || written, event: "", note: "",
                 group: "other", chapter: null });
  }
  return lines;
}

export function readManifest(manifestPath) {
  return manifestPath.toLowerCase().endsWith(".json") ? readJson(manifestPath) : readText(manifestPath);
}

/**
 * Sets (or with null, removes) the TTS respelling of one line in voice_lines.json, keeping the
 * file's formatting. Returns false when the key is not in the file.
 */
export function setSpoken(manifestPath, key, spoken) {
  if (!manifestPath.toLowerCase().endsWith(".json")) return false;
  const original = fs.readFileSync(manifestPath, "utf8");
  const data = JSON.parse(original);
  const line = (data.lines || []).find((l) => keyOf(l) === key);
  if (!line) return false;
  if (spoken) line.spoken = spoken;
  else delete line.spoken;
  writeJson(manifestPath, data, original);

  // tools/content/build_game.py rewrites voice_lines.json from tools/content/spoken_fa.json (keyed
  // by the written text), so the respelling goes there too, or the next rebuild would undo it.
  const spokenFile = path.resolve(path.dirname(manifestPath), "../../tools/content/spoken_fa.json");
  if (fs.existsSync(spokenFile)) {
    const raw = fs.readFileSync(spokenFile, "utf8");
    const table = JSON.parse(raw);
    if (spoken) table[line.text] = spoken;
    else delete table[line.text];
    writeJson(spokenFile, table, raw);
  }
  return true;
}

/** Writes JSON with the same indent as the file had (the Python tools write one space). */
function writeJson(file, data, original) {
  const indent = (/\n( +)"/.exec(original) || [null, " "])[1].length;
  const temp = file + ".tmp";
  fs.writeFileSync(temp, JSON.stringify(data, null, indent) + (original.endsWith("\n") ? "\n" : ""), "utf8");
  fs.renameSync(temp, file);
}

/**
 * Rewrites assets/content/asset_manifest.json the way tools/build_manifest.py does (every bundled
 * sound with its size and sha256), so a clip made or replaced here is listed with no other step
 * and the content test stays green. Called after every write; runs once things go quiet.
 */
let manifestTimer = null;
export function refreshAssetManifest(app) {
  clearTimeout(manifestTimer);
  manifestTimer = setTimeout(() => {
    try {
      writeAssetManifest(app);
    } catch (err) {
      console.error(`asset_manifest.json نوشته نشد: ${err.message}`);
    }
  }, 1500);
}

const TYPES = { ".mp3": "audio/mpeg", ".ogg": "audio/ogg" };

export function writeAssetManifest(app) {
  const assets = path.join(app, "assets");
  const files = [];
  const walk = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) walk(full);
      else if (e.isFile() && TYPES[path.extname(e.name)]) files.push(full);
    }
  };
  walk(path.join(assets, "audio"));
  // the same order as Python's sorted() over paths: plain code-point order of the relative path
  const rel = (f) => path.relative(assets, f).split(path.sep).join("/");
  files.sort((a, b) => (rel(a) < rel(b) ? -1 : rel(a) > rel(b) ? 1 : 0));
  const entries = files.map((f) => {
    const data = fs.readFileSync(f);
    const r = rel(f);
    return {
      id: r.slice("audio/".length).replace(/\.[^.]+$/, ""),
      group: path.posix.dirname(r).slice("audio/".length),
      path: r,
      type: TYPES[path.extname(f)],
      version: 1,
      bytes: data.length,
      sha256: crypto.createHash("sha256").update(data).digest("hex"),
    };
  });
  const out = path.join(assets, "content/asset_manifest.json");
  const body = { version: 1, note: "Generated by tools/build_manifest.py — do not edit by hand.", assets: entries };
  fs.writeFileSync(out + ".tmp", JSON.stringify(body, null, 1) + "\n", "utf8");
  fs.renameSync(out + ".tmp", out);
}

/** Which keys already have a file in the output directory, whatever the extension. */
export function existingKeys(outDir) {
  const done = new Map();
  if (!outDir || !fs.existsSync(outDir)) return done;
  for (const name of fs.readdirSync(outDir)) {
    const ext = path.extname(name).toLowerCase();
    if (![".ogg", ".mp3", ".wav"].includes(ext)) continue;
    const full = path.join(outDir, name);
    let size = 0;
    try {
      size = fs.statSync(full).size;
    } catch {
      continue;
    }
    // a near-empty file is the wreck of a failed attempt, not a recording
    if (size < 512) continue;
    done.set(path.basename(name, ext), { name, size });
  }
  return done;
}

export const GROUP_LABELS = Object.fromEntries(GROUPS.map((g) => [g.id, g.label]));
