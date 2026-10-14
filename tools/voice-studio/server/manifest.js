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
const GROUPS = [
  { id: "app",      test: (id) => id.startsWith("app."),      label: "صفحه‌ها، خوشامد و نقشه" },
  { id: "worlds",   test: (id) => /^(world|scene)\./.test(id), label: "جهان‌ها و صحنه‌ها" },
  { id: "studios",  test: (id) => /^(art|music|build)\./.test(id), label: "نقاشی، موسیقی، ساخت‌وساز" },
  { id: "puzzles",  test: (id) => id.startsWith("puzzle."),   label: "پازل‌ها" },
  { id: "roleplay", test: (id) => id.startsWith("play."),     label: "نقش‌آفرینی" },
  { id: "feedback", test: (id) => /^(praise|idle)\./.test(id), label: "تشویق و راهنمایی" },
  { id: "rewards",  test: (id) => /^(sticker|rewards|library)\./.test(id), label: "برچسب‌ها و کتابخانه" },
  { id: "session",  test: (id) => /^(session|parent)\./.test(id), label: "توقف، ادامه، والدین" },
];

function groupOf(id) {
  return (GROUPS.find((g) => g.test(id)) || { id: "other" }).id;
}

/** POPO lines have no level number. */
function levelOf() {
  return null;
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
