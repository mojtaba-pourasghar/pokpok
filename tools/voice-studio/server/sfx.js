// صدای حیوان‌ها، وسایل و سازها — every effect the app plays that a real recording could replace.
//
// The list comes from assets/content/asset_manifest.json (audio entries under animals/, sfx/,
// ambient/ and instruments/), so a sound added by tools/sfx/synth.py or fetch_sounds.py shows
// up here with no other step. A replaced file is written over the same path the app already
// plays and goes into the build with the next `flutter build`.
//
// docs/audio/sfx_sources.json (in git) records, for every real recording, where it came from
// and under what licence. A sound with no entry is made by tools/sfx/synth.py.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const AUDIO_EXT = /\.(mp3|wav|ogg|oga|m4a|aac|flac|webm|opus|aif|aiff|wma|mp4)$/i;

export function createSfx({ app, normalize, say, onWrite = () => {} }) {
  const manifestFile = path.join(app, "assets/content/asset_manifest.json");
  const CATEGORIES = [
    { id: "animals", title: "حیوان‌ها" },
    { id: "sfx", title: "وسایل، خانه، شهر، طبیعت" },
    { id: "ambient", title: "صدای محیط" },
    { id: "instruments", title: "سازها" },
  ];
  const sourcesFile = path.join(app, "docs/audio/sfx_sources.json");

  // { sounds: [{ id: "animals/cow", title, category, audio: "audio/animals/cow.mp3" }] }
  const readLevels = () => {
    const assets = JSON.parse(fs.readFileSync(manifestFile, "utf8")).assets || [];
    const sounds = assets
      .filter((a) => a.path.startsWith("audio/") && CATEGORIES.some((c) => a.group.split("/")[0] === c.id))
      .map((a) => ({ id: a.id.replace(/\//g, "."), key: a.id, title: a.id.split("/").pop().replace(/_/g, " "), category: a.group.split("/")[0], audio: a.path }));
    return { categories: CATEGORIES, sounds };
  };

  const readSources = () => {
    try {
      return JSON.parse(fs.readFileSync(sourcesFile, "utf8"));
    } catch {
      return {
        note: "صداهای ضبط واقعی با منبع و مجوز. صدایی که اینجا نیست با tools/sfx/synth.py ساخته شده است.",
        files: {},
      };
    }
  };

  const writeSources = (data) => {
    fs.mkdirSync(path.dirname(sourcesFile), { recursive: true });
    const files = Object.fromEntries(Object.entries(data.files).sort(([a], [b]) => a.localeCompare(b)));
    const temp = sourcesFile + ".tmp";
    fs.writeFileSync(temp, JSON.stringify({ ...data, files }, null, 2) + "\n", "utf8");
    fs.renameSync(temp, sourcesFile);
  };

  const soundOf = (id) => {
    const sound = (readLevels().sounds || []).find((s) => s.id === id);
    if (!sound) throw new Error(`صدای «${id}» در asset_manifest.json نیست`);
    return sound;
  };

  const fileOf = (id) => {
    try {
      return path.join(app, "assets", soundOf(id).audio);
    } catch {
      return null;
    }
  };

  return {
    sourcesFile,
    /** Ambient sounds and music are loops (.ogg), cleaned differently from one-shot effects. */
    isLoop: (id) => soundOf(id).audio.endsWith(".ogg"),
    fileOf,

    list() {
      const levels = readLevels();
      const sources = readSources().files;
      const categories = Object.fromEntries((levels.categories || []).map((c) => [c.id, c.title]));
      return {
        sourcesFile,
        categories: (levels.categories || []).map((c) => ({ id: c.id, title: c.title })),
        sounds: (levels.sounds || []).map((s) => {
          const file = path.join(app, "assets", s.audio);
          const exists = fs.existsSync(file);
          return {
            id: s.id,
            title: s.title,
            category: s.category,
            categoryTitle: categories[s.category] || s.category,
            file: s.audio,
            exists,
            size: exists ? fs.statSync(file).size : 0,
            stamp: exists ? fs.statSync(file).mtimeMs : 0,
            real: Boolean(sources[s.key]),
            source: sources[s.key] || null,
          };
        }),
      };
    },

    /** Cleans the dropped file with ffmpeg and writes it over the sound's own path. */
    async replace(id, buffer, { name = "", source = "", license = "", maxSeconds = 6 } = {}) {
      const sound = soundOf(id);
      if (name && !AUDIO_EXT.test(name)) throw new Error(`«${name}» فایلِ صوتی به نظر نمی‌رسد`);
      const target = path.join(app, "assets", sound.audio);
      const temp = fs.mkdtempSync(path.join(os.tmpdir(), "popo-sfx-"));
      const input = path.join(temp, "in" + (path.extname(name) || ".bin"));
      const loop = sound.audio.endsWith(".ogg");
      const output = path.join(temp, loop ? "out.ogg" : "out.mp3");
      try {
        fs.writeFileSync(input, buffer);
        const done = await normalize(input, output, maxSeconds, { loop });
        if (!done.ok) throw new Error(`ffmpeg نتوانست فایل را بخواند: ${done.error || "؟"}`);
        if (fs.statSync(output).size < 1024) throw new Error("خروجی تقریباً خالی است — فایل صدا دارد؟");
        fs.mkdirSync(path.dirname(target), { recursive: true });
        fs.copyFileSync(output, target);
      } finally {
        fs.rmSync(temp, { recursive: true, force: true });
      }

      const data = readSources();
      data.files[sound.key] = {
        file: sound.audio,
        original: name,
        source: source.trim(),
        license: license.trim(),
        at: new Date().toISOString(),
      };
      writeSources(data);
      const size = fs.statSync(target).size;
      onWrite();
      say("ok", `صدای «${sound.title}» جایگزین شد ← ${sound.audio} (${Math.round(size / 1024)} کیلوبایت)`);
      return { ok: true, id, file: sound.audio, size };
    },

    /** Source and licence can be filled in after the file was replaced. */
    setMeta(id, { source, license }) {
      const { key } = soundOf(id);
      const data = readSources();
      if (!data.files[key]) throw new Error("این صدا هنوز جایگزین نشده است");
      if (typeof source === "string") data.files[key].source = source.trim();
      if (typeof license === "string") data.files[key].license = license.trim();
      writeSources(data);
      return { ok: true };
    },
  };
}
