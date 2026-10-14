// Renders POPO's model sheet (the eight approved poses, with Persian labels) and the art set
// overview into docs/art/. These are the reference images for anyone drawing new POPO art.
//   flutter test test/tools/make_model_sheet_test.dart --dart-define=MAKE_DOCS=true
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/app/theme/tokens.dart';
import 'package:popo/features/mascot/popo_painter.dart';

const _run = bool.fromEnvironment('MAKE_DOCS');

const _labels = {
  PopoPose.welcome: 'خوشامد و دست تکان دادن',
  PopoPose.curious: 'کنجکاو',
  PopoPose.thinking: 'در حال فکر',
  PopoPose.happy: 'شاد و جشن',
  PopoPose.surprised: 'شگفت‌زده',
  PopoPose.sleepy: 'خواب‌آلود',
  PopoPose.pointing: 'اشاره به یک چیز',
  PopoPose.idle: 'آرام',
};

void main() {
  test('model sheet', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Vazirmatn')..addFont(rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf'));
    await loader.load();
    const cellW = 260.0, cellH = 360.0, cols = 4;
    const size = Size(cellW * cols, cellH * 2 + 70);
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(Offset.zero & size, Paint()..color = PColors.background);
    void text(String s, Offset at, double fs, Color color, double width) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: fs, fontWeight: FontWeight.w700, color: color),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      )..layout(minWidth: width, maxWidth: width);
      tp.paint(c, at);
    }

    text('پوپو — برگه‌ی مدل شخصیت (هشت حالت تأییدشده)', const Offset(0, 16), 28, PColors.ink, size.width);
    for (final (i, pose) in PopoPose.values.indexed) {
      final x = (cols - 1 - i % cols) * cellW; // راست به چپ
      final y = 70 + (i ~/ cols) * cellH;
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x + 10, y + 10, cellW - 20, cellH - 20), const Radius.circular(28)),
        Paint()..color = Colors.white,
      );
      c.save();
      c.translate(x + 30, y + 30);
      PopoPainter(pose: pose, wave: .2, breath: .25).paint(c, const Size(cellW - 60, cellH - 100));
      c.restore();
      text(_labels[pose]!, Offset(x, y + cellH - 64), 20, PColors.inkSoft, cellW);
    }
    final img = await rec.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('docs/art/popo_model_sheet.png');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes!.buffer.asUint8List());
  }, skip: !_run);
}
