import 'package:flutter/foundation.dart';

enum PurchaseStatus { unavailable, ready, pending, done, failed }

/// خرید درون‌برنامه‌ای. این نسخه هیچ فروشگاهی (Google Play، کافه‌بازار، مایکت، App Store)
/// را وصل نکرده و همه‌ی محتوا رایگان و داخل برنامه است؛ پس پیاده‌سازی پیش‌فرض صادقانه
/// «در دسترس نیست» برمی‌گرداند. اتصال فروشگاه یعنی نوشتن پیاده‌سازی دیگری از همین رابط.
abstract class PurchaseService extends ChangeNotifier {
  PurchaseStatus get status;
  String get storeName;
  Future<void> restore();
}

class NoStorePurchaseService extends PurchaseService {
  @override
  PurchaseStatus get status => PurchaseStatus.unavailable;

  @override
  String get storeName => '';

  @override
  Future<void> restore() async {}
}
