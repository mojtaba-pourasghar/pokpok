import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/widgets/buttons.dart';
import 'package:popo/core/widgets/common.dart';

import 'helpers.dart';

/// هر صفحه در اندازه‌های مختلف بدون خطا و بدون سرریز باز می‌شود.
void main() {
  const routes = [
    '/',
    '/intro',
    '/profiles',
    '/map',
    '/world/home',
    '/world/city',
    '/world/nature?scene=nature.farm',
    '/play/play.cook',
    '/play/play.shop',
    '/play/play.garden',
    '/play/play.pet',
    '/play/play.tidy',
    '/art',
    '/art/gallery',
    '/music',
    '/music?tab=songs',
    '/build',
    '/library',
    '/puzzle/shapes',
    '/puzzle/sort',
    '/puzzle/pattern',
    '/puzzle/match',
    '/rewards',
    '/parent-gate',
  ];
  const sizes = {'phone-small': Size(320, 640), 'phone': Size(412, 915), 'tablet-landscape': Size(1280, 800)};

  for (final s in sizes.entries) {
    for (final r in routes) {
      testWidgets('$r @ ${s.key}', (tester) async {
        final env = await tester.runAsync(TestEnv.create);
        await setSurface(tester, s.value);
        await tester.pumpWidget(testApp(env!, location: r));
        await settle(tester);
        expect(tester.takeException(), isNull);
        // هیچ تصویری با اندازه‌ی صفر کشیده نشده (Stack جمع‌شده یا چیدمان شکسته)
        for (final e in find.byType(ArtImage).evaluate()) {
          final box = e.renderObject as RenderBox?;
          if (box == null || !box.hasSize) continue;
          expect(box.size.width, greaterThan(0), reason: 'ArtImage بی‌اندازه در $r');
        }
        final scaffoldBox = tester.renderObject<RenderBox>(find.byType(Scaffold).last);
        expect(scaffoldBox.size, s.value);
        // هر کنترل لمسی که روی صفحه دیده می‌شود، واقعاً لمس‌پذیر است (نه فقط کشیده‌شده).
        final screen = Offset.zero & s.value;
        for (final type in [PTile, PButton, PIconButton]) {
          for (final e in find.byType(type).evaluate()) {
            final box = e.renderObject! as RenderBox;
            final c = box.localToGlobal(box.size.center(Offset.zero));
            if (!screen.deflate(4).contains(c)) continue;
            final hit = tester.hitTestOnBinding(c);
            expect(hit.path.any((h) => identical(h.target, box)), isTrue, reason: '$type not tappable at $c on $r');
          }
        }
        await tester.pumpWidget(const SizedBox());
        await settle(tester, 3);
        await tester.runAsync(env.dispose);
      });
    }
  }
}
