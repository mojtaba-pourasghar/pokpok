import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/app/app.dart';
import 'package:popo/app/providers.dart';
import 'package:popo/app/router.dart';
import 'package:popo/core/billing/access_store.dart';
import 'package:popo/core/billing/billing.dart';
import 'package:popo/core/widgets/buttons.dart';
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

  Iterable<PTile> tiles(WidgetTester tester) => tester.widgetList<PTile>(find.byType(PTile));

  testWidgets('کتابخانه: فقط بازی اول هر دسته باز است و لمس قفل برگه‌ی خرید را باز می‌کند', (tester) async {
    final env = await tester.runAsync(TestEnv.create);
    await setSurface(tester, const Size(412, 915));
    await tester.pumpWidget(app(env!, '/library'));
    await settle(tester);

    final locked = tiles(tester).where((t) => t.locked).toList();
    expect(locked, isNotEmpty);
    // دسته‌ی «کاوش»: اولی (پذیرایی) باز، بقیه قفل.
    expect(tiles(tester).firstWhere((t) => t.label == 'پذیرایی').locked, isFalse);
    expect(tiles(tester).firstWhere((t) => t.label == 'آشپزخانه').locked, isTrue);

    await tester.tap(find.widgetWithText(PTile, 'آشپزخانه'));
    await settle(tester);
    expect(find.byType(PaywallSheet), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    await tester.runAsync(env.dispose);
  });

  testWidgets('جهان: صحنه‌ی اول باز، بقیه‌ی نوار صحنه‌ها قفل؛ صحنه‌ی پولی از نشانی به صحنه‌ی اول برمی‌گردد', (tester) async {
    final env = await tester.runAsync(TestEnv.create);
    await setSurface(tester, const Size(412, 915));
    await tester.pumpWidget(app(env!, '/world/home?scene=home.kitchen'));
    await settle(tester);

    final bar = tiles(tester).toList();
    expect(bar.first.locked, isFalse);
    expect(bar.first.selected, isTrue, reason: 'آشپزخانه پولی است؛ صحنه‌ی رایگان نشان داده شد');
    expect(bar.skip(1).every((t) => t.locked), isTrue);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    await tester.runAsync(env.dispose);
  });

  testWidgets('بعد از خرید هیچ چیزی قفل نیست', (tester) async {
    final env = await tester.runAsync(TestEnv.create);
    await setSurface(tester, const Size(412, 915));
    await tester.pumpWidget(app(env!, '/library', owned: true));
    await settle(tester);
    expect(tiles(tester).any((t) => t.locked), isFalse);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    await tester.runAsync(env.dispose);
  });

  test('بی‌بازار: خرید «در دسترس نیست»، نه خطا', () async {
    expect(await const NoBilling().purchase('popo_full'), PurchaseResult.unavailable);
  });
}
