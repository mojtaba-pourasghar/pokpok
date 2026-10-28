import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/data/models/models.dart';
import 'package:popo/game/engines/engines.dart';
import 'package:popo/game/game_data.dart';
import 'package:popo/ui/fx.dart';

import 'helpers.dart';

/// هر نوع بازی کوچک (و هر حالت فوت کردن) با داده‌ی واقعی روی صفحه‌ی گوشی ساخته می‌شود، چند ثانیه
/// جلو می‌رود و لمس و کشیده می‌شود؛ هیچ خطای چیدمان یا اجرا نباید رخ دهد.
void main() {
  late TestEnv env;

  setUpAll(() async {
    env = await TestEnv.create();
  });

  tearDownAll(() => env.dispose());

  List<StepDef> samples() {
    final all = [
      for (final c in env.game.chapters)
        for (final s in c.sections) ...s.steps,
      for (final k in env.game.kits) ...k.section.steps,
    ];
    final seen = <String>{};
    return [
      for (final st in all)
        if (seen.add(st.engine == 'blow' ? 'blow:${st.str('mode')}' : st.engine)) st,
    ];
  }

  test('every engine name in the content has a sample', () {
    final names = {for (final s in samples()) s.engine};
    expect(names, containsAll(engineNames));
  });

  for (final age in AgeBand.values) {
    testWidgets('all engines run, take taps and drags (${age.name})', (tester) async {
      await setSurface(tester, const Size(360, 640));
      for (final st in samples()) {
        final host = EngineHost(
          onDone: () {},
          onMistake: () {},
          onPoints: (_) {},
          onHint: (_) {},
          age: age,
          data: env.game,
          backpack: const {'juice', 'hammer', 'bread'},
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: env.overrides,
            child: MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: FxLayer(
                    child: Center(
                      child: SizedBox(width: 360, height: 460, child: buildEngine(st, host, key: ValueKey(st))),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        host.start();
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final c = tester.getCenter(find.byType(SizedBox).last);
        for (final p in [c, c + const Offset(-120, 120), c + const Offset(120, 120), c + const Offset(0, -150)]) {
          await tester.tapAt(p);
          await tester.pump(const Duration(milliseconds: 120));
        }
        await tester.dragFrom(c + const Offset(0, 160), const Offset(0, -200));
        await tester.dragFrom(c, const Offset(60, 40));
        // راهنماها تا پله‌ی ۳ بالا می‌روند.
        for (var i = 0; i < 3; i++) {
          host.raiseHint();
          await tester.pump(const Duration(milliseconds: 300));
        }
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull, reason: '${st.engine} ${st.say}');
        await tester.pumpWidget(const SizedBox());
        host.dispose();
        await tester.pump(const Duration(seconds: 3));
      }
    });
  }
}
