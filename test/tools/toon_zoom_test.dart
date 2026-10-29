import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/ui/toons/toons.dart';

/// چند کارتون در اندازه‌ی بزرگ برای بازبینی جزئیات (TOON_SHEET=1، شناسه‌ها در TOON_IDS).
void main() {
  test('toon zoom', () async {
    final ids = (Platform.environment['TOON_IDS'] ?? 'orange,bear,toy_car,hen').split(',');
    const cell = 360.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(Rect.fromLTWH(0, 0, cell * ids.length, cell), Paint()..color = const Color(0xFFEFF6FF));
    for (final (i, id) in ids.indexed) {
      c.save();
      c.translate(i * cell, 0);
      c.scale(cell / 100);
      toons[id]!(Pen(c), const ToonPose(.4));
      c.restore();
    }
    final img = await rec.endRecording().toImage((cell * ids.length).round(), cell.round());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/toon_sheets').createSync(recursive: true);
    File('build/toon_sheets/zoom.png').writeAsBytesSync(png!.buffer.asUint8List());
  }, skip: Platform.environment['TOON_SHEET'] != '1');
}
