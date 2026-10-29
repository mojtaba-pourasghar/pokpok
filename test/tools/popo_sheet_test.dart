import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/features/mascot/popo_painter.dart';

void main() {
  test('popo sheet', () async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(const Rect.fromLTWH(0, 0, 1600, 260), Paint()..color = const Color(0xFFDDEEFF));
    for (final (i, pose) in PopoPose.values.indexed) {
      c.save();
      c.translate(i * 200.0, 0);
      PopoPainter(pose: pose).paint(c, const Size(200, 260));
      c.restore();
    }
    final img = await rec.endRecording().toImage(1600, 260);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/toon_sheets').createSync(recursive: true);
    File('build/toon_sheets/popo.png').writeAsBytesSync(png!.buffer.asUint8List());
  }, skip: Platform.environment['TOON_SHEET'] != '1');
}
