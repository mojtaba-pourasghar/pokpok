import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/app/app.dart';
import 'package:popo/app/providers.dart';
import 'package:popo/app/router.dart';
import 'package:popo/core/billing/access_store.dart';
import 'package:popo/core/billing/billing.dart';
import 'package:popo/data/repositories/repositories.dart';
import 'package:popo/features/home/home_shell.dart';
import 'package:popo/game/game_state.dart';
import 'package:popo/features/paywall/paywall.dart';

import 'helpers.dart';

/// نسخه‌ی release (paywall روشن): چه چیزی قفل است و لمس قفل برگه‌ی خرید را باز می‌کند.
void main() {
  Widget app(TestEnv env, String location, {bool owned = false}) {
    final access = AccessStore(env.prefs, const NoBilling(), paywall: true);
    if (owned) env.prefs.setBool('popo.full.v1', true);
    return ProviderScope(
      overrides: [
        ...env.overrides,
        routerProvider.overrideWith((ref) => buildRouter(ref, initialLocation: location)),
        accessProvider.overrideWith((_) => owned ? AccessStore(env.prefs, const NoBilling(), paywall: true) : access),
      ],
      child: const PopoApp(),
    );
  }

  /// فصل ۱ و بخش اول فصل ۲ تمام شده‌اند.
  Future<void> seed(TestEnv env) async {
    final data = env.game;
    final done = {
      for (final s in [...data.chapters[0].sections, data.chapters[1].sections.first])
        s.id: const SectionRecord(stars: 2, seconds: 60, plays: 1).toJson(),
    };
    final id = ProfileRepository(env.store).activeId ?? '_guest';
    await env.store.writeJson('game', id, {'records': done, 'lastBonusDay': dayKey(DateTime.now())});
  }

  testWidgets('فصل ۱ کامل رایگان؛ در فصل‌های بعد فقط بخش اول، و بخش پولی برگه‌ی خرید را باز می‌کند', (tester) async {
    final env = await tester.runAsync(TestEnv.create);
    await tester.runAsync(() => seed(env!));
    await setSurface(tester, const Size(412, 915));
    await tester.pumpWidget(app(env!, '/chapter/c2'));
    await settle(tester, 20);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final gate = c.read(gateProvider);
    final ch1 = env.game.chapters[0], ch2 = env.game.chapters[1];
    expect([for (var i = 0; i < 4; i++) gate.needsPurchase(ch1, i)], everyElement(isFalse));
    expect(gate.needsPurchase(ch2, 0), isFalse);
    expect(gate.needsPurchase(ch2, 1), isTrue);
    expect(gate.sectionOpen(ch2, 1), isTrue, reason: 'section 1 done → section 2 is next');
    expect(gate.sectionOpen(ch2, 2), isFalse);

    await tester.tap(find.bySemanticsLabel(RegExp('بخش ۲: ')));
    await settle(tester);
    expect(find.byType(PaywallSheet), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    await tester.runAsync(env.dispose);
  });

  testWidgets('بعد از خرید هیچ بخشی پشت پرداخت نیست', (tester) async {
    final env = await tester.runAsync(TestEnv.create);
    await setSurface(tester, const Size(412, 915));
    await tester.pumpWidget(app(env!, '/home', owned: true));
    await settle(tester);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final gate = c.read(gateProvider);
    for (final ch in env.game.chapters) {
      for (var i = 0; i < ch.sections.length; i++) {
        expect(gate.needsPurchase(ch, i), isFalse);
      }
    }

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    await tester.runAsync(env.dispose);
  });

  test('بی‌بازار: خرید «در دسترس نیست»، نه خطا', () async {
    expect(await const NoBilling().purchase('popo_full'), PurchaseResult.unavailable);
  });
}
