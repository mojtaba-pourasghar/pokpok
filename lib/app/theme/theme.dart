import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tokens.dart';

/// سبک‌های متن؛ هیچ متنی زیر ۱۴ نیست.
abstract final class PText {
  static const family = 'Vazirmatn';

  static const display = TextStyle(fontFamily: family, fontSize: 32, fontWeight: FontWeight.w900, color: PColors.ink, height: 1.3);
  static const title = TextStyle(fontFamily: family, fontSize: 23, fontWeight: FontWeight.w800, color: PColors.ink, height: 1.35);
  static const heading = TextStyle(fontFamily: family, fontSize: 18, fontWeight: FontWeight.w800, color: PColors.ink, height: 1.4);
  static const body = TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w500, color: PColors.ink, height: 1.6);
  static const bodyStrong = TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w700, color: PColors.ink, height: 1.5);
  static const caption = TextStyle(fontFamily: family, fontSize: 14, fontWeight: FontWeight.w600, color: PColors.inkSoft, height: 1.5);
  static const button = TextStyle(fontFamily: family, fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2);
  static const label = TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w800, color: PColors.ink, height: 1.3);
}

ThemeData buildPopoTheme({bool highContrast = false}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: PColors.blue,
    primary: PColors.blue,
    secondary: PColors.orange,
    surface: PColors.background,
    error: PColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: PText.family,
    scaffoldBackgroundColor: PColors.background,
    textTheme: const TextTheme(
      displaySmall: PText.display,
      titleLarge: PText.title,
      titleMedium: PText.heading,
      bodyLarge: PText.body,
      bodyMedium: PText.body,
      labelLarge: PText.bodyStrong,
      bodySmall: PText.caption,
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 10,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 14),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 26),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? PColors.success : PColors.line),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PRadius.lg)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(PRadius.xl))),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
    ),
  );
}
