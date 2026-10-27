import 'package:flutter/services.dart';

/// نتیجه‌ی یک تلاش خرید.
enum PurchaseResult { purchased, cancelled, failed, unavailable }

/// پرداخت درون‌برنامه‌ای. پیاده‌سازی واقعی کافه‌بازار است (BazaarBilling.kt)؛
/// در آزمون‌ها و روی وب [NoBilling].
abstract class Billing {
  /// اتصال به بازار. false یعنی بازار نصب نیست، کلید RSA داده نشده یا اتصال نشد.
  Future<bool> connect();

  /// شناسه‌ی محصول‌های خریده‌شده؛ null اگر نشد پرسید (مثلاً بی‌اینترنت).
  Future<List<String>?> purchased();

  /// قیمتی که بازار برای محصول نشان می‌دهد (متن آماده، مثلاً «۱۸۰٬۰۰۰ تومان»).
  Future<String?> price(String productId);

  Future<PurchaseResult> purchase(String productId);
}

class BazaarBilling implements Billing {
  const BazaarBilling();

  static const _channel = MethodChannel('com.pokpok.ir/billing');

  @override
  Future<bool> connect() async {
    try {
      return await _channel.invokeMethod<bool>('connect') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<List<String>?> purchased() async {
    try {
      final list = await _channel.invokeListMethod<String>('purchased');
      return list ?? const [];
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<String?> price(String productId) async {
    try {
      return await _channel.invokeMethod<String>('price', {'productId': productId});
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    try {
      final r = await _channel.invokeMethod<String>('purchase', {'productId': productId});
      return r == 'ok' ? PurchaseResult.purchased : PurchaseResult.cancelled;
    } on MissingPluginException {
      return PurchaseResult.unavailable;
    } on PlatformException catch (e) {
      return e.code == 'NOT_CONNECTED' || e.code == 'NO_KEY' ? PurchaseResult.unavailable : PurchaseResult.failed;
    }
  }
}

/// بدون پرداخت (آزمون‌ها، وب). همه‌چیز «در دسترس نیست».
class NoBilling implements Billing {
  const NoBilling();

  @override
  Future<bool> connect() async => false;

  @override
  Future<List<String>?> purchased() async => null;

  @override
  Future<String?> price(String productId) async => null;

  @override
  Future<PurchaseResult> purchase(String productId) async => PurchaseResult.unavailable;
}
