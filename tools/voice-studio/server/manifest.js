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
  const temp = manifestPath + ".tmp";
  fs.writeFileSync(temp, JSON.stringify(data, null, 2) + (original.endsWith("\n") ? "\n" : ""), "utf8");
  fs.renameSync(temp, manifestPath);
  return true;
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
