import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/data/models/models.dart';
import 'package:popo/features/play/discover.dart';
import 'package:popo/game/engines/engines.dart';
import 'package:popo/ui/clay.dart';
import 'package:popo/ui/fx.dart';

import '../helpers.dart';

/// عکس یک گام یا صحنه برای بازبینی (ENGINE_SHOT=c1s2:5 یا ENGINE_SHOT=show:bread:bear).
void main() {
  testWidgets('engine shot', (tester) async {
    final env = (await tester.runAsync(TestEnv.create))!;
    await setSurface(tester, const Size(412, 700));
    final spec = Platform.environment['ENGINE_SHOT']!.split(':');
    final key = GlobalKey();
    late Widget child;
    if (spec[0] == 'show') {
      child = ItemShowcase(item: env.game.items[spec[1]]!, friend: spec.length > 2 ? spec[2] : null, play: true);
    } else {
      final sec = [for (final c in env.game.chapters) ...c.sections].firstWhere((s) => s.id == spec[0]);
      final host = EngineHost(onDone: () {}, onMistake: () {}, onPoints: (_) {}, onHint: (_) {}, age: AgeBand.preschool, data: env.game);
      child = buildEngine(sec.steps[int.parse(spec[1]) - 1], host);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: env.overrides,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: RepaintBoundary(
              key: key,
              child: SkyScene(
                scene: 'kitchen',
                child: FxLayer(
                  child: Padding(padding: const EdgeInsets.all(16), child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final img = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/engine_shot.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  }, skip: Platform.environment['ENGINE_SHOT'] == null);
}
