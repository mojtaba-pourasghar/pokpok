# صداهای پوپو

| چه | چطور ساخته می‌شود | کجا |
|---|---|---|
| صداهای رابط، سازها (پیانو، زایلوفون، زنگوله، درام، شیکر)، ماشین‌ها، آشپزخانه، آب، باغ، ساخت‌وساز، دو موسیقی پس‌زمینه | با کد: `python3 tools/sfx/synth.py` (numpy + ffmpeg). اصلی و بدون مجوز بیرونی. | `assets/audio/{ui,sfx,instruments,music}` |
| حیوان‌ها، صدای محیط هر فصل (آشپزخانه، مزرعه، کارگاه، آتلیه، شب، صحنه، شهر، جشن)، باد و باران، زنگ در، ساعت، کتری، شیر آب، گیتار، فلوت، ویولن | ضبط واقعی از Wikimedia Commons: `python3 tools/sfx/fetch_sounds.py` (انتخاب‌ها در `picks.json`) | `assets/audio/{animals,ambient,sfx,instruments}` + منبع و مجوز در `docs/audio/sfx_sources.json` |
| صدای گوینده (پوپو) | `tools/voice-studio` (موقت با آواشو) یا ضبط استودیو + `tools/voice/import_recordings.sh` | `assets/audio/voice` |

- `python3 tools/sfx/synth.py pop boing` فقط همین دو را دوباره می‌سازد.
- پس از هر تغییر: `python3 tools/build_manifest.py` (فهرست و sha256) و `flutter test`.
- جایگزینی دستی یک صدا با فایل بهتر: تب «صدای حیوان‌ها و وسایل» در استودیوی صداگذاری؛ فایل را پاک‌سازی و
  هم‌بلند می‌کند، روی همان مسیر می‌نویسد و منبع/مجوز را ثبت می‌کند.
- Freesound برای دانلود خودکار کلید API می‌خواهد و به درخواست اسکریپتی ۴۰۳ می‌دهد؛ برای همین Commons استفاده
  شده است. اگر از Freesound فایل گرفتید، از تب استودیو با لینک و مجوزش وارد کنید.
