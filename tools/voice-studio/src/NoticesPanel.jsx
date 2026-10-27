import React, { useEffect, useState } from "react";
import {
  toJalali, fromJalali, daysInJalaliMonth, columnOf, spell, todayJalali,
  MONTHS, WEEKDAYS, pad2, fa as faDigits,
} from "./shamsi.js";

// خبرهای امضاشده (server/notices.js): نوشتن، امضا و انتشار روی R2 به popo/notices.json.
// برنامه فقط آنچه با کلید همین رایانه امضا شده نشان می‌دهد (lib/core/notices/notices_store.dart).

async function call(path, method = "GET", body) {
  const res = await fetch("/api" + path, {
    method, headers: { "Content-Type": "application/json" }, body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  const data = text ? JSON.parse(text) : {};
  if (!res.ok) throw new Error(data.error || `HTTP ${res.status}`);
  return data;
}

const EMPTY = { id: "", title: "", body: "", link: "", screen: "", from: "", until: "", imageName: "", imageBase64: "", removeImage: false };

/** Where a tapped notice opens — the same list the app knows (lib/features/notices/notice_card.dart). */
const SCREEN_OPTIONS = [
  ["", "هیچ‌جا — فقط متن، روی نقشه"],
  ["ANYWHERE", "⚡ هر جای برنامه بود — همان‌جا نشانش بده"],
  ["HOME", "نقشه"],
  ["LIBRARY", "همه‌ی بازی‌ها"],
  ["WORLD_HOME", "جهان خانه‌ی من"],
  ["WORLD_CITY", "جهان شهر بازی"],
  ["WORLD_NATURE", "جهان طبیعت"],
  ["ART", "هنر و نقاشی"],
  ["MUSIC", "استودیوی موسیقی"],
  ["BUILD", "کارگاه ساخت‌وساز"],
  ["REWARDS", "برچسب‌ها"],
  ["DOWNLOADS", "دانلود محتوا (والدین)"],
  ["PAYWALL", "نسخه‌ی کامل"],
];

/** فرم، تاریخ و ساعت را همان‌طور که هست (milliseconds) نگه می‌دارد؛ ساعت نباید گم شود. */
const toInput = (ms) => (ms ? Number(ms) : "");

/** از فرم به سرور: خالی یعنی «بی‌تاریخ» = ۰. */
const fromInput = (s) => (s ? Number(s) : 0);
const when = (ms) => (ms ? spell(ms) : "");

function readFile(file) {
  return new Promise((resolve, reject) => {
    const r = new FileReader();
    r.onload = () => resolve(r.result);
    r.onerror = reject;
    r.readAsDataURL(file);
  });
}

/**
 * تقویم فارسی — چون<input type="date"> تقویم میلادی نشان می‌دهد و برای کاربر فارسی
 * تاریخ‌های شمسی لازم است. روز هفته از شنبه آغاز می‌شود.
 */
function ShamsiPicker({ value, onChange, placeholder = "انتخاب نشده", defaultTime = [9, 0] }) {
  const [open, setOpen] = useState(false);
  const start = value ? new Date(value) : new Date();
  const shown = toJalali(new Date(Date.UTC(start.getFullYear(), start.getMonth(), start.getDate())));
  const [at, setAt] = useState({ jy: shown.jy, jm: shown.jm });

  const days = daysInJalaliMonth(at.jy, at.jm);
  const firstDay = fromJalali(at.jy, at.jm, 1);
  const blanks = firstDay ? columnOf(firstDay) : 0;
  const chosen = value ? toJalali(new Date(Date.UTC(start.getFullYear(), start.getMonth(), start.getDate()))) : null;
  const today = todayJalali();

  // ساعت و دقیقه‌ی فعلی؛ اگر هنوز تاریخی نیست، پیش‌فرض (مثلاً ۰۹:۰۰ برای شروع، ۲۳:۵۹ برای پایان).
  const hh = value ? start.getHours() : defaultTime[0];
  const mi = value ? start.getMinutes() : defaultTime[1];

  // روز را که بزنی، همان لحظه با ساعتِ فعلی ثبت می‌شود؛ «تأیید» فقط پنجره را می‌بندد.
  const pick = (jd, h = hh, m = mi) => {
    const when = fromJalali(at.jy, at.jm, jd, h, m);
    if (when) onChange(when.getTime());
  };

  // تغییر ساعت: روی همان روزِ انتخاب‌شده؛ اگر روزی نیست، روی «امروز».
  const setTime = (h, m) => {
    h = Math.min(23, Math.max(0, Number(h) || 0));
    m = Math.min(59, Math.max(0, Number(m) || 0));
    const day = chosen || today;
    const when = fromJalali(day.jy, day.jm, day.jd, h, m);
    if (when) onChange(when.getTime());
  };

  const move = (by) => {
    let jm = at.jm + by, jy = at.jy;
    if (jm < 1) { jm = 12; jy -= 1; }
    if (jm > 12) { jm = 1; jy += 1; }
    setAt({ jy, jm });
  };

  return (
    <div style={{ position: "relative" }}>
      {/* فقط «ghost»: با «go» متن سفید روی زمینه‌ی سفید می‌افتاد و تاریخِ ثبت‌شده دیده نمی‌شد. */}
      <button type="button" className="ghost" style={{
                width: "100%", textAlign: "start",
                color: value ? "var(--ink)" : "var(--muted)", fontWeight: value ? 700 : 400 }}
              onClick={() => {
                if (!open) { const s = value ? chosen : today; setAt({ jy: s.jy, jm: s.jm }); }
                setOpen(!open);
              }}>
        📅 {value ? spell(value) : placeholder}
      </button>

      {open && (
        <div className="card" style={{
          position: "absolute", zIndex: 30, insetInlineStart: 0, marginTop: 6,
          width: 290, padding: 12, boxShadow: "0 10px 30px rgba(0,0,0,.18)" }}>
          <div className="row" style={{ justifyContent: "space-between", alignItems: "center" }}>
            <button type="button" className="tiny ghost" onClick={() => move(-1)}>‹</button>
            <b>{MONTHS[at.jm - 1]} {faDigits(at.jy)}</b>
            <button type="button" className="tiny ghost" onClick={() => move(1)}>›</button>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "repeat(7, 1fr)", gap: 2, marginTop: 10 }}>
            {WEEKDAYS.map(w => (
              <div key={w} style={{ textAlign: "center", fontSize: 11, color: "var(--muted)" }}>{w}</div>
            ))}
            {Array.from({ length: blanks }).map((_, i) => <div key={`b${i}`} />)}
            {Array.from({ length: days }).map((_, i) => {
              const jd = i + 1;
              const isChosen = chosen && chosen.jy === at.jy && chosen.jm === at.jm && chosen.jd === jd;
              const isToday = today.jy === at.jy && today.jm === at.jm && today.jd === jd;
              return (
                <button key={jd} type="button" onClick={() => pick(jd)} style={{
                  padding: "6px 0", fontSize: 12.5, borderRadius: 8,
                  background: isChosen ? "var(--teal)" : isToday ? "var(--orange-soft)" : "transparent",
                  color: isChosen ? "#fff" : "var(--ink)",
                  border: isToday && !isChosen ? "1px solid var(--orange)" : "1px solid transparent",
                }}>{faDigits(jd)}</button>
              );
            })}
          </div>

          <div className="row" style={{ marginTop: 10, gap: 6, alignItems: "center", direction: "ltr", justifyContent: "center" }}>
            <span className="note" style={{ direction: "rtl" }}>ساعت</span>
            <select value={hh} onChange={(e) => setTime(e.target.value, mi)} style={{ width: 64 }}>
              {Array.from({ length: 24 }, (_, h) => <option key={h} value={h}>{pad2(h)}</option>)}
            </select>
            <b>:</b>
            <select value={mi} onChange={(e) => setTime(hh, e.target.value)} style={{ width: 64 }}>
              {Array.from({ length: 60 }, (_, m) => <option key={m} value={m}>{pad2(m)}</option>)}
            </select>
          </div>
          {!value && (
            <p className="note" style={{ margin: "6px 0 0", textAlign: "center" }}>
              روز را بزن؛ ساعت {faDigits(pad2(hh))}:{faDigits(pad2(mi))} با آن ثبت می‌شود.
            </p>
          )}

          <div className="row" style={{ marginTop: 10, gap: 6 }}>
            <button type="button" className="tiny ghost" onClick={() => {
              setAt({ jy: today.jy, jm: today.jm });
              // مستقیم با ماهِ امروز؛ «pick» ماهِ در حال نمایش (at) را می‌خواند که هنوز به‌روز نشده.
              const t = fromJalali(today.jy, today.jm, today.jd, hh, mi);
              if (t) onChange(t.getTime());
            }}>امروز</button>
            <button type="button" className="warn tiny" onClick={() => { onChange(0); setOpen(false); }}>
              پاک کردن
            </button>
            <button type="button" className="go tiny" style={{ marginInlineStart: "auto" }}
                    onClick={() => setOpen(false)}>تأیید</button>
          </div>
        </div>
      )}
    </div>
  );
}

