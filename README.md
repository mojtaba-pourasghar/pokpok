# پوپو — ببین، لمس کن، کشف کن! (Flutter)

دنیای بازی، کشف و خلاقیت برای کودکان ۲ تا ۸ سال، با رابط فارسی و راست‌چین. پوپو، روباه دختر
کوچولو با پاپیون صورتی، کودک را در شش جهان مصور همراهی می‌کند: **خانه‌ی من، شهر بازی، طبیعت و حیوانات،
هنر و نقاشی، استودیوی موسیقی، کارگاه ساخت‌وساز**.

![صفحه‌های پوپو](docs/screenshots/overview.jpg)

*تصویرها از نسخه‌ی وب همین کد در Chromium گرفته شده‌اند (۴۱۲×۹۱۵). نمای تبلت افقی:
[docs/screenshots/tablet.jpg](docs/screenshots/tablet.jpg)*

این پروژه از الگوی [goshyar_game](https://github.com/mojtaba-pourasghar/goshyar_game) پیروی می‌کند
(سیستم طراحی، لایه‌ی دارایی‌ها و CDN، جمله‌های گوینده در JSON، استودیوی صداگذاری، Cloudflare R2) و
نام، نشان، شخصیت و تصویرهایش همه اصلی‌اند؛ هیچ دارایی‌ای از Pok Pok یا برند دیگری استفاده نشده است.

## اجرا

نیازمندی‌ها: Flutter 3.47 یا بالاتر (Dart 3.13)، برای اندروید Android SDK و JDK 17، برای iOS Xcode.

```bash
flutter pub get
flutter run                     # گوشی یا شبیه‌ساز
flutter run -d chrome           # پیش‌نمایش سریع در مرورگر
```

## ساخت خروجی

```bash
flutter build apk --release                 # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release           # Google Play / کافه‌بازار / مایکت
flutter build ios --release                 # روی macOS
flutter build web --release

# با سرور دارایی‌های Cloudflare (اختیاری؛ cloudflare/README.md)
flutter build apk --release \
  --dart-define=POPO_CDN_BASE=https://assets.example.com \
  --dart-define=POPO_ASSET_VERSION=v1
```

**امضا:** `android/key.properties.example` را به `android/key.properties` کپی و پر کنید. بدون آن، نسخه‌ی
release با کلید debug امضا می‌شود که فقط برای آزمایش است. شناسه‌ی بسته: `com.pokpok.ir`.

## آزمون‌ها

```bash
flutter analyze
flutter test                                   # ۱۲۲ آزمون، بدون دستگاه
flutter test integration_test -d <device>      # همان جریان روی دستگاه واقعی
```

| فایل | چه چیزی |
|---|---|
| `test/scene_controller_test.dart` | موتور تعامل: لمس، روشن/خاموش، کشیدن آزاد و روی جاده، رها کردن، ترکیب‌ها (پنهان/برگشت/ماندن/رشد)، اهداف، ذخیره، از نو |
| `test/storage_test.dart` | ماندن داده پس از بستن و باز کردن، انتقال طرح‌واره ۱←۲، داده‌ی خراب، حذف نمایه |
| `test/download_manager_test.dart` | با یک CDN محلی: دانلود و sha256، خطای checksum، ادامه با Range، مکث/ادامه، فهرست آفلاین، `minApp`، نسخه‌ی تازه |
| `test/content_integrity_test.dart` | هر ارجاع JSON (تصویر، صدا، جمله، برچسب، مسیر) واقعی است؛ checksum فهرست دارایی‌ها؛ منبع و مجوز صداهای واقعی |
| `test/routes_smoke_test.dart` | ۲۴ مسیر × ۳ اندازه (۳۲۰×۶۴۰، ۴۱۲×۹۱۵، تبلت افقی): بدون خطا، بدون سرریز، و **هر کنترل دیده‌شده واقعاً لمس‌پذیر** |
| `test/app_flow_test.dart` | شروع ← معرفی ← نقشه، ورود به جهان، تعامل و ماندن آن پس از «بستن» برنامه، نقش‌آفرینی تا برچسب، نقاشی/برگرداندن/ذخیره، دروازه‌ی والدین، تنظیمات صدا، جدایی نمایه‌ها، متن درشت و حرکت کمتر، زیرنویس |
| `test/puzzle_logic_test.dart` | دشواری بر اساس سن، الگو، حافظه، دروازه |

## ساختار

```
lib/
  main.dart                    راه‌اندازی Hive، محتوا، دارایی‌ها، صدا
  app/                         app.dart، router.dart (GoRouter + مسیرهای محافظت‌شده)، providers.dart (Riverpod)،
                               theme/ (نشانه‌های رنگ، فاصله، شعاع، سایه، حرکت، تایپوگرافی)، localization/
  core/
    assets/                    AssetConfig (CDN)، AssetResolver، DownloadManager، StorageInfo
    audio/                     PopoAudio (چهار کانال جدا)، JustAudioService، SilentAudio برای آزمون
    content/                   مدل محتوا و بارگذاری JSONها (جهان، صحنه، شیء، واکنش، هدف، جمله)
    storage/local_store.dart   Hive + نسخه‌ی طرح‌واره و انتقال داده
    widgets/                   سیستم طراحی: دکمه، کاشی، کارت، نوار پیشرفت، حالت‌ها، حباب زیرنویس، نشان
    billing/                   پرداخت کافه‌بازار (Billing، AccessStore: چه چیزی رایگان است)
    notices/                   خبرهای امضاشده (NoticeSeal، NoticesStore)
    platform/                  NativeBridge (کانال com.pokpok.ir/native)
    narrator.dart
  data/                        مدل‌ها (نمایه، تنظیمات، پیشرفت، نقاشی، آهنگ، ساخته) و مخزن‌ها
  features/
    mascot/                    پوپو: نقاش با ۸ حالت + پلک، نفس، دست تکان دادن
    worlds/engine/             موتور تعامل (SceneController) و صحنه (SceneStage)
    worlds/backgrounds/        پس‌زمینه‌های مصور هم‌تراز با مختصات اشیا
    onboarding/ map/ worlds/ role_play/ art_studio/ music_studio/ construction/ puzzles/
    activity_library/ progress/ profiles/ settings/ parental_dashboard/ downloads/
assets/
  content/                     worlds.json، scenes/*.json، activities.json، voice_lines.json، asset_manifest.json
  art/<group>/<id>.svg         ۸۹ طرح برداری اصلی (tools/art/build_art.py)
  audio/                       ui، sfx، animals، ambient، instruments، music، voice
  fonts/                       Vazirmatn (OFL)
tools/
  art/build_art.py             ساخت طرح‌ها با یک سبک یکدست
  build_manifest.py            فهرست دارایی‌ها با sha256
  content/build_content.py     نوشتن JSON صحنه‌ها و فعالیت‌ها (اختیاری؛ JSON را مستقیم هم می‌شود ویرایش کرد)
  sfx/synth.py                 صداهای عمومی (ساخته با کد)
  sfx/fetch_sounds.py          صداهای واقعی از Wikimedia Commons با مجوز
  voice-studio/                استودیوی صداگذاری گوینده
  voice/                       فیلم‌نامه‌ی ضبط و ورود صدای ضبط‌شده
cloudflare/                    Worker، پیکربندی R2، ساخت و بارگذاری بسته‌ها
docs/                          ASSETS.md (مشخصات شخصیت و دارایی‌ها)، STATUS.md (وضعیت و کارهای باقی)
integration_test/              آزمون روی دستگاه
```

## افزودن محتوا بدون تغییر کد

- **صحنه یا جهان تازه:** یک فایل در `assets/content/scenes/` و نامش در `worlds.json` (`sceneFiles`). هر شیء
  شناسه، تصویر، جای نسبی، اندازه، ناحیه‌ی لمس، نوع کشیدن (`free` یا `path:<مسیر>`)، واکنش لمس (حرکت،
  صدا، روشن/خاموش، مرحله‌ی بعد، جمله)، واکنش رها شدن چیزی رویش (`accepts`)، و ذخیره شدن یا نشدن دارد.
  پس‌زمینه یکی از شناسه‌های `SceneBackgroundPainter.ids` است. سپس `flutter test`؛ آزمون سلامت محتوا ارجاع
  شکسته را پیدا می‌کند. راهنمای کامل: [docs/ASSETS.md](docs/ASSETS.md).
- **تصویر تازه:** تابعی در `tools/art/build_art.py` و `python3 tools/art/build_art.py`.
- **تصویرسازی نهایی (رستری):** فایل WebP با همان شناسه (مثلاً `cow.webp`) از راه بسته‌ی CDN جای طرح برداری را
  می‌گیرد؛ کد عوض نمی‌شود.
- **جمله‌ی گوینده:** `assets/content/voice_lines.json`، بعد `python3 tools/voice/make_recording_script.py`.

## تصویرها با Cloudflare (level 3)

همه‌ی تصویرها (۸ حالت پوپو، پس‌زمینه‌ی همه‌ی صحنه‌ها، کارت جهان‌ها و ۸۹ شیء) یک prompt با سبک
یکسان در `art/art_manifest.json` دارند (`tools/art/prompts.py`). با Cloudflare Workers AI
(flux-1-schnell، همان مهارت `.claude/skills/level-3-image-generator`) ساخته می‌شوند:

```bash
cp .env.example .env          # CF_ACCOUNT_ID (۳۲ نویسه) و CF_API_TOKEN
python3 tools/art/generate_cf.py                     # همه‌ی تصویرهای کم
python3 tools/art/generate_cf.py --kind character    # فقط پوپو
```

پس‌زمینه‌ی سفید اشیا و پوپو خودکار برداشته می‌شود و WebP در `assets/art/...` قرار می‌گیرد؛ برنامه هر
تصویر رستری را به‌جای طرح برداری هم‌نام نشان می‌دهد (پوپو، پس‌زمینه‌ها، کارت‌ها، اشیا) بدون تغییر کد.

## صدا

- **صداهای عمومی** (رابط، سازها، ماشین‌ها، آشپزخانه، آب، ساخت‌وساز، دو موسیقی پس‌زمینه): همه با کد ساخته
  شده‌اند (`tools/sfx/synth.py`، numpy + ffmpeg) و اصلی‌اند.
- **صدای واقعی** حیوان‌ها، آب، زنگ در، ساعت، کتری، گیتار/فلوت/ویولن: ضبط‌های Wikimedia Commons (همان
  انتخاب‌های goshyar_game) با منبع، مجوز و پدیدآورنده در `docs/audio/sfx_sources.json`. برای مجوزهای
  CC BY / CC BY-SA ذکر نام پدیدآورنده در صفحه‌ی «درباره» یا فروشگاه لازم است.
- **صدای گوینده (پوپو):** ۶۸ جمله در `voice_lines.json`؛ با **استودیوی صداگذاری** `tools/voice-studio`
  (ویندوز: `start.bat`، بقیه: `npm install && npm start`، راهنما: [tools/voice-studio/README.md](tools/voice-studio/README.md))
  صدای موقت با آواشو ساخته می‌شود و ضبط انسانی با `tools/voice/import_recordings.sh` وارد می‌شود.
  تا آن زمان حرف‌های پوپو در حباب زیرنویس نوشته می‌شود و بازی بی‌وقفه کار می‌کند.
- چهار کانال جدا با بلندی و کلید جدا برای هر کودک: موسیقی، جلوه‌ها، صدای محیط، گوینده.

## نسخه‌ی کامل (کافه‌بازار) و خبرها

- **پرداخت:** در release، صحنه‌ی اول هر جهان و بازی اول هر دسته‌ی «همه‌ی بازی‌ها» رایگان است و بقیه با یک بار خرید
  «نسخه‌ی کامل» از کافه‌بازار (Poolakey، SKU `popo_full`) باز می‌شوند؛ خرید پشت دروازه‌ی والدین است. در debug
  همه‌چیز باز است. «پنل والدین ← خریدها و بازی‌های دیگر» وضعیت، بازیابی خرید و بازی‌های دیگر ما را دارد.
- **خبرها و اعلان‌ها:** بی هیچ سرویس پوش؛ استودیو خبر را امضا و با FTP روی `mp-apdl.ir/popo/notices.json`
  می‌گذارد و برنامه (باز هر دقیقه، بسته حدود هر ربع ساعت) آن را می‌خواند، امضا را می‌سنجد و خبر را در نوار
  اعلان و روی نقشه (زنگوله) نشان می‌دهد. خاموش کردن در «پنل والدین ← اعلان‌ها و خبرها».
- راهنمای ساخت release، پنل بازار، کلید RSA و کلید خبرها: [docs/RELEASE.md](docs/RELEASE.md).

## حریم خصوصی و والدین

بدون تبلیغ، بدون ردیاب، بدون حساب کاربری، بدون گفت‌وگو یا نمایه‌ی عمومی. همه‌ی داده‌ها فقط روی دستگاه‌اند.
تنظیمات، نمایه‌ها، تاریخچه، دانلودها، خریدها، خروجی گرفتن از نقاشی و پاک کردن داده‌ها پشت **دروازه‌ی والدین**
(سه عدد به حروف) هستند. این توصیف فنی است، نه تأیید حقوقی؛ پیش از انتشار بررسی حقوقی لازم است.

## وضعیت (صادقانه)

خلاصه در [docs/STATUS.md](docs/STATUS.md). مهم‌ترین‌ها:

- **تصویرها** طرح‌های برداری اصلی و یکدست‌اند (نه رندر سه‌بعدی). مسیر جایگزینی با تصویرسازی نهایی آماده است.
- **صدای گوینده** هنوز ضبط/ساخته نشده؛ استودیو و فیلم‌نامه آماده‌اند.
- **Cloudflare:** کد و پیکربندی آماده و محلی آزمایش شده؛ هیچ منبعی روی حساب واقعی ساخته نشده.
- **ساخت اندروید/iOS در این نشست اجرا نشد** (Android SDK در دسترس نبود و `dl.google.com` در شبکه‌ی این محیط
  بسته بود؛ macOS هم نبود). نسخه‌ی وب ساخته و در Chromium بررسی شد و همه‌ی آزمون‌ها سبزند.
