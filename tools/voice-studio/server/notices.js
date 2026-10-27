// خبرهای امضاشده‌ی پوپو: نوشتن، امضا و انتشار روی R2 (popo/notices.json).
//
// هر کس به CDN یا سطل R2 دسترسی پیدا کند می‌تواند notices.json را عوض کند. بی‌امضا، نوشته‌ی او
// روی صفحه‌ی هر کودکی که پوپو دارد می‌آمد. پس فایل همین‌جا، روی همین رایانه، امضا می‌شود و برنامه
// هرچه را نتواند بیازماید دور می‌ریزد (lib/core/notices/notice_seal.dart و android/…/NoticeCenter.kt).
//
// نیمه‌ی خصوصی کلید فقط در voice-studio.config.json است (در گیت نیست). نیمه‌ی عمومی در
// assets/notices/notice-key.pub نوشته می‌شود و همراه برنامه می‌رود؛ با آن فقط می‌شود امضا را آزمود.
// رمز مشترکی که در APK باشد کار نمی‌کرد: با باز کردن APK به دست همه می‌افتد.
//
// شکل فایل منتشرشده (یک فایل، تا cache هیچ‌وقت متن و امضای ناهمخوان نشان ندهد):
//   {"alg":"RSA-SHA256","body":"<base64 بایت‌های JSON خبرها>","sig":"<base64 امضا>"}
// تصویرها امضا نمی‌شوند؛ نامشان sha256 خودشان است و همان درهم‌سازی در متن امضاشده آمده.

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { spawn } from "node:child_process";
import { createFtp } from "./ftp.js";

export const NOTICE_DEFAULTS = { bucket: "popo-assets" };

export const LIMITS = { title: 80, body: 600, imageBytes: 2 * 1024 * 1024, fileBytes: 256 * 1024 };

const IMAGE_TYPES = { webp: "image/webp", png: "image/png", jpg: "image/jpeg", jpeg: "image/jpeg" };

/** Values the app understands for `screen` (lib/features/notices/notice_card.dart noticeScreens) plus ANYWHERE. */
export const SCREENS = ["ANYWHERE", "HOME", "WORKSHOP", "PLAYROOM", "ME",
  "CHAPTER_1", "CHAPTER_2", "CHAPTER_3", "CHAPTER_4", "CHAPTER_5", "CHAPTER_6", "CHAPTER_7", "CHAPTER_8",
  "DOWNLOADS", "PAYWALL",
  // names from the first version; the app still opens something sensible for them
  "LIBRARY", "WORLD_HOME", "WORLD_CITY", "WORLD_NATURE", "ART", "MUSIC", "BUILD", "REWARDS"];

export function makeKeyPair() {
  return crypto.generateKeyPairSync("rsa", {
    modulusLength: 2048,
    publicKeyEncoding: { type: "spki", format: "pem" },
    privateKeyEncoding: { type: "pkcs8", format: "pem" },
  });
}

/** پاکت امضاشده؛ همان بایت‌هایی امضا می‌شوند که در body می‌روند. */
export function seal(list, privateKey, now = Date.now()) {
  const body = Buffer.from(JSON.stringify({ v: 1, at: now, notices: list.map(publicShape) }), "utf8");
  const sig = crypto.sign("sha256", body, privateKey).toString("base64");
  return JSON.stringify({ alg: "RSA-SHA256", body: body.toString("base64"), sig });
}

/** آزمودن پاکت با کلید عمومی (برای بررسی پیش از انتشار). */
export function unseal(envelope, publicKey) {
  const root = JSON.parse(envelope);
  if (root.alg !== "RSA-SHA256") return null;
  const body = Buffer.from(root.body, "base64");
  return crypto.verify("sha256", body, publicKey, Buffer.from(root.sig, "base64")) ? JSON.parse(body.toString("utf8")) : null;
}

