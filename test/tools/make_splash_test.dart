// Renders Popo's head for the Android launch screen (res/drawable-*/launch_fox.png), the same
// picture and size the app's own loading screen draws (lib/features/mascot/popo_loader.dart), so
// the hand-over from the system splash to the app shows no jump. Run it on purpose:
//   flutter test test/tools/make_splash_test.dart --dart-define=MAKE_SPLASH=true
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/features/mascot/popo_loader.dart';

const _run = bool.fromEnvironment('MAKE_SPLASH');

Future<void> _splash(String path, int px) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final s = px.toDouble();
  PopoHeadPainter().paint(c, Size(s, s));
  final img = await rec.endRecording().toImage(px, px);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final f = File(path);
  await f.parent.create(recursive: true);
  await f.writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  test('make launch screen fox', () async {
    const density = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
    for (final e in density.entries) {
      await _splash('android/app/src/main/res/drawable-${e.key}/launch_fox.png', (popoLoaderHeadSize * e.value).round());
    }
  }, skip: !_run);
}
