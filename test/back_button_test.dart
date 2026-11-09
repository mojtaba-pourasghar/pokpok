import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/features/chapter/chapter_screen.dart';
import 'package:popo/features/home/home_shell.dart';

import 'helpers.dart';

/// دکمه‌ی برگشت گوشی هیچ‌وقت برنامه را نمی‌بندد.
void main() {
  /// دکمه‌ی برگشت سیستم (همان که اندروید می‌فرستد). true یعنی برنامه آن را گرفت و بسته نمی‌شود.
  Future<bool> systemBack(WidgetTester tester) async {
    final handled = await tester.binding.handlePopRoute();
    await settle(tester, 6);
    return handled;
  }

  testWidgets('back on home stays in the app; back elsewhere goes up, never out', (tester) async {
    final env = (await tester.runAsync(TestEnv.create))!;
    await setSurface(tester, const Size(412, 915));

    await tester.pumpWidget(testApp(env, location: '/home'));
    await settle(tester);
    expect(await systemBack(tester), isTrue, reason: 'home is the root; the app must not close');
    expect(find.byType(HomeShell), findsOneWidget);

    // صفحه‌ای که با go باز شده (صفحه‌ای زیرش نیست): برگشت به صفحه‌ی بالاتر.
    routerOf(tester).go('/play/c1s2');
    await settle(tester);
    expect(await systemBack(tester), isTrue);
    expect(find.byType(ChapterScreen), findsOneWidget, reason: 'section → its chapter map');
    expect(await systemBack(tester), isTrue);
    expect(find.byType(HomeShell), findsOneWidget, reason: 'chapter map → home');
    expect(await systemBack(tester), isTrue);
    expect(find.byType(HomeShell), findsOneWidget);

    // زبانه‌ی دیگر خانه → زبانه‌ی ماجرا
    routerOf(tester).go('/home?tab=me');
    await settle(tester);
    expect(await systemBack(tester), isTrue);
    expect(find.text('فصل‌ها'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    await tester.runAsync(env.dispose);
  });

  testWidgets('back after push pops to the page below', (tester) async {
    final env = (await tester.runAsync(TestEnv.create))!;
    await setSurface(tester, const Size(412, 915));
    await tester.pumpWidget(testApp(env, location: '/home'));
    await settle(tester);
    unawaited(routerOf(tester).push('/chapter/c3'));
    await settle(tester, 10);
    expect(find.byType(ChapterScreen), findsOneWidget);
    expect(await systemBack(tester), isTrue);
    expect(find.byType(ChapterScreen), findsNothing);
    expect(find.byType(HomeShell), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    await tester.runAsync(env.dispose);
  });

  testWidgets('back on the splash screen stays in the app', (tester) async {
    final env = (await tester.runAsync(TestEnv.create))!;
    await setSurface(tester, const Size(412, 915));
    await tester.pumpWidget(testApp(env, location: '/'));
    await settle(tester, 15);
    expect(await systemBack(tester), isTrue);
    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    await tester.runAsync(env.dispose);
  });
}