/** فقط آنچه برنامه می‌خواند؛ چیز دیگری (یادداشت‌های استودیو) بیرون نمی‌رود. */
function publicShape(n) {
  const out = { id: n.id, title: n.title };
  if (n.body) out.body = n.body;
  if (n.image && n.imageSha256) { out.image = n.image; out.imageSha256 = n.imageSha256; }
  if (n.link) out.link = n.link;
  if (n.screen) out.screen = n.screen;
  if (n.from) out.from = n.from;
  if (n.until) out.until = n.until;
  return out;
}

/** شناسه‌ی تازه، هرگز تکراری: «دیده شد» در گوشی با همین نگه داشته می‌شود. */
export function freshId(list, now = Date.now()) {
  let id;
  do id = `n${now.toString(36)}${crypto.randomBytes(2).toString("hex")}`;

  while (list.some((n) => n.id === id));
  return id;
}

const toMillis = (v) => {
  if (v === undefined || v === null || v === "") return 0;
  const n = typeof v === "number" ? v : Date.parse(String(v));
  return Number.isFinite(n) && n > 0 ? Math.round(n) : NaN;
};

/** خبر درست‌شده از فرم، یا پیام خطا. */
export function normalize(input) {
  const title = String(input.title || "").trim();
  const body = String(input.body || "").trim();
  const link = String(input.link || "").trim();
  if (!title) return { error: "عنوان لازم است" };
  if (title.length > LIMITS.title) return { error: `عنوان بیش از ${LIMITS.title} نویسه است` };
  if (body.length > LIMITS.body) return { error: `متن بیش از ${LIMITS.body} نویسه است` };
  if (link && !/^https:\/\/[^\s]+$/i.test(link)) return { error: "پیوند باید نشانی کامل https:// باشد" };
  const from = toMillis(input.from);
  const until = toMillis(input.until);
  if (Number.isNaN(from) || Number.isNaN(until)) return { error: "تاریخ درست نیست" };
  if (from && until && until <= from) return { error: "پایان باید بعد از شروع باشد" };
  // where the app goes when it is tapped (lib/features/notices/notice_card.dart noticeScreens), or ANYWHERE
  const screen = String(input.screen || "").trim();
  if (screen && !SCREENS.includes(screen)) return { error: `صفحه‌ی «${screen}» شناخته نشد` };
  return { notice: { title, body, link, screen, from, until } };
}

/** تصویر از base64 (data URL یا خام) → { name: notices/<sha>.<ext>, sha, bytes } */
export function imageFrom(name, base64) {
  const ext = String(name || "").toLowerCase().split(".").pop();
  if (!IMAGE_TYPES[ext]) throw new Error("تصویر باید webp، png یا jpg باشد");
  const bytes = Buffer.from(String(base64).split(",").pop(), "base64");
  if (!bytes.length) throw new Error("تصویر خالی است");
  if (bytes.length > LIMITS.imageBytes) throw new Error("تصویر بیش از ۲ مگابایت است");
  const sha = crypto.createHash("sha256").update(bytes).digest("hex");
  return { name: `notices/${sha}.${ext === "jpeg" ? "jpg" : ext}`, sha, bytes };

}

export function contentType(file) {
  return IMAGE_TYPES[file.split(".").pop().toLowerCase()] || "application/octet-stream";
}

/** یک فایل را با wrangler در R2 می‌گذارد (همان راه cloudflare/scripts/upload.sh؛ ورود با 
px wrangler@4 login`). */
export function wranglerPut({ bucket, key, file, type, cache, cwd }) {
  const args = ["--yes", "wrangler@4", "r2", "object", "put", `${bucket}/${key}`, "--file", file, "--remote",
    "--content-type", type, "--cache-control", cache];
  return new Promise((resolve, reject) => {
    const child = spawn("npx", args, { cwd, shell: process.platform === "win32" });
    let out = "";
    child.stdout.on("data", (d) => { out += d; });
    child.stderr.on("data", (d) => { out += d; });
    child.on("error", reject);
    child.on("close", (code) => (code === 0 ? resolve(out) : reject(new Error(`wrangler (${code}): ${out.slice(-800)}`))));
  });
}

