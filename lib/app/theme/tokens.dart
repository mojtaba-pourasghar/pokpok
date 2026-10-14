import 'package:flutter/material.dart';

/// رنگ‌های پوپو. همه‌جا از این نشانه‌ها استفاده می‌شود، نه رنگ‌های پراکنده.
abstract final class PColors {
  // پالت اصلی برند
  static const orange = Color(0xFFFF9D37);
  static const turquoise = Color(0xFF16B9D1);
  static const blue = Color(0xFF3778F6);
  static const green = Color(0xFFA6D943);
  static const yellow = Color(0xFFFFD34F);
  static const purple = Color(0xFFA77BEF);
  static const background = Color(0xFFF4F8FF);

  // نقش‌های معنایی
  static const primary = blue;
  static const accent = orange;
  static const success = Color(0xFF3DBE6B);
  static const danger = Color(0xFFF2574E);
  static const pink = Color(0xFFFF8FB8);
  static const ink = Color(0xFF2B2A4C);
  static const inkSoft = Color(0xFF5F6283);
  static const card = Colors.white;
  static const line = Color(0xFFE2E8F5);
  static const sky = Color(0xFFDDF1FF);
  static const cream = Color(0xFFFFF4E3);
  static const fur = Color(0xFFFF9D37);
  static const furDark = Color(0xFFD9741A);
  static const muzzle = Color(0xFFFFE9C9);
  static const outfit = Color(0xFF16B9D1);
  static const headphones = Color(0xFF3778F6);

  /// رنگ هر جهان (برای کارت‌ها و عنوان‌ها).
  static const worlds = <String, Color>{
    'home': orange,
    'city': blue,
    'nature': Color(0xFF6CC24A),
    'art': pink,
    'music': purple,
    'build': Color(0xFFF2B33D),
  };

  static Color shade(Color c, [double amount = .16]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color tint(Color c, [double amount = .32]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static Color fromHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }
}

abstract final class PSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const gutter = 20.0;
}

abstract final class PRadius {
  static const sm = 14.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const xl = 36.0;
  static const pill = 999.0;
}

/// اندازه‌های لمسی: کنترل‌های اصلی ۵۶ تا ۷۶ نقطه.
abstract final class PTouch {
  static const min = 56.0;
  static const button = 64.0;
  static const big = 76.0;
}

abstract final class PMotion {
  static const tap = Duration(milliseconds: 120);
  static const quick = Duration(milliseconds: 220);
  static const medium = Duration(milliseconds: 380);
  static const slow = Duration(milliseconds: 650);
  static const enter = Curves.easeOutCubic;
  static const bounce = Curves.elasticOut;
}

abstract final class PShadow {
  static List<BoxShadow> soft([Color tint = const Color(0xFF3B4A8C)]) => [
    BoxShadow(color: tint.withValues(alpha: .12), blurRadius: 18, offset: const Offset(0, 8)),
    BoxShadow(color: tint.withValues(alpha: .06), blurRadius: 4, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> glow(Color c) => [BoxShadow(color: c.withValues(alpha: .5), blurRadius: 24, spreadRadius: 2)];
}
