import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/app/localization/fa.dart';
import 'package:popo/app/providers.dart';
import 'package:popo/core/audio/popo_audio.dart';
import 'package:popo/core/content/content.dart';
import 'package:popo/core/widgets/buttons.dart';
import 'package:popo/core/widgets/common.dart';
import 'package:popo/data/models/models.dart';
import 'package:popo/data/repositories/repositories.dart';
import 'package:popo/features/worlds/world_screen.dart';

import 'helpers.dart';

void main() {
  late TestEnv env;

  Future<void> boot(WidgetTester tester, String location, {Size size = const Size(412, 915), Map<String, Object>? prefs}) async {
    env = (await tester.runAsync(() => TestEnv.create(prefs: prefs ?? const {'introSeen': true})))!;
    await setSurface(tester, size);
    await tester.pumpWidget(testApp(env, location: location));
    await settle(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    await tester.runAsync(env.dispose);
  }

  void go(WidgetTester tester, String location) => routerOf(tester).go(location);

  testWidgets('onboarding: start → intro → skip → map, without any registration', (tester) async {
    await boot(tester, '/', prefs: const {});
    expect(find.text('شروع بازی'), findsOneWidget);
    expect(find.text('ورود والدین'), findsOneWidget);
    await tester.tap(find.text('شروع بازی'));
    await settle(tester);
    expect(find.text('رد کردن'), findsOneWidget);
    // گام دوم بدون لمس پوپو باز نمی‌شود، ولی «رد کردن» همیشه هست.
    await tester.tap(find.text('بعدی'));
    await settle(tester);
    await tester.tap(find.text('رد کردن'));
    await settle(tester);
    expect(find.text('خانه‌ی من'), findsOneWidget);
    expect(env.prefs.getBool('introSeen'), isTrue);
    expect(ProfileRepository(env.store).all(), hasLength(1), reason: 'a default profile is created silently');
    expect(env.audio.log, contains('say:app.splash.welcome'));
    await finish(tester);
  });

  testWidgets('map: the layout is right-to-left and a world opens with its first scene', (tester) async {
    await boot(tester, '/map');
    expect(Directionality.of(tester.element(find.text('خانه‌ی من'))), TextDirection.rtl);
    await tester.tap(find.text('طبیعت و حیوانات'));
    await settle(tester, 20);
    expect(find.byType(WorldScreen), findsOneWidget);
    expect(find.text('طبیعت و حیوانات · جنگل'), findsOneWidget);
    await tester.tap(find.text('مزرعه'));
    await settle(tester);
    expect(find.text('طبیعت و حیوانات · مزرعه'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(WorldScreen)));
    expect(container.read(progressProvider).stickers, contains('world.nature'));
    expect(container.read(progressProvider).lastWorld, 'nature');
    await finish(tester);
  });

  testWidgets('object interaction is real and survives an app restart', (tester) async {
    final semantics = tester.ensureSemantics();
    await boot(tester, '/world/home');
    await tester.tap(find.bySemanticsLabel('چراغ'));
    await settle(tester, 4);
    expect(env.audio.log, contains('play:audio/sfx/light_switch.mp3'));

    final ball = find.bySemanticsLabel('توپ');
    final before = tester.getCenter(ball);
    await tester.drag(ball, const Offset(-150, -200));
    await settle(tester, 4);
    final after = tester.getCenter(ball);
    expect((after - before).distance, greaterThan(100));

    // «بستن» برنامه و باز کردن دوباره با همان ذخیره‌سازی
    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    await tester.pumpWidget(testApp(env, location: '/world/home'));
    await settle(tester);
    final saved = SceneRepository(env.store).load(ProfileRepository(env.store).activeId ?? '_guest', 'home.living');
    expect(saved['lamp']!.on, isTrue);
    expect((tester.getCenter(find.bySemanticsLabel('توپ')) - after).distance, lessThan(2));
    semantics.dispose();
    await finish(tester);
  });

  testWidgets('role-play: shopping list completed → celebration and sticker', (tester) async {
    final semantics = tester.ensureSemantics();
    await boot(tester, '/play/play.shop');
    for (final item in ['سیب', 'شیر', 'نان']) {
      final from = tester.getCenter(find.bySemanticsLabel(item));
      final to = tester.getCenter(find.bySemanticsLabel('سبد خرید'));
      await tester.dragFrom(from, to - from);
      await settle(tester, 4);
    }
    await settle(tester);
    expect(find.text('آفرین!'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.text('آفرین!')));
    expect(container.read(progressProvider).stickers, contains('shopper'));
    expect(container.read(progressProvider).completed, contains('play.shop'));
    semantics.dispose();
    await finish(tester);
  });

  testWidgets('drawing: strokes, undo, save to the gallery, reopen', (tester) async {
    final semantics = tester.ensureSemantics();
    await boot(tester, '/art');
    final canvas = find.bySemanticsLabel('بوم نقاشی؛ با انگشت بکش');
    await tester.drag(canvas, const Offset(120, 80));
    await settle(tester, 2);
    await tester.drag(canvas, const Offset(-60, 100));
    await settle(tester, 2);
    final profile = ProfileRepository(env.store).activeId ?? '_guest';
    expect(ArtworkRepository(env.store).draft(profile)!.strokes, hasLength(2), reason: 'draft is saved after every stroke');
    await tester.tap(find.bySemanticsLabel('برگرداندن'));
    await settle(tester, 2);
    expect(ArtworkRepository(env.store).draft(profile)!.strokes, hasLength(1));
    await tester.tap(find.bySemanticsLabel('ذخیره'));
    await settle(tester);
    final saved = ArtworkRepository(env.store).all(profile).where((a) => a.id != '_draft').toList();
    expect(saved, hasLength(1));
    expect(saved.single.strokes, hasLength(1));
    go(tester, '/art/gallery');
    await settle(tester);
    expect(find.text('نقاشی تازه'), findsOneWidget);
    semantics.dispose();
    await finish(tester);
  });

  testWidgets('parent area is protected; the right digits open it', (tester) async {
    await boot(tester, '/map');
    go(tester, '/parent');
    await settle(tester);
    expect(find.text('فقط برای بزرگ‌ترها'), findsOneWidget);
    expect(find.text('پنل والدین'), findsNothing);
    go(tester, '/settings');
    await settle(tester);
    expect(find.text('فقط برای بزرگ‌ترها'), findsOneWidget);

    final words = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').firstWhere((t) => t.split('، ').length == 3);
    // یک بار اشتباه
    await tester.tap(find.byKey(ValueKey('gate-${words.startsWith(faNumberWords[1]) ? 2 : 1}')));
    await tester.tap(find.byKey(const ValueKey('gate-9')));
    await tester.tap(find.byKey(const ValueKey('gate-9')));
    await settle(tester, 3);
    final again = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').firstWhere((t) => t.split('، ').length == 3);
    for (final w in again.split('، ')) {
      await tester.tap(find.byKey(ValueKey('gate-${faNumberWords.indexOf(w)}')));
      await tester.pump();
    }
    await settle(tester);
    expect(find.text('تنظیمات'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('sound settings are applied to the audio engine and saved per profile', (tester) async {
    await boot(tester, '/map');
    final container = ProviderScope.containerOf(tester.element(find.text('خانه‌ی من')));
    container.read(parentGateProvider.notifier).unlock();
    go(tester, '/settings');
    await settle(tester);
    final musicRow = find.ancestor(of: find.text('موسیقی پس‌زمینه'), matching: find.byType(SettingRow));
    await tester.tap(find.descendant(of: musicRow, matching: find.byType(Switch)));
    await settle(tester, 3);
    expect(env.audio.settings.musicOn, isFalse);
    expect(env.audio.settings.volume(AudioChannel.music), 0);
    final id = container.read(activeIdProvider);
    expect(SettingsRepository(env.store).load(id).musicOn, isFalse);
    await finish(tester);
  });

  testWidgets('profiles keep separate settings and progress', (tester) async {
    await boot(tester, '/map');
    final container = ProviderScope.containerOf(tester.element(find.text('خانه‌ی من')));
    final n = container.read(profilesProvider.notifier);
    final a = await tester.runAsync(() => n.create(name: 'آرا', avatar: 'cat', ageBand: AgeBand.toddler));
    await tester.runAsync(() => container.read(progressProvider.notifier).addSticker('chef'));
    await tester.runAsync(() => container.read(settingsProvider.notifier).update((s) => s.copyWith(reducedMotion: true)));
    final b = await tester.runAsync(() => n.create(name: 'نیما', avatar: 'dog', ageBand: AgeBand.early));
    expect(container.read(activeIdProvider), b!.id);
    expect(container.read(progressProvider).stickers, isEmpty);
    expect(container.read(settingsProvider).reducedMotion, isFalse);
    await tester.runAsync(() => n.select(a!.id));
    expect(container.read(progressProvider).stickers, {'chef'});
    expect(container.read(settingsProvider).reducedMotion, isTrue);
    go(tester, '/profiles');
    await settle(tester);
    expect(find.text('آرا'), findsOneWidget);
    expect(find.text('نیما'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('large text and reduced motion: key screens still fit a small phone', (tester) async {
    for (final r in ['/map', '/world/home', '/art', '/music', '/build', '/library', '/rewards']) {
      env = (await tester.runAsync(() => TestEnv.create()))!;
      await SettingsRepository(env.store).save('_guest', const ProfileSettings(largeText: true, reducedMotion: true));
      await setSurface(tester, const Size(320, 640));
      await tester.pumpWidget(testApp(env, location: r));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: r);
      final mq = MediaQuery.of(tester.element(find.byType(Scaffold).first));
      expect(mq.disableAnimations, isTrue);
      expect(mq.textScaler.scale(10), greaterThan(11));
      await finish(tester);
    }
  });

  testWidgets('captions show what Popo says when sound is off', (tester) async {
    final audio = SilentAudio(captions: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioProvider.overrideWithValue(audio),
          settingsProvider.overrideWithBuild((_, _) => const ProfileSettings(voiceOn: false)),
        ],
        child: const MaterialApp(home: Scaffold(body: CaptionBubble())),
      ),
    );
    await audio.say(const VoiceLine(id: 'x', text: 'سلام! من پوپو هستم.', file: 'voice/x.mp3'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('سلام! من پوپو هستم.'), findsOneWidget);
  });

  testWidgets('PButton: large target, plays a sound and calls back; disabled does nothing', (tester) async {
    final audio = SilentAudio();
    var taps = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [audioProvider.overrideWithValue(audio)],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PButton(label: 'بزن', onPressed: () => taps++),
                const PButton(label: 'غیرفعال', onPressed: null),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(PButton).first).height, greaterThanOrEqualTo(64));
    await tester.tap(find.text('بزن'));
    await tester.tap(find.text('غیرفعال'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
    expect(audio.log.where((l) => l.startsWith('ui:')), hasLength(1));
  });

  testWidgets('state views cover loading, empty, offline, error, success and pending', (tester) async {
    for (final s in ViewState.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateView(state: s, message: 'پیام ${s.name}'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('پیام ${s.name}'), findsOneWidget);
    }
  });
}
