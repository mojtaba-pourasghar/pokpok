/// ابزارهای متن فارسی: اعداد فارسی و اندازه‌ی خوانای فایل.
String faDigits(Object value) {
  const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  final b = StringBuffer();
  for (final ch in value.toString().split('')) {
    final d = int.tryParse(ch);
    b.write(d == null ? ch : fa[d]);
  }
  return b.toString();
}

String faBytes(int bytes) {
  if (bytes < 1024) return '${faDigits(bytes)} بایت';
  if (bytes < 1024 * 1024) return '${faDigits((bytes / 1024).round())} کیلوبایت';
  final mb = (bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', '٫');
  return '${faDigits(mb)} مگابایت';
}

String faMinutes(int seconds) {
  final m = (seconds / 60).round();
  if (m < 1) return 'کمتر از یک دقیقه';
  if (m < 60) return '${faDigits(m)} دقیقه';
  final h = m ~/ 60;
  final rest = m % 60;
  return rest == 0 ? '${faDigits(h)} ساعت' : '${faDigits(h)} ساعت و ${faDigits(rest)} دقیقه';
}

/// تاریخ نسبی ساده برای تاریخچه («امروز»، «دیروز»، «۳ روز پیش»).
String faRelativeDay(DateTime at, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(at.year, at.month, at.day);
  final d = today.difference(day).inDays;
  if (d <= 0) return 'امروز';
  if (d == 1) return 'دیروز';
  return '${faDigits(d)} روز پیش';
}

/// عددهای فارسی به حروف (۰ تا ۹) برای دروازه‌ی والدین.
const faNumberWords = ['صفر', 'یک', 'دو', 'سه', 'چهار', 'پنج', 'شش', 'هفت', 'هشت', 'نه'];
