import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

/// ذخیره‌سازی محلی و آفلاین با Hive.
///
/// هر مقدار به‌صورت JSON در یک «جعبه»ی رشته‌ای نگه داشته می‌شود؛ پس نیازی به
/// کدسازی آداپتر نیست و هر مدل با toJson/fromJson خودش خوانده می‌شود.
///
/// جعبه‌ها:
///   meta      نسخه‌ی طرح‌واره، نمایه‌ی فعال
///   profiles  نمایه‌ی کودکان (کلید = شناسه‌ی نمایه)
///   settings  تنظیمات هر نمایه
///   progress  پیشرفت هر نمایه
///   scenes    وضعیت اشیای صحنه‌ها   (کلید = profile/scene)
///   artworks  نقاشی‌ها              (کلید = profile/artwork)
///   songs     آهنگ‌ها               (کلید = profile/song)
///   builds    ساخته‌های کارگاه       (کلید = profile)
///   content   فهرست بسته‌ها و نسخه‌ی دارایی‌ها
///   game      پیشرفت بازی هر نمایه: ستاره، سکه، کوله‌پشتی، ابزارها (کلید = نمایه)
class LocalStore {
  LocalStore._(this._boxes);

  /// نسخه‌ی فعلی طرح‌واره‌ی داده. هر تغییر ناسازگار یک گام در [migrations] لازم دارد.
  static const schemaVersion = 2;

  static const boxNames = ['meta', 'profiles', 'settings', 'progress', 'scenes', 'artworks', 'songs', 'builds', 'content', 'game'];

  final Map<String, Box<String>> _boxes;

  /// باز کردن همه‌ی جعبه‌ها. در برنامه Hive.initFlutter پیش از این صدا زده شده است.
  /// [inMemory] جعبه‌ها را بدون دیسک می‌سازد (برای آزمون‌ها)؛ [prefix] نام جعبه‌ها را جدا می‌کند.
  static Future<LocalStore> open({String? path, bool inMemory = false, String prefix = 'popo'}) async {
    if (path != null) Hive.init(path);
    final boxes = <String, Box<String>>{};
    for (final name in boxNames) {
      boxes[name] = await Hive.openBox<String>('${prefix}_$name', bytes: inMemory ? Uint8List(0) : null);
    }
    final store = LocalStore._(boxes);
    await store.migrate();
    return store;
  }

  Box<String> box(String name) => _boxes[name]!;

  Map<String, dynamic>? readJson(String boxName, String key) {
    final raw = box(boxName).get(key);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (e) {
      // داده‌ی خراب نباید برنامه را از کار بیندازد؛ مقدار پیش‌فرض جایگزین می‌شود.
      debugPrint('داده‌ی خراب در $boxName/$key نادیده گرفته شد: $e');
      return null;
    }
  }

  Future<void> writeJson(String boxName, String key, Map<String, Object?> value) => box(boxName).put(key, jsonEncode(value));

  Future<void> delete(String boxName, String key) => box(boxName).delete(key);

  /// همه‌ی کلیدهایی که با پیشوند شروع می‌شوند (مثلاً همه‌ی نقاشی‌های یک نمایه).
  Iterable<String> keysWithPrefix(String boxName, String prefix) => box(boxName).keys.cast<String>().where((k) => k.startsWith(prefix));

  String? meta(String key) => box('meta').get(key);
  Future<void> setMeta(String key, String? value) => value == null ? box('meta').delete(key) : box('meta').put(key, value);

  int get storedVersion => int.tryParse(meta('schema') ?? '') ?? (box('profiles').isEmpty ? schemaVersion : 1);

  /// گام‌های انتقال داده، هر کدام از نسخه‌ی n به n+1.
  ///
  /// نسخه‌ی ۱: نمایه‌ها بدون گروه سنی ذخیره می‌شدند.
  /// نسخه‌ی ۲: هر نمایه «ageBand» دارد (پیش‌فرض: ۴ تا ۶ سال).
  @visibleForTesting
  static final Map<int, Future<void> Function(LocalStore)> migrations = {
    1: (s) async {
      final profiles = s.box('profiles');
      for (final key in profiles.keys.cast<String>().toList()) {
        final j = s.readJson('profiles', key);
        if (j == null) continue;
        j['ageBand'] ??= 'preschool';
        await s.writeJson('profiles', key, j);
      }
    },
  };

  Future<void> migrate() async {
    var v = storedVersion;
    while (v < schemaVersion) {
      final step = migrations[v];
      if (step != null) await step(this);
      v++;
      // نسخه پس از هر گام ذخیره می‌شود تا قطع شدن برنامه وسط انتقال، گام‌های انجام‌شده را تکرار نکند.
      await setMeta('schema', '$v');
    }
    if (meta('schema') == null) await setMeta('schema', '$schemaVersion');
  }

  Future<void> flush() async {
    for (final b in _boxes.values) {
      await b.flush();
    }
  }

  Future<void> close() async {
    for (final b in _boxes.values) {
      await b.close();
    }
  }
}
