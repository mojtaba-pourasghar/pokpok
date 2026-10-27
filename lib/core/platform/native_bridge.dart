import 'package:flutter/services.dart';

/// خبری که کودک در نوار اعلان لمس کرده (NoticeCenter.kt): برو به [screen]، یا اگر خالی است و [show]،
/// خود خبر را با عکس و دکمه‌هایش نشان بده.
class NoticeTap {
  const NoticeTap({required this.id, this.screen = '', this.show = false});

  final String id;
  final String screen;
  final bool show;

  static NoticeTap? from(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    if (id is! String || id.isEmpty) return null;
    final screen = raw['screen'];
    return NoticeTap(id: id, screen: screen is String ? screen : '', show: raw['show'] == true);
  }
}

/// کارهای کوچکی که فقط سمت اندروید شدنی است (MainActivity.kt، کانال com.pokpok.ir/native).
/// روی وب و در آزمون‌ها کانال نیست؛ هر متد آن‌جا بی‌صدا «نه» برمی‌گرداند.
class NativeBridge {
  const NativeBridge();

  static const _channel = MethodChannel('com.pokpok.ir/native');

  /// پیام‌هایی که اندروید خودش می‌فرستد: لمس یک اعلان وقتی برنامه باز است، پاسخ به اجازه‌ی اعلان.
  static void listen({void Function(NoticeTap tap)? onNoticeTapped, void Function(bool allowed)? onPermission}) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'noticeTapped':
          final tap = NoticeTap.from(call.arguments);
          if (tap != null) onNoticeTapped?.call(tap);
        case 'permissionAnswered':
          onPermission?.call(call.arguments == true);
      }
      return null;
    });
  }

  /// صفحه‌ی یک برنامه در کافه‌بازار (یا اگر بازار نصب نیست، همان صفحه در مرورگر).
  Future<bool> openStorePage(String packageName) =>
      _call<bool>('openStorePage', {'packageName': packageName}).then((v) => v ?? false);

  /// یک نشانی https در مرورگر (پیوند خبرها؛ فقط بعد از دروازه‌ی والدین صدا زده می‌شود).
  Future<bool> openUrl(String url) {
    if (!url.startsWith('https://')) return Future.value(false);
    return _call<bool>('openUrl', {'url': url}).then((v) => v ?? false);
  }

  /// نسخه‌ی همین برنامه (versionName)؛ برای «نسخه‌ی تازه آمده». خالی یعنی نمی‌دانیم.
  Future<String> appVersion() => _call<String>('appVersion').then((v) => v ?? '');

  /// اجازه‌ی نمایش اعلان (اندروید ۱۳+ و روشن بودن اعلان‌های برنامه در تنظیمات).
  Future<bool> notificationsAllowed() => _call<bool>('notificationsAllowed').then((v) => v ?? false);

  /// پنجره‌ی اجازه؛ اگر قبلاً «نه» گفته شده و [openSettings]، صفحه‌ی اعلان‌های برنامه در تنظیمات
  /// (فقط از بخش والدین — پرسیدن خودکار نباید کودک را به تنظیمات گوشی ببرد).
  Future<void> requestNotifications({bool openSettings = true}) =>
      _call<void>('requestNotifications', {'settings': openSettings});

  /// کار پس‌زمینه‌ی خبرها (NoticeWork.kt و NoticeAlarm.kt، حدود هر ربع ساعت): با نشانی روشن، با null خاموش.
  Future<void> scheduleNotices(String? url) => _call<void>('scheduleNotices', {'url': url});

  /// فوری‌ترین خبری که هنوز به نوار اعلان نرفته (یکی، با فاصله؛ NoticeCenter.post).
  Future<void> postNotices() => _call<void>('postNotices');

  /// آیا سیستم اجازه می‌دهد بررسی‌ها وقتی گوشی خواب است هم انجام شوند (بیرون از صرفه‌جویی باتری)؟
  Future<bool> runsInBackground() => _call<bool>('runsInBackground').then((v) => v ?? true);

  /// پنجره‌ی «بیرون ماندن از صرفه‌جویی باتری» — از بخش والدین.
  Future<void> askBackground() => _call<void>('askBackground');

  /// همان پنجره، فقط یک بار برای همیشه و فقط وقتی به کار می‌آید.
  Future<void> askBackgroundOnce() => _call<void>('askBackgroundOnce');

  /// آیا گوشی از سازنده‌ای است (شیائومی، هواوی، سامسونگ، …) که برنامه‌ی بسته را بی «اجرای خودکار»
  /// نگه نمی‌دارد؟
  Future<bool> hasAutostart() => _call<bool>('hasAutostart').then((v) => v ?? false);

  /// صفحه‌ی «اجرای خودکار» سازنده، یا اطلاعات برنامه در تنظیمات — از بخش والدین.
  Future<void> openAutostart() => _call<void>('openAutostart');

  /// اعلانی که برنامه با لمسش باز شد، یا null. فقط یک بار برمی‌گردد.
  Future<NoticeTap?> takeLaunchNotice() => _call<Object>('takeLaunchNotice').then(NoticeTap.from);

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
