import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/app/app.dart';
import 'package:popo/app/providers.dart';
import 'package:popo/app/router.dart';
import 'package:popo/core/ads/ads.dart';
import 'package:popo/core/billing/access_store.dart';
import 'package:popo/core/billing/billing.dart';
import 'package:popo/features/home/home_shell.dart';
import 'package:popo/features/paywall/paywall.dart';

import 'helpers.dart';

/// دو حالت: رایگان (همه باز، تبلیغ بعد از هر بخش) و نسخه‌ی کامل (بی‌تبلیغ)، و دکمه‌ی خرید در «من».
void main() {
  Widget app(TestEnv env, String location, {bool owned = false, Ads ads = const NoAds()}) {
    if (owned) env.prefs.setBool('popo.full.v1', true);
    return ProviderScope(
      overrides: [
        ...env.overrides,
        routerProvider.overrideWith((ref) => buildRouter(ref, initialLocation: location)),
        accessProvider.overrideWith((_) => AccessStore(env.prefs, const NoBilling())),
        adsProvider.overrideWithValue(ads),
      ],
      child: const PopoApp(),
    );
  }

  testWidgets('رایگان: فصل‌ها و بخش‌های بی‌سابقه هم باز است و مستقیم بازی می‌شود', (tester) async {
    final semantics = tester.ensureSemantics();
    final env = await tester.runAsync(TestEnv.create);
    await setSurface(tester, const Size(412, 915));
    await tester.pumpWidget(app(env!, '/chapter/c5'));
    await settle(tester, 20);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    expect(c.read(accessProvider).showsAds, isTrue);
    final gate = c.read(gateProvider);
    for (final ch in env.game.chapters) {
      expect(gate.chapterOpen(ch), isTrue);
      for (var i = 0; i < ch.sections.length; i++) {
        expect(gate.sectionOpen(ch, i), isTrue);
      }
    }

    await tester.tap(find.bySemanticsLabel(RegExp('بخش ۴: ')));
    await settle(tester, 20);
    expect(find.byType(PaywallSheet), findsNothing);
    expect(find.text('شروع کنیم!'), findsOneWidget, reason: 'the last section of chapter 5 opens with no purchase');
    expect(tester.takeException(), isNull);

    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    await tester.runAsync(env.dispose);
  });

  testWidgets('زبانه‌ی «من»: دکمه‌ی خرید هست؛ بعد از خرید «بدون تبلیغ» و دیگر دکمه‌ای نیست', (tester) async {
    final env = await tester.runAsync(TestEnv.create);
    await setSurface(tester, const Size(412, 915));
    await tester.pumpWidget(app(env!, '/home?tab=me'));
    await settle(tester);
    expect(find.textContaining('خرید از کافه‌بازار'), findsOneWidget);
    expect(find.text('قبلاً خریده‌ام'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);

    await tester.pumpWidget(app(env, '/home?tab=me', owned: true));
    await settle(tester);
    expect(find.textContaining('خرید از کافه‌بازار'), findsNothing);
    expect(find.text('نسخه‌ی کامل — بدون تبلیغ'), findsOneWidget);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    expect(c.read(accessProvider).showsAds, isFalse);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    await tester.runAsync(env.dispose);
  });

  testWidgets('دکمه‌ی خرید در «من» اول دروازه‌ی والدین را نشان می‌دهد', (tester) async {
    final env = await tester.runAsync(TestEnv.create);
    await setSurface(tester, const Size(412, 915));
    await tester.pumpWidget(app(env!, '/home?tab=me'));
    await settle(tester);
    await tester.tap(find.textContaining('خرید از کافه‌بازار'));
    await settle(tester);
    expect(find.text('فقط برای بزرگ‌ترها'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    await tester.runAsync(env.dispose);
  });

  test('بی‌بازار: خرید «در دسترس نیست»، نه خطا', () async {
    expect(await const NoBilling().purchase('popo_full'), PurchaseResult.unavailable);
  });
}
