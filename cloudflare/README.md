# Cloudflare: ذخیره و توزیع دارایی‌های پوپو

Cloudflare فقط **نگه‌داری و رساندن فایل‌ها** (تصویر، صدا، صدای گوینده، بسته‌های محتوا) را بر عهده دارد.
رابط کاربری، تعامل‌ها، مسیرها و منطق برنامه همه در Flutter است و برنامه بدون هیچ درخواست
شبکه‌ای کامل کار می‌کند.

> **وضعیت (صادقانه):** کد Worker، پیکربندی، CORS و اسکریپت‌های ساخت و بارگذاری آماده‌اند و با
> `wrangler dev` (شبیه‌ساز محلی R2) آزمایش شده‌اند. **هیچ حساب Cloudflare به این پروژه وصل نشده و
> هیچ bucket، Worker یا دامنه‌ای روی Cloudflare واقعی ساخته نشده است.** مراحل زیر را صاحب حساب
> باید انجام دهد.

## معماری

```
برنامه‌ی Flutter (بدون هیچ کلید یا توکن)
  │  GET https://<دامنه>/popo/v1/packs.json                  ← فهرست نسخه‌دار بسته‌ها (کش ۵ دقیقه)
  │  GET https://<دامنه>/popo/v1/art/animals/cow.webp         ← فایل‌ها (کش یک‌ساله، immutable)
  │  GET …/audio/voice/app_splash_welcome.mp3  (Range برای ادامه‌ی دانلود)
  ▼
Cloudflare Worker «popo-assets»  — فقط GET/HEAD، CORS، کش لبه، Range ← 206، ETag ← 304
  ▼
R2 bucket «popo-assets» (خصوصی؛ تنها راه دسترسی همین Worker است)
  popo/<version>/…          محتوای عمومی
  popo-private/<version>/…  محتوای دارای مجوز/خصوصی؛ فقط با نشانی امضاشده (اختیاری)
```

| بخش | کجا |
|---|---|
| تنظیم نشانی CDN در برنامه | `lib/core/assets/asset_config.dart` (`--dart-define=POPO_CDN_BASE=…`) |
| ترتیب جست‌وجوی فایل (دانلودی ← داخلی) | `lib/core/assets/asset_resolver.dart` |
| دانلود، sha256، مکث/ادامه با Range، خطای حافظه | `lib/core/assets/download_manager.dart` |
| Worker | `cloudflare/worker/src/index.js`، `cloudflare/worker/wrangler.toml` |
| CORS برای R2 | `cloudflare/r2-cors.json` |
| ساخت بسته‌ها و packs.json | `cloudflare/scripts/build_packs.py` |
| بارگذاری | `cloudflare/scripts/upload.sh` |

### قاعده‌ها

- **نسخه‌بندی:** همه‌ی مسیرها زیر `popo/<نسخه>/` هستند. فایل منتشرشده هرگز عوض نمی‌شود؛ برای تغییر،
  نسخه‌ی تازه (`v2`) بسازید و برنامه را با `POPO_ASSET_VERSION=v2` بسازید. به همین دلیل کش یک‌ساله امن است.
  `packs.json` کوتاه‌عمر است و فیلد `minApp` بسته‌هایی را که برنامه‌ی قدیمی نمی‌فهمد کنار می‌گذارد.
- **ساختار پوشه‌ها** همان مسیرهای منطقی برنامه است (`art/<group>/<id>.webp`، `audio/voice/…`)، پس فایل
  دانلودی خودبه‌خود جای فایل داخلی را می‌گیرد؛ تصویر WebP با همان شناسه جای طرح برداری را می‌گیرد.
- **بدون اینترنت:** همه‌ی جهان‌ها، تصویرهای برداری، صداها و موسیقی داخل بسته‌ی نصبی‌اند. بسته‌ها اختیاری‌اند،
  روی دستگاه می‌مانند و بدون اینترنت کار می‌کنند؛ فهرست بسته‌ها هم روی دستگاه ذخیره می‌شود.
