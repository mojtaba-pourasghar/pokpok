import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// فضای آزاد دستگاه از کانال بومی (StatFs در اندروید، volumeAvailableCapacity در iOS).
/// روی وب یا اگر کانال پاسخ ندهد null است و صفحه «نامشخص» نشان می‌دهد.
class StorageInfo {
  static const _channel = MethodChannel('ir.brandimo.popo/storage');

  static Future<int?> freeBytes() async {
    if (kIsWeb) return null;
    try {
      return await _channel.invokeMethod<int>('freeBytes');
    } catch (_) {
      return null;
    }
  }
}