/**
 * فهرست خبرها روی همین رایانه (tools/voice-studio/notices.json و تصویرها کنارش). هیچ چیزی تا
 * زدن «انتشار» بیرون نمی‌رود؛ انتشار کل فهرست را امضا می‌کند و یک‌جا می‌گذارد.
 */
export function createNotices({ dir, keyAsset, getConfig, saveConfig, say, put = wranglerPut }) {
  const listFile = path.join(dir, "notices.json");

  const read = () => {
    let data;
    try {
      data = JSON.parse(fs.readFileSync(listFile, "utf8"));
    } catch {
      data = {};
    }
    // An earlier publish wrote the signed envelope over this list; take the notices back out of it.
    if (data && data.alg && typeof data.body === "string") {
      try {
        const inner = JSON.parse(Buffer.from(data.body, "base64").toString("utf8"));
        data = { notices: Array.isArray(inner.notices) ? inner.notices : [], publishedAt: inner.at || 0 };
      } catch {
        data = {};
      }
    }
    if (!data || typeof data !== "object") data = {};
    if (!Array.isArray(data.notices)) data.notices = [];
    if (!data.publishedAt) data.publishedAt = 0;
    return data;
  };
  const write = (data) => {
    fs.mkdirSync(dir, { recursive: true });
    const temp = listFile + ".tmp";
    fs.writeFileSync(temp, JSON.stringify(data, null, 2), "utf8");
    fs.renameSync(temp, listFile);
  };

  const keyState = () => {
    const cfg = getConfig();
    const exists = fs.existsSync(keyAsset);
    return {
      hasPrivate: Boolean(cfg.noticeKeyPrivate),
      assetPath: keyAsset,
      assetExists: exists,
      // کلید فایل با کلید ذخیره‌شده یکی است؟ اگر نه، برنامه‌ی ساخته‌شده خبرها را نمی‌پذیرد.
      assetMatches: Boolean(cfg.noticeKeyPublic) && exists
        && fs.readFileSync(keyAsset, "utf8").trim() === String(cfg.noticeKeyPublic).trim(),
    };
  };

  const api = {
    keyState,
    list: () => ({ ...read(), key: keyState(), bucket: getConfig().notices?.bucket || NOTICE_DEFAULTS.bucket }),

    makeKey(replace) {
      const cfg = getConfig();
      if (cfg.noticeKeyPrivate && replace !== true) {
        const err = new Error("کلید امضا از قبل ساخته شده. کلید تازه یعنی برنامه‌هایی که الان نصب‌اند تا "
          + "نسخه‌ی تازه را نگیرند هیچ خبری را نمی‌پذیرند.");
        err.status = 409;
        throw err;
      }
      const { privateKey, publicKey } = makeKeyPair();
      cfg.noticeKeyPrivate = privateKey;
      cfg.noticeKeyPublic = publicKey;
      saveConfig();
      fs.mkdirSync(path.dirname(keyAsset), { recursive: true });
      fs.writeFileSync(keyAsset, publicKey, "utf8");
      say("ok", "کلید امضای خبرها ساخته شد؛ assets/notices/notice-key.pub را کامیت کنید و نسخه‌ی تازه بسازید.");
      say("warn", "نیمه‌ی خصوصی فقط در voice-studio.config.json است. گمش کنید، دیگر نمی‌شود خبر امضا کرد.");
      return keyState();
    },

    save(input) {
      const { notice, error } = normalize(input);
      if (error) throw new Error(error);
      const data = read();
      const old = input.id ? data.notices.find((n) => n.id === input.id) : null;
      if (input.imageBase64) {
        const img = imageFrom(input.imageName, input.imageBase64);
        fs.mkdirSync(path.join(dir, "notices"), { recursive: true });
        fs.writeFileSync(path.join(dir, img.name), img.bytes);
        notice.image = img.name;
        notice.imageSha256 = img.sha;
      } else if (old && input.removeImage !== true) {
        notice.image = old.image || "";
        notice.imageSha256 = old.imageSha256 || "";
      }
      if (old) Object.assign(old, notice, { editedAt: Date.now() });
      else data.notices.unshift({ id: freshId(data.notices), ...notice, createdAt: Date.now() });
      data.dirty = true;
      write(data);
      return api.list();
    },

    remove(id) {
      const data = read();
      data.notices = data.notices.filter((n) => n.id !== id);
      data.dirty = true;
      write(data);
      return api.list();
    },

    move(id, delta) {
      const data = read();
      const i = data.notices.findIndex((n) => n.id === id);
      const j = i + delta;
      if (i >= 0 && j >= 0 && j < data.notices.length) {
        [data.notices[i], data.notices[j]] = [data.notices[j], data.notices[i]];
        data.dirty = true;
        write(data);
      }
      return api.list();
    },

    /** امضا، آزمودن با کلید عمومی، گذاشتن تصویرها و در آخر خود فایل (تا فایل به تصویر نبوده اشاره نکند). */
    async publish({ ftp } = {}) {
      const cfg = getConfig();
      if (!cfg.noticeKeyPrivate) throw new Error("اول کلید امضا را بسازید");
      const data = read();
      const now = Date.now();
      const live = data.notices.filter((n) => !n.until || n.until > now);
      const envelope = seal(live, cfg.noticeKeyPrivate, now);
      if (Buffer.byteLength(envelope) > LIMITS.fileBytes) throw new Error("فایل خبرها بیش از ۲۵۶ کیلوبایت است");
      if (!unseal(envelope, cfg.noticeKeyPublic)) throw new Error("امضا با کلید عمومی نخواند — کلید را بررسی کنید");
      if (!keyState().assetMatches) {
        say("warn", "assets/notices/notice-key.pub با کلید ذخیره‌شده یکی نیست؛ برنامه این خبرها را نمی‌پذیرد.");
      }

      // The signed file is written beside the list (published/), never over the list itself.
      const out = path.join(dir, "published", "notices.json");
      fs.mkdirSync(path.dirname(out), { recursive: true });
      fs.writeFileSync(out, envelope, "utf8");

      const ftpClient = ftp || (cfg.ftp?.host ? createFtp(cfg.ftp) : null);
      if (ftpClient) {
        // Exactly like هوهو ریاضی: one FTP session, pictures first (a notice must never point
        // at a picture that is not there yet), the signed notices.json last.
        const items = live.filter((n) => n.image).map((n) => ({ localFile: path.join(dir, n.image), remoteName: n.image }));
        for (const item of items) {
          if (!fs.existsSync(item.localFile)) throw new Error(`تصویر ${item.remoteName} روی این رایانه نیست`);
        }
        items.push({ localFile: out, remoteName: "notices.json" });
        say("info", `انتشار با FTP: ${ftpClient.host}:${ftpClient.port}${ftpClient.remotePath} — ${items.length} فایل`);
        await ftpClient.putAll(items, (remote) => say("info", `FTP ← ${remote}`));
        Object.assign(data, { publishedAt: now, dirty: false, publishedCount: live.length });
        write(data);
        say("ok", `${live.length} خبر امضا و با FTP منتشر شد (${ftpClient.remotePath}/notices.json).`);
        return api.list();
      }

      const bucket = cfg.notices?.bucket || NOTICE_DEFAULTS.bucket;
      const uploaded = new Set(data.uploaded || []);
      for (const n of live) {
        if (!n.image || uploaded.has(n.image)) continue;
        await put({ bucket, key: `popo/${n.image}`, file: path.join(dir, n.image), type: contentType(n.image),
          cache: "public, max-age=31536000, immutable", cwd: dir });
        uploaded.add(n.image);
        say("info", `تصویر ${n.image} گذاشته شد`);
      }
      await put({ bucket, key: "popo/notices.json", file: out, type: "application/json; charset=utf-8",
        cache: "public, max-age=300", cwd: dir });

      Object.assign(data, { publishedAt: now, dirty: false, uploaded: [...uploaded], publishedCount: live.length });
      write(data);
      say("ok", `${live.length} خبر امضا و منتشر شد (popo/notices.json). تا ۵ دقیقه به گوشی‌ها می‌رسد.`);
      return api.list();
    },
  };
  return api;
}






