import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/features/play/discover.dart';
import 'package:popo/ui/fx.dart';

import 'helpers.dart';

/// «امتحانش کن» و «باهاش بازی کن» برای همه‌ی ساخته‌ها: صحنه ساخته، لمس و کشیده می‌شود و
/// هر بار که کودک کاری کرد، شمارنده‌ی تلاش (که دکمه‌ی «فهمیدم!» را باز می‌کند) باید بالا برود.
void main() {
  late TestEnv env;

  setUpAll(() async {
    env = await TestEnv.create();
  });

  tearDownAll(() => env.dispose());

  for (final play in [false, true]) {
    testWidgets('every item scene runs and counts tries (play: $play)', (tester) async {
      await setSurface(tester, const Size(360, 720));
      final stuck = <String>[];
      for (final item in env.game.items.values) {
        var tries = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: env.overrides,
            child: MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: FxLayer(
                    child: Center(
                      child: SizedBox(
                        key: const ValueKey('stage'),
                        width: 340,
                        height: 460,
                        child: ItemShowcase(
                          key: ValueKey('${item.id}$play'),
                          item: item,
                          friend: 'bear',
                          play: play,
                          onTry: (n) => tries = n,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final box = tester.getRect(find.byKey(const ValueKey('stage')));
        // لمس روی یک شبکه از نقطه‌ها، بعد چند کشیدن (غذا به دهان، چراغ، بادبادک، آهن‌ربا).
        for (var round = 0; round < 2; round++) {
          for (var y = .1; y < 1; y += .2) {
            for (var x = .1; x < 1; x += .2) {
              await tester.tapAt(Offset(box.left + box.width * x, box.top + box.height * y));
              await tester.pump(const Duration(milliseconds: 160));
            }
          }
        }
        for (final (from, by) in [
          (const Offset(.8, .3), const Offset(-.6, .5)),
          (const Offset(.5, .5), const Offset(.3, -.3)),
          (const Offset(.2, .2), const Offset(.6, .6)),
          (const Offset(.75, .25), const Offset(-.55, .55)),
        ]) {
          final start = Offset(box.left + box.width * from.dx, box.top + box.height * from.dy);
          final g = await tester.startGesture(start);
          for (var k = 1; k <= 12; k++) {
            await g.moveTo(start + Offset(box.width * by.dx * k / 12, box.height * by.dy * k / 12));
            await tester.pump(const Duration(milliseconds: 40));
          }
          await g.up();
          await tester.pump(const Duration(milliseconds: 200));
        }
        // پدال گاز: نگه داشتن پایین صحنه
        final hold = await tester.startGesture(Offset(box.left + box.width * .85, box.bottom - 30));
        await tester.pump(const Duration(seconds: 3));
        await hold.up();
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull, reason: '${item.id} (${item.kind})');
        if (tries < 2) stuck.add('${item.id}(${item.kind}):$tries');
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
      }
      expect(stuck, isEmpty, reason: 'these scenes never reached two tries, so «فهمیدم!» stays locked');
    });
  }
}