export default function NoticesPanel() {
  const [data, setData] = useState(null);
  const [form, setForm] = useState(EMPTY);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [bucket, setBucket] = useState("");
  const [ftp, setFtp] = useState({ host: "", port: 21, user: "", password: "", path: "/", secure: false });

  const run = async (fn) => {
    setBusy(true);
    try {
      const next = await fn();
      setData(next);
      setError("");
      return true;
    } catch (err) {
      setError(err.message);
      return false;
    } finally {
      setBusy(false);
    }
  };

  useEffect(() => { run(() => call("/notices")); }, []);
  useEffect(() => { if (data?.bucket) setBucket(data.bucket); }, [data?.bucket]);
  // Saved FTP settings arrive once with the list (password as a mask, never the real one).
  const [ftpLoaded, setFtpLoaded] = useState(false);
  useEffect(() => {
    if (!ftpLoaded && data?.ftp) { setFtp((f) => ({ ...f, ...data.ftp })); setFtpLoaded(true); }
  }, [data?.ftp, ftpLoaded]);

  // The FTP result is shown beside its own buttons — the notice card's error box is far up the page.
  const [ftpState, setFtpState] = useState({ kind: "", text: "" });
  const [ftpBusy, setFtpBusy] = useState(false);
  const ftpBody = () => ({
    host: ftp.host, port: ftp.port, user: ftp.user, password: ftp.password,
    path: ftp.path, secure: ftp.secure,
  });
  const saveFtp = async () => {
    setFtpBusy(true);
    try {
      const res = await call("/ftp/settings", "POST", ftpBody());
      if (res.ftp) setFtp((f) => ({ ...f, ...res.ftp }));
      setFtpState({ kind: "ok", text: "تنظیمات FTP ذخیره شد ✓" });
    } catch (err) {
      setFtpState({ kind: "bad", text: err.message });
    } finally { setFtpBusy(false); }
  };
  const testFtp = async () => {
    setFtpBusy(true);
    setFtpState({ kind: "warn", text: `در حال اتصال به ${ftp.host}:${ftp.port} … (تا ۲۵ ثانیه؛ جزئیات در لاگ پایین صفحه)` });
    try {
      const res = await call("/ftp/test", "POST", ftpBody());
      setFtpState({ kind: "ok", text: `اتصال FTP به ${res.host}:${res.port} برقرار شد ✓ — برای ماندگاری «ذخیره» را هم بزنید` });
    } catch (err) {
      setFtpState({ kind: "bad", text: err.message });
    } finally { setFtpBusy(false); }
  };

  if (!data) return <div className="card">{error ? <div className="err">{error}</div> : "…"}</div>;
  const key = data.key || {};

  const save = async () => {
    const ok = await run(() => call("/notices", "POST", { ...form, from: fromInput(form.from), until: fromInput(form.until) }));
    if (ok) setForm(EMPTY);
  };
  const edit = (n) => setForm({ ...EMPTY, id: n.id, title: n.title, body: n.body || "", link: n.link || "",
    screen: n.screen || "", from: toInput(n.from), until: toInput(n.until) });
  const publish = () => {
    const count = data.notices.filter((n) => !n.until || n.until > Date.now()).length;
    if (!window.confirm(`${count} خبر امضا و برای همه‌ی گوشی‌ها منتشر شود؟`)) return;
    run(() => call("/notices/publish", "POST", {}));
  };
  const makeKey = async () => {
    const replace = key.hasPrivate;
    if (replace && !window.confirm("کلید تازه یعنی نسخه‌های نصب‌شده تا به‌روز نشوند هیچ خبری را نمی‌پذیرند. ادامه؟")) return;
    if (await run(async () => { await call("/notices/key", "POST", { replace }); return call("/notices"); })) {
      alert("کلید ساخته شد.\n\nassets/notices/notice-key.pub را کامیت کنید و نسخه‌ی تازه بسازید؛ "
        + "تا آن نسخه روی گوشی‌ها نرود، خبرها نشان داده نمی‌شوند.");
    }
  };
  const field = (k, label, extra = {}) => (
    <div>
      <label>{label}</label>
      <input type="text" value={form[k]} onChange={(e) => setForm({ ...form, [k]: e.target.value })} {...extra} />
    </div>
  );

  return (
    <>
      <div className="card" style={{ borderColor: key.hasPrivate && key.assetMatches ? "#3e9e7a" : "#c0392b" }}>
        <h2>🔑 مُهر خبرها <span className="hint">{key.hasPrivate ? "ساخته شده" : "هنوز ساخته نشده"}</span></h2>
        <p className="note">
          هر کس به CDN دسترسی پیدا کند می‌تواند فایل خبرها را عوض کند؛ پس فایل همین‌جا امضا می‌شود و برنامه
          هرچه را نتواند بیازماید نشان نمی‌دهد. نیمه‌ی خصوصی فقط در <code>voice-studio.config.json</code> روی
          همین رایانه است؛ نیمه‌ی عمومی در <code>assets/notices/notice-key.pub</code> نوشته می‌شود.
        </p>
        {key.hasPrivate && !key.assetMatches && (
          <div className="err">assets/notices/notice-key.pub نیست یا با کلید ذخیره‌شده یکی نیست — برنامه خبرها را نمی‌پذیرد.</div>
        )}
        <button className={key.hasPrivate ? "ghost" : "go"} disabled={busy} onClick={makeKey}>
          {key.hasPrivate ? "ساخت کلید تازه (خطرناک)" : "ساخت کلید امضا"}
        </button>
      </div>

      <div className="card">
        <h2>📰 {form.id ? "ویرایش خبر" : "خبر تازه"} <span className="hint">تا «انتشار» را نزنید چیزی بیرون نمی‌رود</span></h2>
        {error && <div className="err">{error}</div>}
        <div className="grid">
          {field("title", "عنوان", { maxLength: 80, placeholder: "مثلاً: صداهای جنگل رسید!" })}
          {field("link", "پیوند برای بزرگ‌ترها (اختیاری، https)", { dir: "ltr", placeholder: "https://cafebazaar.ir/app/com.pokpok.ir" })}
        </div>
        <div style={{ marginTop: 12 }}>
          <label>متن</label>
          <textarea rows={3} style={{ width: "100%" }} maxLength={600} value={form.body}
                    onChange={(e) => setForm({ ...form, body: e.target.value })} />
        </div>
        <div className="grid" style={{ marginTop: 12 }}>
          <div>
<label>از (تاریخ شروع)</label>
<ShamsiPicker value={form.from} onChange={(v) => setForm({ ...form, from: v })} placeholder="۱۴۰۴/۰۱/۰۱" />
          </div>
          <div>
<label>تا (تاریخ پایان، اختیاری)</label>
<ShamsiPicker value={form.until} onChange={(v) => setForm({ ...form, until: v })} placeholder="۱۴۰۴/۱۲/۲۹" defaultTime={[23, 59]} />
          </div>
          <div>
            <label>تصویر (اختیاری، webp/png/jpg، تا ۲ مگابایت، افقی ۲:۱)</label>
            <input type="file" accept=".webp,.png,.jpg,.jpeg" onChange={async (e) => {
              const f = e.target.files?.[0];
              if (f) setForm({ ...form, imageName: f.name, imageBase64: await readFile(f), removeImage: false });
            }} />
            {form.id && (
              <label><input type="checkbox" checked={form.removeImage}
                            onChange={(e) => setForm({ ...form, removeImage: e.target.checked })} /> برداشتن تصویر</label>
            )}
          </div>
          <div>
            <label>📍 کجای برنامه باز شود</label>
            <select value={form.screen} onChange={(e) => setForm({ ...form, screen: e.target.value })}>
              {SCREEN_OPTIONS.map(([v, label]) => <option key={v} value={v}>{label}</option>)}
            </select>
            <span className="note">
              خبر معمولی تا وقتی کودک به نقشه برگردد صبر می‌کند — وسط بازی مزاحمش نمی‌شود.
              «⚡ هر جای برنامه» صبر نمی‌کند.
            </span>
          </div>
        </div>
        <div className="row" style={{ marginTop: 12 }}>
          <button className="go" disabled={busy || !form.title.trim()} onClick={save}>{form.id ? "ذخیره‌ی تغییر" : "افزودن به فهرست"}</button>
          {form.id && <button className="ghost" onClick={() => setForm(EMPTY)}>انصراف</button>}
        </div>
      </div>

      <div className="card">
        <h2>
          فهرست ({data.notices.length})
          <span className="hint">
            {data.publishedAt ? ` آخرین انتشار: ${when(data.publishedAt)}` : " هنوز منتشر نشده"}
            {data.dirty ? " · تغییرهای منتشرنشده" : ""}
          </span>
        </h2>
        {data.notices.map((n, i) => (
          <div key={n.id} className="row" style={{ borderTop: "1px solid var(--line)", padding: "8px 0", opacity: n.until && n.until < Date.now() ? 0.5 : 1 }}>
            <div className="grow">
              <b>{n.title}</b> {n.image && "🖼"} {n.link && "🔗"} {n.screen && `📍 ${n.screen}`}
              <div className="note">{n.body}</div>
              <div className="note">{n.from ? `از ${when(n.from)} ` : ""}{n.until ? `تا ${when(n.until)}` : ""} · <code>{n.id}</code></div>
            </div>
            <button className="ghost" disabled={busy || i === 0} onClick={() => run(() => call(`/notices/${n.id}/move`, "POST", { delta: -1 }))}>▲</button>
            <button className="ghost" disabled={busy || i === data.notices.length - 1} onClick={() => run(() => call(`/notices/${n.id}/move`, "POST", { delta: 1 }))}>▼</button>
            <button className="ghost" disabled={busy} onClick={() => edit(n)}>ویرایش</button>
            <button className="warn" disabled={busy} onClick={() => window.confirm(`«${n.title}» پاک شود؟`) && run(() => call(`/notices/${n.id}`, "DELETE"))}>پاک</button>
          </div>
        ))}
        <div className="row" style={{ marginTop: 12 }}>
          <button className="go" disabled={busy || !key.hasPrivate} onClick={publish}>
            {busy ? "…" : "امضا و انتشار"}
          </button>
          <span className="note">
            {data.ftp?.host
              ? <>با FTP به <code>{data.ftp.host}{(data.ftp.path || "/").replace(/\/$/, "")}/notices.json</code> (اول عکس‌ها، آخر خودِ فایل).</>
              : <>به <code>{data.bucket}/popo/notices.json</code> با <code>npx wrangler@4</code> (یک بار <code>npx wrangler@4 login</code>).</>}
            {" "}خبر بالاتر اول نشان داده می‌شود. شناسه‌ی هر خبر ثابت است؛ ویرایش آن را دوباره «تازه» نمی‌کند.
          </span>
        </div>
        <div className="row" style={{ marginTop: 12 }}>
          <label>سطل R2</label>
          <input type="text" dir="ltr" value={bucket} onChange={(e) => setBucket(e.target.value)} />
          <button className="ghost" disabled={busy} onClick={() => run(() => call("/notices/settings", "POST", { bucket }))}>ذخیره</button>
        </div>

        <div className="row" style={{ marginTop: 12 }}>
          <label>تنظیمات FTP (میزبان، پورت، کاربر، رمز، مسیر)</label>
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
            <div style={{ minWidth: 140 }}><label>میزبان</label><input type="text" dir="ltr" value={ftp.host} onChange={(e) => setFtp({ ...ftp, host: e.target.value })} /></div>
            <div style={{ minWidth: 70 }}><label>پورت</label><input type="number" value={ftp.port} onChange={(e) => setFtp({ ...ftp, port: Number(e.target.value) || 21 })} /></div>
            <div style={{ minWidth: 120 }}><label>کاربر</label><input type="text" dir="ltr" value={ftp.user} onChange={(e) => setFtp({ ...ftp, user: e.target.value })} /></div>
            <div style={{ minWidth: 120 }}><label>رمز</label><input type="password" value={ftp.password} onChange={(e) => setFtp({ ...ftp, password: e.target.value })} /></div>
            <div style={{ minWidth: 120 }}><label>مسیر ریموت</label><input type="text" dir="ltr" value={ftp.path} onChange={(e) => setFtp({ ...ftp, path: e.target.value || "/" })} /></div>
            <label><input type="checkbox" checked={ftp.secure} onChange={(e) => setFtp({ ...ftp, secure: e.target.checked })} /> FTPS (explicit)</label>
            <button className="ghost" disabled={busy || ftpBusy} onClick={saveFtp}>ذخیره تنظیمات FTP</button>
            <button className="ghost" disabled={busy || ftpBusy || !ftp.host} onClick={testFtp}>
              {ftpBusy ? "در حال اتصال…" : "تست اتصال"}
            </button>
          </div>
          {!ftp.host && <p className="note">برای تست، اول «میزبان» را بنویسید.</p>}
          {ftpState.text && <p className={`note state ${ftpState.kind}`} style={{ marginTop: 8 }}>{ftpState.text}</p>}
        </div>
      </div>
    </>
  );
}




