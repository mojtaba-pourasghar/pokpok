import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/ui/toons/toons.dart';

/// برگه‌ی بازبینی کارتون‌ها: هر کارتون در چهار حالت (آرام، آرام بعدی، مشغول، خوشحال/ناراحت)
/// در build/toon_sheets/ کشیده می‌شود. فقط با TOON_SHEET=1 اجرا می‌شود.
void main() {
  test('toon sheets', () async {
    const cell = 140.0;
    const cols = 8;
    final ids = toons.keys.toList();
    final dir = Directory('build/toon_sheets')..createSync(recursive: true);
    const perSheet = 24;
    for (var sheet = 0; sheet * perSheet < ids.length; sheet++) {
      final part = ids.skip(sheet * perSheet).take(perSheet).toList();
      final rows = (part.length / 2).ceil();
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawRect(Rect.fromLTWH(0, 0, cell * cols, cell * rows), Paint()..color = const Color(0xFFDDEEFF));
      for (final (i, id) in part.indexed) {
        final poses = [
          const ToonPose(.3),
          const ToonPose(1.75),
          const ToonPose(.9, mood: ToonMood.act),
          ToonPose(.25, mood: i.isEven ? ToonMood.happy : ToonMood.sad),
        ];
        for (final (j, p) in poses.indexed) {
          final x = ((i % 2) * 4 + j) * cell, y = (i ~/ 2) * cell;
          c.save();
          c.translate(x, y);
          c.drawRect(
            const Rect.fromLTWH(1, 1, cell - 2, cell - 2),
            Paint()..color = (i ~/ 2).isEven ? const Color(0xFFF4FAFF) : const Color(0xFFFFFBF0),
          );
          c.scale(cell / 100);
          toons[id]!(Pen(c), p);
          c.restore();
        }
      }
      final img = await rec.endRecording().toImage((cell * cols).round(), (cell * rows).round());
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('${dir.path}/sheet_$sheet.png').writeAsBytesSync(png!.buffer.asUint8List());
      File('${dir.path}/sheet_$sheet.txt').writeAsStringSync(part.join('\n'));
    }
  }, skip: Platform.environment['TOON_SHEET'] != '1');
}
