import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/localization/fa.dart';
import '../assets/asset_config.dart';
import '../platform/native_bridge.dart';
import 'notice_seal.dart';

/// یک خبر از سازنده‌ی پوپو؛ همان شکل هوهو ریاضی.
///
///     {"id": "forest-pack",              // ثابت می‌ماند؛ «دیده شد» با همین نگه داشته می‌شود
///      "title": "صداهای جنگل رسید!",
///      "body": "…",                       // اختیاری
///      "image": "notices/<sha256>.webp",  // اختیاری، نسبی به popo/ روی سرور
///      "imageSha256": "<hex>",            // امضا روی متن است نه تصویر؛ تصویر با این سنجیده می‌شود
///      "link": "https://…",               // اختیاری؛ فقط بعد از دروازه‌ی والدین باز می‌شود
///      "screen": "GAMES",                 // اختیاری: صفحه‌ای در برنامه، یا ANYWHERE
///      "from": 1761000000000,             // اختیاری، میلی‌ثانیه؛ پیش از آن نشان داده نمی‌شود
///      "until": 1763000000000}            // اختیاری؛ بعد از آن هرگز نشان داده نمی‌شود
class Notice {
  const Notice({
    required this.id,
    required this.title,
    this.body = '',
    this.image = '',
    this.imageSha256 = '',
    this.link = '',
    this.screen = '',
    this.from = 0,
    this.until = 0,
  });

  /// مقدار `screen` که یعنی «هر جای برنامه بود، همان‌جا نشانش بده» و نه صفحه‌ای برای باز کردن.
  static const anywhereMarker = 'ANYWHERE';

  final String id;
  final String title;
  final String body;
  final String image;
  final String imageSha256;
  final String link;
  final String screen;
  final int from;
  final int until;

  bool get hasImage => image.isNotEmpty && imageSha256.length == 64;

  /// فقط https؛ هر چیز دیگری (http، intent:، javascript:) نادیده گرفته می‌شود.
  bool get hasLink => link.startsWith('https://');

  /// خبر معمولی تا وقتی کودک به صفحه‌ی خانه برگردد صبر می‌کند — وسط بازی مزاحمش نمی‌شود. این یکی
  /// صبر نمی‌کند: «مسابقه ده دقیقه‌ی دیگر شروع می‌شود» به‌درد کسی که یک ساعت دیگر سر بلند می‌کند نمی‌خورد.
  bool get anywhere => screen == anywhereMarker;

  /// کجا می‌رود، یا خالی وقتی فقط نشانه‌ی «همان‌جا نشان بده» است.
  String get destination => anywhere ? '' : screen;

  /// خبر دیر، خبر نیست: خبری که مهلتش گذشته هرگز نشان داده نمی‌شود.
  bool activeAt(int now) => (from <= 0 || now >= from) && (until <= 0 || now <= until);

  /// خبرهای درست از متن امضاشده؛ خبر بی‌شناسه یا بی‌عنوان کنار گذاشته می‌شود.
  static List<Notice> parseAll(String? json) {
    final out = <Notice>[];
    if (json == null || json.isEmpty) return out;
    try {
      final root = jsonDecode(json);
      final list = root is Map ? root['notices'] : null;
      if (list is! List) return out;
      for (final o in list) {
        if (o is! Map) continue;
        final id = _str(o, 'id');
        final title = _str(o, 'title');
        if (id.isEmpty || title.isEmpty) continue;
        out.add(Notice(
          id: id,
          title: title,
          body: _str(o, 'body'),
          image: _str(o, 'image'),
          imageSha256: _str(o, 'imageSha256').toLowerCase(),
          link: _str(o, 'link'),
          screen: _str(o, 'screen'),
          from: _millis(o, 'from'),
          until: _millis(o, 'until'),
        ));
      }
    } on FormatException {
      // فایل نیمه‌کاره ارزش خراب کردن برنامه‌ی کودک را ندارد.
    }
    return out;
  }
}

String _str(Map m, String k) => m[k] is String ? (m[k] as String).trim() : '';
int _millis(Map m, String k) => m[k] is num ? (m[k] as num).toInt() : 0;

