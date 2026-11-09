import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/features/play/discover.dart';
import 'package:popo/ui/clay.dart';
import 'package:popo/ui/fx.dart';

import 'helpers.dart';

/// اتوبوس (و هر وسیله‌ی نقلیه): استارت، بعد نگه داشتن پدال واقعاً حرکتش می‌دهد و شمار متر بالا می‌رود.
void main() {
  for (final id in ['bus', 'toy_car', 'cart', 'train', 'bicycle', 'rocket', 'submarine']) {
    testWidgets('$id moves while the pedal is held', (tester) async {
      final env = (await tester.runAsync(TestEnv.create))!;
      await setSurface(tester, const Size(412, 700));
      final item = env.game.items[id]!;
      var tries = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: FxLayer(child: ItemShowcase(item: item, friend: 'bear', onTry: (n) => tries = n)),
              ),
            ),
          ),
        ),
      );
      await settle(tester, 3);

      int meters() => tester.widget<CountChip>(find.byWidgetPredicate((w) => w is CountChip && w.label == 'متر')).value;
      expect(meters(), 0);

      // استارت
      await tester.tap(find.bySemanticsLabel(RegExp('استارت|روشن کن')).first, warnIfMissed: false);
      await settle(tester, 3);

      // نگه داشتن پدال
      final pedal = find.textContaining('نگه دار');
      expect(pedal, findsOneWidget);
      final g = await tester.startGesture(tester.getCenter(pedal));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final moving = meters();
      expect(moving, greaterThan(0), reason: '$id must move while the pedal is held');
      await g.up();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(meters(), greaterThanOrEqualTo(moving));
      expect(tries, greaterThan(0));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await settle(tester, 3);
      await tester.runAsync(env.dispose);
    });
  }
}
