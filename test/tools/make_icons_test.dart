// Renders POPO's launcher icon (the mascot's head on a sunny round tile) into every size Android,
// iOS and the web build need. Run it on purpose; it is skipped in the normal test run:
//   flutter test test/tools/make_icons_test.dart --dart-define=MAKE_ICONS=true
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/app/theme/tokens.dart';
import 'package:popo/features/mascot/popo_painter.dart';

const _run = bool.fromEnvironment('MAKE_ICONS');

Future<void> _icon(String path, int size, {bool round = false, bool maskable = false}) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final s = size.toDouble();
  final rect = Offset.zero & Size(s, s);
  final bg = Paint()
    ..shader = const RadialGradient(
      center: Alignment(-.3, -.4),
      colors: [Color(0xFFFFE89A), PColors.yellow, PColors.orange],
      stops: [0, .55, 1],
    ).createShader(rect);
  if (round) {
    c.drawCircle(rect.center, s / 2, bg);
  } else {
    c.drawRect(rect, bg);
  }
  // سر پوپو: فقط بالای نقاشی (۲۰۰×۱۷۰ از ۲۰۰×۲۶۰)، کمی کوچک‌تر برای ناحیه‌ی امن.
  final k = maskable ? .62 : .8;
  final w = s * k;
  final scale = w / 200;
  c.save();
  c.translate((s - w) / 2, s * (maskable ? .2 : .12));
  c.scale(scale);
  c.clipRect(const Rect.fromLTWH(-20, -20, 240, 182));
  PopoPainter(pose: PopoPose.happy).paint(c, PopoPainter.designSize);
  c.restore();
  final img = await rec.endRecording().toImage(size, size);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final f = File(path);
  await f.parent.create(recursive: true);
  await f.writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  test('make launcher icons', () async {
    const android = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
    for (final e in android.entries) {
      await _icon('android/app/src/main/res/mipmap-${e.key}/ic_launcher.png', e.value);
    }
    final ios = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    if (ios.existsSync()) {
      final re = RegExp(r'Icon-App-(\d+(?:\.\d+)?)x\d+(?:\.\d+)?@(\d)x\.png');
      for (final f in ios.listSync().whereType<File>()) {
        final m = re.firstMatch(f.uri.pathSegments.last);
        if (m == null) continue;
        await _icon(f.path, (double.parse(m[1]!) * int.parse(m[2]!)).round());
      }
    }
    await _icon('web/favicon.png', 32, round: true);
    await _icon('web/icons/Icon-192.png', 192, round: true);
    await _icon('web/icons/Icon-512.png', 512, round: true);
    await _icon('web/icons/Icon-maskable-192.png', 192, maskable: true);
    await _icon('web/icons/Icon-maskable-512.png', 512, maskable: true);
  }, skip: !_run);
}