/// «نسخه‌ی تازه آمده». داخل همان فایل امضاشده می‌آید: پیوند دانلود خطرناک‌ترین چیزی است که می‌شود به
/// برنامه گفت، پس همان امضای خبرها آن را هم می‌پوشاند.
class AppUpdate {
  const AppUpdate({required this.version, required this.url, this.note = ''});

  final String version;
  final String url;
  final String note;

  static AppUpdate? parse(String? json) {
    if (json == null) return null;
    try {
      final root = jsonDecode(json);
      final app = root is Map ? root['app'] : null;
      if (app is! Map) return null;
      final version = _str(app, 'version');
      final url = _str(app, 'url');
      if (version.isEmpty || !url.startsWith('https://')) return null;
      return AppUpdate(version: version, url: url, note: _str(app, 'note'));
    } on FormatException {
      return null;
    }
  }

  /// آیا [theirs] از [ours] تازه‌تر است؟ عددی، نه متنی: «1.30.0» بعد از «1.9.0» است.
  static bool newer(String theirs, String ours) {
    int digits(String part) => int.tryParse(RegExp(r'^\d+').stringMatch(part) ?? '') ?? 0;
    final a = theirs.split('.'), b = ours.split('.');
    for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
      final x = i < a.length ? digits(a[i]) : 0;
      final y = i < b.length ? digits(b[i]) : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}

/// خبرها و اعلان‌ها — بدون هیچ سرویس پوشی، همان طرح گوش‌یار و هوهو ریاضی.
///
/// خبر را استودیو روی سرور می‌گذارد (popo/notices.json، امضاشده). برنامه خودش نگاه می‌کند: هر دقیقه
/// وقتی باز است (lib/features/notices/notice_host.dart) و حدود هر ربع ساعت وقتی بسته است (NoticeWork.kt و
/// NoticeAlarm.kt). تازه‌ها یکی‌یکی به نوار اعلان می‌روند و وقتی برنامه باز است، یکی‌یکی به شکل کارت
/// روی صفحه می‌آیند.
///
/// دو قاعده جلوی شلوغی را می‌گیرد، به‌خصوص روی گوشی‌ای که هفته‌ها خاموش بوده:
///  - یکی در هر نوبت، با فاصله: فوری‌ترین (نزدیک‌ترین مهلت) و بعدی نه زودتر از [gap].
///  - خبر دیر، خبر نیست: مهلت گذشته یعنی هرگز نشان داده نمی‌شود.
///
/// چیزی از گوشی فرستاده نمی‌شود. وضعیت با اندروید در همان FlutterSharedPreferences مشترک است؛
/// NoticeCenter.kt کلیدها را با پیشوند «flutter.» می‌خواند.
class NoticesStore extends ChangeNotifier {
  NoticesStore(
    this._prefs, {
    this.seal,
    http.Client? client,
    this.config = const AssetConfig(),
    this.bridge = const NativeBridge(),
    int Function()? clock,
  }) : _client = client ?? http.Client(),
       _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final SharedPreferences _prefs;
  final http.Client _client;
  final int Function() _clock;
  final AssetConfig config;
  final NativeBridge bridge;

  /// null یعنی کلید عمومی ساخته نشده؛ آن‌وقت هیچ خبری پذیرفته نمی‌شود.
  final NoticeSeal? seal;

  static const keyAsset = 'assets/notices/notice-key.pub';

  /// کمترین فاصله میان دو خبر جلوی کودک — میان دو کارت، و جداگانه میان دو اعلان (NoticeCenter.GAP_MS).
  static const gap = Duration(minutes: 1);

  static const onKey = 'popo.notices.on';
  static const seenKey = 'popo.notices.seen';
  static const cacheKey = 'popo.notices.cache';
  static const _checkKey = 'popo.notices.lastCheck';
  static const _resultKey = 'popo.notices.lastResult';
  static const _dialogAtKey = 'popo.notices.lastDialogAt';
  static const _updateDayKey = 'popo.notices.updateAskDay';

  static const _maxBytes = 256 * 1024;
  static const _maxImageBytes = 2 * 1024 * 1024;

  final _images = <String, Future<Uint8List?>>{};
  bool _busy = false;

