import 'dart:async';

import 'package:flutter/services.dart';

/// تبلیغ تمام‌صفحه‌ی بعد از هر بخش (نسخه‌ی رایگان). پیاده‌سازی واقعی ادیوری است
/// (android/.../AdiveryAds.kt)؛ در آزمون‌ها و روی وب [NoAds].
abstract class Ads {
  /// تبلیغ بعدی از پیش بارگیری می‌شود تا وقت نمایش معطل نماند. چند بار صدا زدنش بی‌ضرر است.
  Future<void> prepare();

  /// اگر تبلیغی آماده است نشانش می‌دهد و تا بسته شدنش صبر می‌کند. true یعنی تبلیغی دیده شد؛
  /// false یعنی آماده نبود (بی‌اینترنت، شناسه‌ها خالی، …) و بازی بی‌معطلی ادامه می‌دهد.
  Future<bool> show();
}

class AdiveryAds implements Ads {
  const AdiveryAds();

  static const _channel = MethodChannel('com.pokpok.ir/ads');

  /// اگر به هر دلیل «بسته شد» از ادیوری نرسید، کودک بیشتر از این پشت صفحه نمی‌ماند.
  static const _limit = Duration(minutes: 2);

  @override
  Future<void> prepare() async {
    try {
      await _channel.invokeMethod<void>('prepare');
    } on MissingPluginException {
      // وب و آزمون‌ها
    } on PlatformException {
      // بی‌شناسه یا خطای ادیوری: بی‌تبلیغ ادامه.
    }
  }

  @override
  Future<bool> show() async {
    try {
      return await _channel.invokeMethod<bool>('show').timeout(_limit, onTimeout: () => false) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

/// بی‌تبلیغ (آزمون‌ها، وب).
class NoAds implements Ads {
  const NoAds();

  @override
  Future<void> prepare() async {}

  @override
  Future<bool> show() async => false;
}

/// برای آزمون‌ها: هر نمایش را می‌شمارد.
class CountingAds implements Ads {
  int prepared = 0;
  int shown = 0;

  @override
  Future<void> prepare() async => prepared++;

  @override
  Future<bool> show() async {
    shown++;
    return true;
  }
}
