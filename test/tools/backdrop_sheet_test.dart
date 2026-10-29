import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/ui/toons/backdrops.dart';
import 'package:popo/ui/toons/toon.dart';

/// برگه‌ی بازبینی پس‌زمینه‌های زنده (فقط با TOON_SHEET=1).
void main() {
  test('backdrop sheet', () async {
    const w = 300.0, h = 560.0;
    final ids = backdrops.keys.toList();
    const cols = 6;
    final rows = (ids.length / cols).ceil();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    for (final (i, id) in ids.indexed) {
      c.save();
      c.translate((i % cols) * (w + 6), (i ~/ cols) * (h + 6));
      c.clipRect(const Rect.fromLTWH(0, 0, w, h));
      backdrops[id]!(Pen(c), const Size(w, h), 7.3);
      c.restore();
    }
    final img = await rec.endRecording().toImage(((w + 6) * cols).round(), ((h + 6) * rows).round());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/toon_sheets').createSync(recursive: true);
    File('build/toon_sheets/backdrops.png').writeAsBytesSync(png!.buffer.asUint8List());
    File('build/toon_sheets/backdrops.txt').writeAsStringSync(ids.join(' '));
  }, skip: Platform.environment['TOON_SHEET'] != '1');
}