  /// کلید عمومی همراه برنامه؛ نبودنش خطا نیست، فقط یعنی «خبری نیست».
  static Future<NoticeSeal?> loadSeal(AssetBundle bundle) async {
    try {
      return NoticeSeal.fromPem(await bundle.loadString(keyAsset));
    } catch (_) {
      return null;
    }
  }

  /// آیا این ساخت اصلاً می‌تواند خبر بگیرد؟ (کلید هست و نشانی سرور داده شده.)
  bool get ready => seal != null && config.noticesEnabled;

  /// والدین در «بخش والدین ← اعلان‌ها» خاموشش می‌کنند. پیش‌فرض روشن.
  bool get enabled => _prefs.getBool(onKey) ?? true;

  /// همه‌ی خبرهایی که الان ارزش نشان دادن دارند، از نسخه‌ی تأییدشده‌ی روی گوشی.
  List<Notice> get current {
    if (!ready || !enabled) return const [];
    final now = _clock();
    return Notice.parseAll(_prefs.getString(cacheKey)).where((n) => n.activeAt(now)).toList(growable: false);
  }

  /// چند خبر روی گوشی هست (برای بخش والدین).
  int get countHere => current.length;

  /// همان [current]؛ نام کوتاه برای آزمون‌ها و صفحه‌ها.
  List<Notice> get notices => current;

  /// چند خبر هنوز کنار زده نشده.
  int get unread => unseen.length;

  /// آیا اصلاً خبری برای نشان دادن هست؟
  bool get visible => current.isNotEmpty;

  /// همه‌ی خبرهای فعلی «دیده شد».
  Future<void> markAllSeen() async {
    final ids = current.map((n) => n.id).toSet();
    await _prefs.setString(seenKey, ids.join('\n'));
    notifyListeners();
  }

  /// آنچه کد اندروید (NoticeCenter.kt) در پس‌زمینه نوشته از دیسک خوانده می‌شود؛ shared_preferences
  /// نسخه‌ی خودش را در حافظه نگه می‌دارد و بی این، خبری که با برنامه‌ی بسته رسیده دیده نمی‌شد.
  Future<void> reloadFromDisk() async {
    await _prefs.reload();
    notifyListeners();
  }

  Set<String> _lines(String key) => (_prefs.getString(key) ?? '').split('\n').where((s) => s.isNotEmpty).toSet();

  bool isSeen(Notice n) => _lines(seenKey).contains(n.id);

  /// آن‌هایی که کودک هنوز کنار نزده.
  List<Notice> get unseen {
    final seen = _lines(seenKey);
    return current.where((n) => !seen.contains(n.id)).toList(growable: false);
  }

