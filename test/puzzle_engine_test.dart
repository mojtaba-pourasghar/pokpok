import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/data/models/models.dart';
import 'package:popo/game/engines/engines.dart';
import 'package:popo/ui/fx.dart';

import 'helpers.dart';

/// هر سه پازل بازی، در هر سه گروه سنی: صفحه‌ی مربع و چپ‌به‌راست، همه روی صفحه، تکه فقط روی خانه‌ی
/// خودش می‌نشیند، و آخرش حل می‌شود.
void main() {
  for (final age in AgeBand.values) {
    for (final sec in ['c3s4', 'c5s1', 'c7s4']) {
      testWidgets('puzzle $sec (${age.name})', (tester) async {
        final env = (await tester.runAsync(TestEnv.create))!;
        const size = Size(412, 640);
        await setSurface(tester, size);
        final step = [for (final c in env.game.chapters) ...c.sections]
            .firstWhere((s) => s.id == sec)
            .steps
            .firstWhere((s) => s.engine == 'puzzle');
        var done = false;
        final host = EngineHost(onDone: () => done = true, onMistake: () {}, onPoints: (_) {}, onHint: (_) {}, age: age, data: env.game);
        await tester.pumpWidget(
          ProviderScope(
            overrides: env.overrides,
            child: MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: FxLayer(
                    child: Padding(padding: const EdgeInsets.all(12), child: buildEngine(step, host)),
                  ),
                ),
              ),
            ),
          ),
        );
        await settle(tester, 5);
        expect(tester.takeException(), isNull);

        final targets = find.byWidgetPredicate((w) => w is DragTarget<int>);
        final pieces = find.byWidgetPredicate((w) => w is Draggable<int>);
        final n = targets.evaluate().length;
        final side = age.minAge <= 2 ? 2 : 3;
        expect(n, side * side, reason: 'square grid');
        expect(pieces.evaluate().length, n);

        // خانه‌ها مربع، بی‌فاصله، ردیف به ردیف و از چپ به راست (حتی در راست‌به‌چپ).
        final rects = [for (var i = 0; i < n; i++) tester.getRect(targets.at(i))];
        final cell = rects.first.width;
        for (var i = 0; i < n; i++) {
          expect(rects[i].width, moreOrLessEquals(cell, epsilon: .5));
          expect(rects[i].height, moreOrLessEquals(cell, epsilon: .5));
          expect(rects[i].left - rects[0].left, moreOrLessEquals((i % side) * cell, epsilon: .5), reason: 'cell $i column');
          expect(rects[i].top - rects[0].top, moreOrLessEquals((i ~/ side) * cell, epsilon: .5), reason: 'cell $i row');
        }
        // همه‌چیز روی صفحه است و تکه‌های قفسه روی هم نیفتاده‌اند.
        final screen = Offset.zero & size;
        final shelf = <Rect>[];
        for (final e in pieces.evaluate()) {
          final box = e.renderObject! as RenderBox;
          shelf.add(box.localToGlobal(Offset.zero) & box.size);
        }
        for (final r in [...rects, ...shelf]) {
          expect(screen.contains(r.topLeft) && screen.contains(r.bottomRight - const Offset(.5, .5)), isTrue, reason: 'on screen: $r');
        }
        for (var a = 0; a < shelf.length; a++) {
          for (var b = a + 1; b < shelf.length; b++) {
            expect(shelf[a].deflate(1).overlaps(shelf[b].deflate(1)), isFalse, reason: 'shelf pieces overlap');
          }
          expect(shelf[a].overlaps(rects.reduce((x, y) => x.expandToInclude(y))), isFalse, reason: 'shelf under the board');
        }

        Future<void> drag(int piece, int cellIndex) async {
          final from = tester.getCenter(find.byWidgetPredicate((w) => w is Draggable<int> && w.data == piece));
          final g = await tester.startGesture(from);
          await tester.pump(const Duration(milliseconds: 50));
          await g.moveTo(Offset.lerp(from, rects[cellIndex].center, .5)!);
          await tester.pump(const Duration(milliseconds: 50));
          await g.moveTo(rects[cellIndex].center);
          await tester.pump(const Duration(milliseconds: 50));
          await g.up();
          await settle(tester, 3);
        }

        // تکه‌ی ۰ روی خانه‌ی اشتباه نمی‌نشیند.
        await drag(0, n - 1);
        expect(pieces.evaluate().length, n, reason: 'wrong cell rejects the piece');
        expect(host.mistakes, 1, reason: 'a wrong drop counts as a mistake');

        for (var i = 0; i < n; i++) {
          await drag(i, i);
          expect(find.byWidgetPredicate((w) => w is Draggable<int> && w.data == i), findsNothing, reason: 'piece $i placed');
        }
        await settle(tester, 15);
        expect(done, isTrue, reason: 'solved');
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await settle(tester, 3);
        await tester.runAsync(env.dispose);
      });
    }
  }
}
