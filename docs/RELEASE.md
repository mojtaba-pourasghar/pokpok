# ساخت نسخه‌ی release، پرداخت کافه‌بازار و خبرها

همان روش گوش‌یار (`goshyar_game/docs/RELEASE.md`)، برای پوپو (`com.pokpok.ir`).

## debug و release چه فرقی دارند

| | debug (Run در Android Studio، `flutter run`) | release (برای بازار) |
|---|---|---|
| محتوا | **همه باز**، بی‌خرید | در هر جهان **فقط صحنه‌ی اول** و در هر دسته‌ی «همه‌ی بازی‌ها» **فقط بازی اول** رایگان؛ بقیه با «نسخه‌ی کامل» |
| پرداخت | لازم نیست | کافه‌بازار (Poolakey، `BazaarBilling.kt`) |
| امضا | کلید debug | کلید release شما |

قفل در `lib/core/billing/access_store.dart` (`needsPurchase`) است؛ جهان‌ها (`world_screen.dart`) و کتابخانه
(`library_screen.dart`) آن را می‌پرسند. هنر، موسیقی و ساخت‌وساز همیشه رایگان‌اند.

## ۱. یک بار: کلید امضا و `android/key.properties`
```powershell
keytool -genkey -v -keystore C:\MyData\Keys\pokpok-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pokpok
```
`android/key.properties.example` را به `android/key.properties` کپی و پر کنید (مسیر با `/`). از فایل `.jks` و رمزها
پشتیبان بگیرید؛ گم شدنش یعنی دیگر نمی‌شود روی همین برنامه در بازار نسخه‌ی تازه داد.

## ۲. یک بار: پنل کافه‌بازار و `android/services.properties`
1. در [پیشخان کافه‌بازار](https://pishkhan.cafebazaar.ir) برنامه‌ی `com.pokpok.ir` را بسازید.
2. **پرداخت درون‌برنامه‌ای** ← محصول تازه: نوع **مصرف‌نشدنی**، شناسه (SKU) **`popo_full`**، قیمت دلخواه.
   (شناسه‌ی دیگر: `--dart-define=BAZAAR_SKU=…`.)
3. **کلید RSA** همان بخش را کپی کنید و `android/services.properties.example` را به
   `android/services.properties` کپی کنید: `bazaar.rsa=…` (در گیت نیست).

قیمت نمایشی از خود بازار خوانده می‌شود؛ اگر نشد `AccessStore.fallbackPrice` نشان داده می‌شود.

## ۳. هر بار: ساخت
```powershell
flutter build apk --release        # build\app\outputs\flutter-apk\app-release.apk
flutter build appbundle --release
```
پیش از هر انتشار `version` در `pubspec.yaml` را بالا ببرید (عدد بعد از `+` هر بار بیشتر). برای خرید آزمایشی،
حساب بازار خود را در پیشخان «آزمایش‌کننده» کنید و `flutter run --release` بزنید.

## خبرها و اعلان‌ها (بدون سرویس پوش)
- **یک بار:** استودیو (`tools/voice-studio`) ← تب «خبرها و اعلان‌ها» ← «ساخت کلید امضا». فایل
  `assets/notices/notice-key.pub` را **کامیت کنید**. نیمه‌ی خصوصی فقط در
  `tools/voice-studio/voice-studio.config.json` است (در گیت نیست)؛ از آن پشتیبان امن بگیرید.
  بی این فایل، زنگوله و گزینه‌ی خبرها اصلاً دیده نمی‌شوند.
- **نشانی:** خبرها از `https://mp-apdl.ir/popo/notices.json` خوانده می‌شوند (پیش‌فرض؛ با
  `--dart-define=POPO_NOTICES_BASE=…` عوض می‌شود، خالی یعنی بی‌خبر).
- **انتشار:** تب خبرها ← تنظیمات FTP (میزبان `ftp.mp-apdl.ir`، مسیر `/public_html/popo`) ← «تست اتصال» ←
  «ذخیره». خبر را بنویسید ← «امضا و انتشار»: اول عکس‌ها (`notices/<sha>.webp`)، آخر `notices.json`. بی میزبان
  FTP، به R2 (`popo-assets/popo/notices.json` با `npx wrangler@4`) می‌رود.
- **رفتار برنامه:** باز، هر دقیقه؛ بسته، حدود هر ربع ساعت (`NoticeWork.kt` و `NoticeAlarm.kt`). یک خبر در هر
  نوبت؛ خبر معمولی منتظر نقشه می‌ماند، «⚡ هر جای برنامه» نه. اجازه‌ی اعلان فقط وقتی خبری هست پرسیده می‌شود.
- **حریم خصوصی:** چیزی از گوشی فرستاده نمی‌شود؛ پیوند خبر فقط بعد از دروازه‌ی والدین باز می‌شود؛ والدین در
  «پنل والدین ← اعلان‌ها و خبرها» خاموشش می‌کنند.

## صادقانه: چه آزموده شده و چه نه
- کد Dart (قفل، برگه‌ی خرید، امضای خبرها، صف خبرها) با `flutter test` آزموده می‌شود.
- کد Kotlin پرداخت و اعلان از گوش‌یار آمده و فقط نام بسته و کلیدهایش عوض شده؛ **اولین ساخت اندروید و خرید
  واقعی باید روی دستگاه امتحان شود**.