  /// یک خبر با شناسه‌اش، چه نوبتش باشد چه نه — برای لمس اعلان، که یعنی کودک همین را خواسته.
  Notice? find(String id) {
    if (!ready) return null;
    for (final n in Notice.parseAll(_prefs.getString(cacheKey))) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// فوری‌ترین اول: هر چه مهلت دارد، نزدیک‌ترین مهلت اول؛ بعد بی‌مهلت‌ها. پایدار: برابرها ترتیب فایل
  /// را نگه می‌دارند (استودیو تازه‌ترین را بالا می‌گذارد).
  static List<Notice> byUrgency(Iterable<Notice> list) {
    final items = list.toList();
    final order = <String, int>{for (var i = 0; i < items.length; i++) items[i].id: i};
    int key(Notice n) => n.until > 0 ? n.until : 0x7fffffffffffffff;
    items.sort((a, b) {
      final c = key(a).compareTo(key(b));
      return c != 0 ? c : order[a.id]!.compareTo(order[b.id]!);
    });
    return items;
  }

  /// چقدر مانده تا ساعت شروع ([Notice.from]) نزدیک‌ترین خبری که هنوز دیده نشده، یا null. برنامه‌ی باز با
  /// این خبر را سر همان دقیقه نشان می‌دهد، نه در نگاه بعدی به سرور.
  Duration? nextStartIn() {
    if (!ready || !enabled) return null;
    final now = _clock();
    final seen = _lines(seenKey);
    int? next;
    for (final n in Notice.parseAll(_prefs.getString(cacheKey))) {
      if (n.from <= now || seen.contains(n.id) || (n.until > 0 && n.until < n.from)) continue;
      if (next == null || n.from < next) next = n.from;
    }
    return next == null ? null : Duration(milliseconds: next - now);
  }

  bool _pressing(Notice n, int now) => n.until > 0 && n.until - now <= gap.inMilliseconds;

  /// ساعتی که عقب کشیده شده خبرها را قفل نمی‌کند.
  bool _spaced(int last, int now) => last <= 0 || last > now || now - last >= gap.inMilliseconds;

  /// خبری که همین حالا باید به شکل کارت بیاید، یا null.
  ///
  /// یکی، فوری‌ترین، و بعدی نه زودتر از [gap]. [onHome]: خبر معمولی منتظر صفحه‌ی خانه می‌ماند؛ فقط
  /// «هر جای برنامه» (ANYWHERE) جای دیگر هم می‌آید. خبری که مهلتش در همین فاصله تمام می‌شود صبر نمی‌کند.
  Notice? dueNow({required bool onHome}) {
    if (!ready || !enabled) return null;
    final now = _clock();
    final gapOver = _spaced(_prefs.getInt(_dialogAtKey) ?? 0, now);
    for (final n in byUrgency(unseen)) {
      if (!onHome && !n.anywhere) continue;
      if (gapOver || _pressing(n, now)) return n;
    }
    return null;
  }

  /// نوبت این خبر رسید؛ فاصله تا بعدی از همین حالا شمرده می‌شود.
  Future<void> shown() => _prefs.setInt(_dialogAtKey, _clock());

  /// کودک کنارش زد، دنبالش رفت یا اعلانش را لمس کرد: دیگر نه کارتش می‌آید نه اعلانش.
  /// شناسه‌هایی که دیگر در فایل نیستند همین‌جا دور ریخته می‌شوند.
  Future<void> markSeen(String id) async {
    final all = Notice.parseAll(_prefs.getString(cacheKey)).map((n) => n.id).toSet();
    final seen = _lines(seenKey).where(all.contains).toSet()..add(id);
    await _prefs.setString(seenKey, seen.join('\n'));
    notifyListeners();
  }

  Future<void> setEnabled(bool on) async {
    await _prefs.setBool(onKey, on);
    notifyListeners();
    // «خاموش» باید به بررسی پس‌زمینه هم برسد، وگرنه گوشی برای والدی که خاموشش کرده خبر می‌آورد.
    await schedule();
    if (on) await refresh();
  }

  /// کار پس‌زمینه‌ی اندروید را روشن یا خاموش می‌کند (روی وب و در آزمون‌ها کاری نمی‌کند).
  Future<void> schedule() => bridge.scheduleNotices(ready && enabled ? config.notices.toString() : null);

  /// یک نگاه به سرور. true یعنی چیزی واقعاً عوض شد (نه هر بار که پرسیده شد).
  ///
  /// هر شکستی بی‌صدا یعنی «همان قبلی‌ها»، ولی دلیلش برای بخش والدین نوشته می‌شود ([lastCheck]):
  /// بی آن «خبر گذاشتم و چیزی نیامد» از بیرون جوابی نداشت. [forget]: فایل روی گوشی کنار گذاشته
  /// می‌شود تا هرچه روی سرور است تازه حساب شود («بررسی کن» در بخش والدین).
  Future<bool> refresh({bool forget = false}) async {
    if (!ready || !enabled || _busy) return false;
    _busy = true;
    try {
      if (forget) await _prefs.remove(cacheKey);
      // پرسش یکتا: هیچ میانجی (هاست، پراکسی اپراتور) نسخه‌ی کهنه‌ی فایل را تحویل نمی‌دهد.
      final address = config.notices.replace(queryParameters: {'t': '${_clock()}'});
      final res = await _client.get(address).timeout(const Duration(seconds: 20));
      if (res.statusCode == 404) return await _store('{"notices":[]}', 'هنوز خبری روی سرور نیست');
      if (res.statusCode != 200) return await _note('فایل خبرها از سرور نیامد (HTTP ${res.statusCode})');
      if (res.bodyBytes.length > _maxBytes) return await _note('فایل خبرها بیش از اندازه بزرگ است');
      // امضا روی همان بایت‌هایی آزموده می‌شود که رسیده‌اند، نه روی JSON دوباره ساخته‌شده.
      final bytes = seal!.unseal(utf8.decode(res.bodyBytes, allowMalformed: true));
      if (bytes == null) return await _note('امضا با فایل نمی‌خواند — یا فایل دستی عوض شده، یا با کلید دیگری امضا شده');
      final body = utf8.decode(bytes, allowMalformed: true);
      final root = _tryJson(body);
      if (root is! Map || root['notices'] is! List) return await _note('آنچه آمد فایل خبرها نبود');
      return await _store(body, null);
    } on TimeoutException {
      return await _note('سرور جواب نداد');
    } catch (e) {
      debugPrint('notices: $e');
      return await _note('به سرور وصل نشد');
    } finally {
      _busy = false;
    }
  }

  static Object? _tryJson(String s) {
    try {
      return jsonDecode(s);
    } on FormatException {
      return null;
    }
  }

  Future<bool> _note(String what) async {
    await _prefs.setInt(_checkKey, _clock());
    await _prefs.setString(_resultKey, what);
    notifyListeners();
    return false;
  }

  Future<bool> _store(String body, String? emptyNote) async {
    final count = Notice.parseAll(body).length;
    if (_prefs.getString(cacheKey) == body) {
      await _note(emptyNote ?? 'چیز تازه‌ای نبود (${faDigits(count)} خبر، همان‌ها)');
      return false;
    }
    await _prefs.setString(cacheKey, body);
    _images.clear();
    await _note(emptyNote ?? '${faDigits(count)} خبر گرفته شد');
    return true;
  }

  /// «۳ دقیقه پیش — ۱ خبر گرفته شد»، یا خالی پیش از اولین نگاه. همان را NoticeCenter.kt هم می‌نویسد.
  String get lastCheck {
    final at = _prefs.getInt(_checkKey) ?? 0;
    final what = _prefs.getString(_resultKey) ?? '';
    if (at == 0 || what.isEmpty) return '';
    final ago = (_clock() - at).clamp(0, 1 << 62) ~/ 60000;
    final when = ago < 1
        ? 'همین الان'
        : ago < 60
        ? '${faDigits(ago)} دقیقه پیش'
        : ago < 60 * 24
        ? '${faDigits(ago ~/ 60)} ساعت پیش'
        : '${faDigits(ago ~/ (60 * 24))} روز پیش';
    return '$when — $what';
  }

  /// نسخه‌ی تازه‌تر از [ours] که در فایل امضاشده اعلام شده، یا null.
  AppUpdate? updateWaiting(String ours) {
    if (!ready || ours.isEmpty) return null;
    final u = AppUpdate.parse(_prefs.getString(cacheKey));
    return u != null && AppUpdate.newer(u.version, ours) ? u : null;
  }

  int get _today => _clock() ~/ Duration.millisecondsPerDay;

  /// «نسخه‌ی تازه آمده» حداکثر یک بار در روز، مثل هوهو ریاضی.
  bool updateDue(String ours) => updateWaiting(ours) != null && _prefs.getInt(_updateDayKey) != _today;

  Future<void> askedAboutUpdate() => _prefs.setInt(_updateDayKey, _today);

  /// تصویر خبر، فقط اگر درهم‌سازی‌اش با آنچه در متن امضاشده آمده بخواند.
  Future<Uint8List?> image(Notice n) {
    if (!n.hasImage || !ready || n.image.contains('..') || n.image.contains('://')) return Future.value();
    return _images.putIfAbsent(n.imageSha256, () async {
      try {
        final res = await _client.get(config.noticeFile(n.image)).timeout(const Duration(seconds: 30));
        if (res.statusCode != 200 || res.bodyBytes.length > _maxImageBytes) return null;
        return sha256.convert(res.bodyBytes).toString() == n.imageSha256 ? res.bodyBytes : null;
      } catch (_) {
        return null;
      }
    });
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