- **امنیت:** برنامه هیچ کلید R2 یا توکن API ندارد و نباید داشته باشد. bucket عمومی نمی‌شود (R2 به‌طور
  پیش‌فرض خصوصی است، ولی این را با «Public access: Disabled» در داشبورد بررسی کنید). Worker فقط
  پیشوندهای `popo/` و `popo-private/` را سرو می‌کند و `..` را رد می‌کند. برنامه هر فایل را با sha256
  فهرست بررسی می‌کند.
- **محتوای خصوصی/دارای مجوز:** زیر `popo-private/` فقط با نشانی امضاشده (`?exp=…&sig=…`، HMAC-SHA256 با
  راز `SIGNING_KEY` در Worker). کلید هرگز در برنامه نیست؛ نشانی باید از سروری که شما کنترل می‌کنید صادر شود
  (چنین سروری در این پروژه نیست). همه‌ی محتوای فعلی عمومی و رایگان است و به امضا نیازی ندارد.
- **حریم خصوصی کودک:** Worker هیچ کوکی یا شناسه‌ای نمی‌گذارد و برنامه هیچ داده‌ای از کودک نمی‌فرستد؛ تنها
  درخواست‌ها GET فایل‌های عمومی‌اند. Analytics/Logpush را برای این دامنه روشن نکنید مگر با سیاست روشن.

## راه‌اندازی (یک بار، با حساب خودتان)

```bash
cd cloudflare/worker
npx wrangler@4 login                                   # اعتبارنامه فقط روی سیستم شما می‌ماند
npx wrangler@4 r2 bucket create popo-assets
npx wrangler@4 r2 bucket cors set popo-assets --file ../r2-cors.json
# دامنه را در wrangler.toml (routes) تنظیم کنید؛ دامنه باید روی همین حساب Cloudflare باشد. بعد:
npx wrangler@4 deploy
# فقط اگر محتوای خصوصی دارید:
npx wrangler@4 secret put SIGNING_KEY
```

دامنه‌ی سفارشی (مثلاً `assets.example.com`) به‌جای `*.workers.dev` توصیه می‌شود: کش لبه و قواعد
Cache Rules روی آن کار می‌کند و در صورت لزوم جابه‌جایی بی‌دردسر است.

## انتشار محتوا

```bash
python3 tools/art/build_art.py                         # طرح‌های برداری + asset_manifest.json
python3 tools/sfx/synth.py                             # صداهای عمومی
python3 cloudflare/scripts/build_packs.py --version v1 \
    --voice-dir /path/to/recorded/voice  \              # صدای ضبط‌شده‌ی گوینده (اختیاری)
    --art-dir /path/to/final/webp                       # تصویرسازی نهایی با نام شناسه‌ها (اختیاری)
cloudflare/scripts/upload.sh v1                        # packs.json آخر از همه بارگذاری می‌شود
```

## ساخت برنامه با CDN

```bash
flutter build apk --release \
  --dart-define=POPO_CDN_BASE=https://assets.example.com \
  --dart-define=POPO_ASSET_VERSION=v1
```

بدون `POPO_CDN_BASE`، صفحه‌ی «دانلود محتوا» در پنل والدین می‌گوید سرور تنظیم نشده و برنامه فقط با
دارایی‌های داخلی کار می‌کند.

## آزمایش محلی (بدون حساب)

```bash
python3 cloudflare/scripts/build_packs.py --version v1
cd cloudflare/dist
for k in popo/v1/packs.json popo/v1/audio/music/menu_loop.mp3; do
  npx wrangler@4 r2 object put "popo-assets/$k" --file "$k" --local \
     --config ../worker/wrangler.toml --persist-to ../worker/.wrangler/state
done
cd ../worker && npx wrangler@4 dev --persist-to .wrangler/state
curl -i http://127.0.0.1:8787/popo/v1/packs.json
```

آنچه در این نشست محلی بررسی شد: ۲۰۰ و بایت‌های یکسان با فایل منبع، `Cache-Control` کوتاه برای
packs.json و یک‌ساله برای فایل‌ها، Range ← ۲۰۶، ETag ← ۳۰۴، ۴۰۴ بیرون از پیشوند، برای `..` و برای
مسیر خصوصی بدون امضا، ۴۰۵ برای POST. منطق دانلود برنامه (sha256، ادامه با Range، خطای checksum،
فهرست آفلاین) در `test/download_manager_test.dart` با یک سرور HTTP محلی آزمون می‌شود.
