import path from "node:path";
import { Client } from "basic-ftp";

// Putting the finished files on the host.
// The clips and the worksheets are made here and have to end up on the teacher's own server.
// This does that over FTP: it connects, makes the folder if it is not there, and sends the files.
// The password is only ever read from the studio's own config file on this machine and is never written to the log.

const CONNECT_MS = 25000;

/** What an FTP failure usually means, in words the person can act on. */
export function ftpHint(err, { host, port, secure }) {
  const code = err?.code || "";
  const text = `${code} ${err?.message || ""}`;
  if (code === "ENOTFOUND" || code === "EAI_AGAIN") {
    return `آدرس «${host}» پیدا نشد — نام سرور را بررسی کنید (معمولاً ftp.<دومنه> یا خودِ دامنه).`;
  }
  if (code === "ECONNREFUSED") return `پورت ${port} روی ${host} بسته است — پورت را بررسی کنید.`;
  if (code === "ETIMEDOUT" || code === "ERR_SOCKET_CONNECTION_TIMEOUT" || /timeout/i.test(text)) {
    return `تا ${host}:${port} جوابی نیامد — فایروال، آنتی‌ویروس، یا پورت اشتباه.`;
  }
  if (code === "ECONNRESET" || code === "EPIPE") {
    return secure
      ? "اتصال قطع شد — شاید هاست FTPS نمی‌خواهد؛ تیک FTPS را بردارید."
      : "اتصال قطع شد — شاید هاست FTPS می‌خواهد؛ تیک FTPS را بزنید.";
  }
  if (/\b530\b/.test(text)) return "نام کاربری یا رمز را قبول نکرد (۵۳۰).";
  if (/\b550\b/.test(text)) return "به آن پوشه اجازه نداد (۵۵۰) — مسیر را بررسی کنید.";
  if (/\b425\b|\b421\b|passive/i.test(text)) {
    return "کانال داده باز نشد (passive) — هاست باید حالت passive را مجاز کند.";
  }
  if (/self.signed|certificate/i.test(text)) return "گواهی TLS مشکل دارد — تیک FTPS را بردارید.";
  return "";
}

/** One client, with the conversation on the wire reported line by line.
 *
 * `onLine` gets every command and reply — this is what turns «هیچ لاگی نمی‌زند» into a visible handshake.
 * `connect` races the handshake against a timeout of our own. Without it a blocked port leaves
 * the page waiting with nothing on screen, which is exactly how this looked broken.
 */
function clientFor({ host, port, user, password, secure }, { onLine = null } = {}) {
  const client = new Client(CONNECT_MS);
  const clean = (text) => {
    const line = String(text);
    return password ? line.split(String(password)).join("###") : line;
  };
  if (onLine) {
    client.ftp.verbose = true;
    client.ftp.log = (message) => onLine(clean(message).trim().slice(0, 300));
  } else {
    client.ftp.verbose = false;
  }

  const where = `${String(host || "").trim()}:${Number(port) || 21}`;
  const connect = async () => {
    let timer;
    const expired = new Promise((_, reject) => {
      timer = setTimeout(() => {
        const err = new Error(`تا ${CONNECT_MS / 1000} ثانیه از ${where} جوابی نیامد`);
        err.code = "ERR_SOCKET_CONNECTION_TIMEOUT";
        reject(err);
      }, CONNECT_MS);
    });
    try {
      return await Promise.race([client.access({ host, port, user, password, secure }), expired]);
    } finally {
      clearTimeout(timer);
    }
  };

  return { client, connect, where };
}

/** کمترین کلاینت FTP برای آپلود تصاویر خبرها روی سرور (مثل configureِ هوهو ریاضی). */
export function createFtp(cfg = {}, { onLine = null } = {}) {
  cfg = cfg || {};
  const host = String(cfg.host || "").trim();
  const port = Number(cfg.port) || 21;
  const user = String(cfg.user || "").trim();
  const password = String(cfg.password || "");
  const remotePath = String(cfg.path || "/").trim();
  const secure = Boolean(cfg.secure);

  /** اتصال و بررسی اتصال به سرور FTP. */
  async function test() {
    if (!host) throw new Error("میزبان FTP مشخص نشده است");
    const { client, connect, where } = clientFor({ host, port, user, password, secure }, { onLine });
    try {
      await connect();
      return true;
    } catch (err) {
      const hint = ftpHint(err, { host, port, secure });
      throw new Error(hint ? `${hint} (${err.message})` : `اتصال FTP برقرار نشد: ${err.message}`);
    } finally {
      client.close();
    }
  }

  /**
   * چند فایل در یک اتصال، به ترتیب داده‌شده (مثل انتشارِ هوهو ریاضی: اول عکس‌ها، آخر notices.json).
   * remoteName نسبی به remotePath است و می‌تواند پوشه داشته باشد (notices/<sha>.webp).
   */
  async function putAll(items, onStep = () => {}) {
    if (!host) throw new Error("میزبان FTP تنظیم نشده است");
    const { client, connect } = clientFor({ host, port, user, password, secure }, { onLine });
    try {
      await connect();
      for (const { localFile, remoteName } of items) {
        const remoteFile = path.posix.join("/", remotePath || "/", String(remoteName).replace(/\\/g, "/"));
        await client.ensureDir(path.posix.dirname(remoteFile));
        await client.uploadFrom(localFile, path.posix.basename(remoteFile));
        onStep(remoteFile);
      }
      return { host, port };
    } catch (err) {
      const hint = ftpHint(err, { host, port, secure });
      throw new Error(hint ? `${hint} (${err.message})` : `آپلود FTP شکست خورد: ${err.message}`);
    } finally {
      client.close();
    }
  }

  const put = ({ localFile, remoteName }) => putAll([{ localFile, remoteName }]);

  return { test, put, putAll, host, port, remotePath, secure };
}