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
import 'package:popo/app/app.dart';
import 'package:popo/app/router.dart';
import 'package:popo/features/chapter/chapter_screen.dart';
import 'package:popo/features/home/home_shell.dart';
import 'package:popo/features/play/discover.dart';
import 'package:popo/game/engines/backpack_engines.dart';
import 'package:popo/game/engines/drag_engines.dart';
import 'package:popo/game/engines/tap_engines.dart';
import 'package:popo/game/game_data.dart';
import 'package:popo/game/game_state.dart';
import 'package:popo/ui/clay.dart';

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

  testWidgets('onboarding: start → intro → skip → home with chapters, without any registration', (tester) async {
    await boot(tester, '/', prefs: const {});
    expect(find.text('شروع بازی'), findsOneWidget);
    expect(find.text('ورود والدین'), findsOneWidget);
    await tester.tap(find.text('شروع بازی'));
    await settle(tester);
    expect(find.text('رد کردن'), findsOneWidget);
    await tester.tap(find.text('بعدی'));
    await settle(tester);
    await tester.tap(find.text('رد کردن'));
    await settle(tester);
    expect(find.text('فصل‌ها'), findsOneWidget);
    expect(env.prefs.getBool('introSeen'), isTrue);
    expect(ProfileRepository(env.store).all(), hasLength(1), reason: 'a default profile is created silently');
    expect(env.audio.log, contains('say:app.splash.welcome'));
    await finish(tester);
  });

  testWidgets('home: right-to-left, daily bonus once, chapter 1 opens and later chapters are locked', (tester) async {
    final semantics = tester.ensureSemantics();
    await boot(tester, '/home', prefs: const {'introSeen': true});
    // جایزه‌ی روزانه‌ی اول
    expect(find.text('جایزه‌ی امروز!'), findsOneWidget);
    expect(env.audio.log, contains('say:game.daily'));
    await tester.tap(find.text('جایزه‌ی امروز!'));
    await settle(tester);
    expect(find.text('جایزه‌ی امروز!'), findsNothing);
    expect(Directionality.of(tester.element(find.text('فصل‌ها'))), TextDirection.rtl);
    final container = ProviderScope.containerOf(tester.element(find.text('فصل‌ها')));
    expect(container.read(gameProvider).coins, 10);
    final gate = container.read(gateProvider);
    final data = container.read(gameDataProvider);
    expect(gate.chapterOpen(data.chapters[0]), isTrue);
    expect(gate.chapterOpen(data.chapters[1]), gate.open, reason: 'chapter 2 waits for chapter 1 (open only in debug)');
    await tester.tap(find.text('آشپزخانه‌ی خاله خرسی').first);
    await settle(tester, 20);
    expect(find.byType(ChapterScreen), findsOneWidget);
    expect(env.audio.log, contains('say:c1.intro'));
    await tester.tap(find.bySemanticsLabel(RegExp('بخش ۱: آب‌پرتقال')));
    await settle(tester, 20);
    expect(find.text('شروع کنیم!'), findsOneWidget);
    expect(env.audio.log, contains('say:c1s1.mission'));
    semantics.dispose();
    await finish(tester);
  });

  testWidgets('a whole section: steps → made → discover → quiz → play → backpack and stars', (tester) async {
    env = (await tester.runAsync(() => TestEnv.create()))!;
    // یک بخش کوتاه با یک گام «ضربه»، تا کل چرخه در آزمون اجرا شود.
    final real = env.game;
    final juice = real.items['juice']!;
    final data = GameData(
      friends: real.friends,
      items: real.items,
      chapters: [
        const ChapterDef(
          id: 'c1',
          index: 0,
          title: 'آزمون',
          friend: 'bear',
          bg: 'kitchen',
          color: '#FF8A1F',
          ambient: 'audio/ambient/garden.mp3',
          intro: 'آزمون',
          film: ['آب‌میوه'],
          next: '',
          sections: [
            SectionDef(
              id: 'c1s1',
              title: 'آب‌پرتقال',
              makes: 'juice',
              mission: 'آزمون',
              targetSec: 100,
              steps: [
                StepDef('tap', 'بزن', {
                  'engine': 'tap',
                  'target': 'orange',
                  'count': 2,
                  'sound': 'audio/sfx/squeak.mp3',
                  '_section': 'c1s1',
                  '_index': 1,
                }),
              ],
            ),
          ],
        ),
      ],
      kits: const [],
      tools: const [],
      combos: const [],
      orders: const [],
      emoji: real.emoji,
    );
    await setSurface(tester, const Size(412, 915));
    final overrides = [
      for (final o in env.overrides) o,
      routerProvider.overrideWith((ref) => buildRouter(ref, initialLocation: '/play/c1s1')),
    ];
    final container = ProviderContainer(
      overrides: [...overrides.where((o) => !identical(o, overrides[3])), gameDataProvider.overrideWithValue(data)],
    );
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const PopoApp()));
    await settle(tester);
    await tester.tap(find.text('شروع کنیم!'));
    await settle(tester, 6);
    expect(find.byType(TapEngine), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byType(TapEngine));
      await settle(tester, 2);
    }
    await settle(tester, 10);
    expect(find.text('آب‌پرتقال آماده شد!'), findsOneWidget);
    expect(env.audio.log, contains('play:audio/sfx/squeak.mp3'));
    await tester.tap(find.text('امتحانش کنیم!'));
    await settle(tester, 6);
    await tester.tap(find.byType(ItemShowcase));
    await settle(tester, 20);
    expect(env.audio.log, contains('say:item.juice.taste'), reason: 'tasting food says how it tastes');
    await tester.tap(find.text('فهمیدم!'));
    await settle(tester, 6);
    expect(env.audio.log, contains('say:item.juice.quiz'));
    await tester.tap(find.text(juice.quiz.options[juice.quiz.answer].label));
    await settle(tester, 30);
    await tester.tap(find.text('بگذارش در کوله‌پشتی'));
    await settle(tester, 20);
    final g = container.read(gameProvider);
    expect(g.backpack, contains('juice'));
    expect(g.starsOf('c1s1'), 3);
    expect(g.coins, greaterThan(0));
    expect(find.text('عالی!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await settle(tester, 3);
    container.dispose();
    await tester.runAsync(env.dispose);
  });

  testWidgets('an obstacle needs the right thing from the backpack; the wrong one explains itself', (tester) async {
    final semantics = tester.ensureSemantics();
    await boot(tester, '/play/c2s1');
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    await tester.tap(find.text('شروع کنیم!'));
    await settle(tester, 6);
    expect(find.byType(UseEngine), findsOneWidget);
    expect(find.text('کوله‌پشتی پوپو'), findsOneWidget);
    // آب‌پرتقال هنوز ساخته نشده؛ نسخه‌ی قرضی در کوله هست.
    expect(find.byTooltip('قرضی از دوستان'), findsOneWidget);
    Finder inTray(String id) => find.byWidgetPredicate((w) => w is GameArt && w.id == id && w.size == 78);
    final juice = inTray('juice');
    final hammer = inTray('hammer');
    final spot = tester.getCenter(find.byType(UseEngine)) - const Offset(0, 120);
    await tester.timedDragFrom(tester.getCenter(hammer), spot - tester.getCenter(hammer), const Duration(milliseconds: 400));
    await settle(tester, 6);
    expect(env.audio.log, contains('say:c2s1.s1.why'));
    expect(env.audio.log, contains('say:item.hammer.use'));
    await tester.timedDragFrom(tester.getCenter(juice), spot - tester.getCenter(juice), const Duration(milliseconds: 400));
    await settle(tester, 25);
    expect(env.audio.log, contains('say:c2s1.s1.done'));
    expect(find.byType(AssembleEngine), findsOneWidget, reason: 'next step');
    expect(container.read(gameProvider).backpack, isEmpty, reason: 'nothing is finished yet');
    semantics.dispose();
    await finish(tester);
  });

  testWidgets('parent area is protected; the right digits open it', (tester) async {
    await boot(tester, '/home');
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
    await boot(tester, '/home');
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
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
    await boot(tester, '/home');
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final n = container.read(profilesProvider.notifier);
    final a = await tester.runAsync(() => n.create(name: 'آرا', avatar: 'cat', ageBand: AgeBand.toddler));
    await tester.runAsync(() => container.read(gameProvider.notifier).addCoins(40));
    await tester.runAsync(() => container.read(settingsProvider.notifier).update((s) => s.copyWith(reducedMotion: true)));
    final b = await tester.runAsync(() => n.create(name: 'نیما', avatar: 'dog', ageBand: AgeBand.early));
    expect(container.read(activeIdProvider), b!.id);
    expect(container.read(gameProvider).coins, 0);
    expect(container.read(settingsProvider).reducedMotion, isFalse);
    await tester.runAsync(() => n.select(a!.id));
    expect(container.read(gameProvider).coins, 40);
    expect(container.read(settingsProvider).reducedMotion, isTrue);
    go(tester, '/profiles');
    await settle(tester);
    expect(find.text('آرا'), findsOneWidget);
    expect(find.text('نیما'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('large text and reduced motion: key screens still fit a small phone', (tester) async {
    for (final r in ['/home', '/home?tab=workshop', '/home?tab=playroom', '/home?tab=me', '/chapter/c1', '/play/c1s1']) {
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
