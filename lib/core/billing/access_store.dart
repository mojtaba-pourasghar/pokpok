import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'billing.dart';

/// دو حالت برنامه:
///
/// - **رایگان**: همه‌ی فصل‌ها، بخش‌ها و بازی‌ها باز است؛ بعد از تمام شدن هر بخش یک تبلیغ تمام‌صفحه
///   (ادیوری) نشان داده می‌شود ([showsAds]).
/// - **نسخه‌ی کامل** (یک بار خرید از کافه‌بازار، از زبانه‌ی «من»): همان بازی، بی هیچ تبلیغی.
///
/// شناسه‌ی محصول و قیمت در پنل کافه‌بازار تعریف می‌شوند؛ قیمت نمایشی از خود بازار خوانده می‌شود و
/// اگر نشد، [fallbackPrice] نشان داده می‌شود.
class AccessStore extends ChangeNotifier {
  AccessStore(this._prefs, this._billing) {
    _owned = _prefs.getBool(_key) ?? false;
  }

  static const productId = String.fromEnvironment('BAZAAR_SKU', defaultValue: 'popo_full');
  static const fallbackPrice = '۱۸۰٬۰۰۰ تومان';
  static const _key = 'popo.full.v1';

  final SharedPreferences _prefs;
  final Billing _billing;

  bool _owned = false;
  String? _price;
  bool _busy = false;

  /// نسخه‌ی کامل (بی‌تبلیغ) خریده شده است.
  bool get owned => _owned;
  bool get busy => _busy;
  String get price => _price ?? fallbackPrice;

  /// بعد از هر بخش تبلیغ نشان داده می‌شود (نسخه‌ی رایگان).
  bool get showsAds => !_owned;

  /// با بازار هماهنگ می‌شود: خرید قبلی (مثلاً روی گوشی دیگر یا بعد از نصب دوباره) و قیمت.
  /// بی‌اینترنت یا بی‌بازار، همان وضعیت ذخیره‌شده می‌ماند.
  Future<void> sync() async {
    if (!await _billing.connect()) return;
    final list = await _billing.purchased();
    if (list != null) await _setOwned(list.contains(productId));
    final p = await _billing.price(productId);
    if (p != null && p.isNotEmpty) {
      _price = p;
      notifyListeners();
    }
  }

  Future<PurchaseResult> buy() async {
    if (_busy) return PurchaseResult.failed;
    _busy = true;
    notifyListeners();
    try {
      if (!await _billing.connect()) return PurchaseResult.unavailable;
      final r = await _billing.purchase(productId);
      if (r == PurchaseResult.purchased) await _setOwned(true);
      return r;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// «قبلاً خریده‌ام»: از بازار می‌پرسد. true اگر خرید پیدا شد.
  Future<bool?> restore() async {
    if (!await _billing.connect()) return null;
    final list = await _billing.purchased();
    if (list == null) return null;
    await _setOwned(list.contains(productId));
    return _owned;
  }

  Future<void> _setOwned(bool value) async {
    if (_owned == value) return;
    _owned = value;
    await _prefs.setBool(_key, value);
    notifyListeners();
  }
}
