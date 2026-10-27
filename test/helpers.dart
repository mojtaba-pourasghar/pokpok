import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:popo/app/app.dart';
import 'package:popo/app/providers.dart';
import 'package:popo/app/router.dart';
import 'package:popo/core/assets/asset_resolver.dart';
import 'package:popo/core/audio/popo_audio.dart';
import 'package:popo/core/content/content.dart';
import 'package:popo/core/storage/local_store.dart';
import 'package:popo/game/game_data.dart';
import 'package:popo/game/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// محیط آزمون: Hive در پوشه‌ی موقت، SharedPreferences ساختگی، محتوای واقعی برنامه، صدای بی‌صدا.
class TestEnv {
  TestEnv._(this.dir, this.store, this.prefs, this.content, this.game, this.bundled, this.audio);

  final Directory dir;
  final LocalStore store;
  final SharedPreferences prefs;
  final ContentRepository content;
  final GameData game;
  final Set<String> bundled;
  final SilentAudio audio;

  static bool _fonts = false;
  static int _n = 0;

  static Future<TestEnv> create({Map<String, Object> prefs = const {'introSeen': true}}) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!_fonts) {
      _fonts = true;
      final loader = FontLoader('Vazirmatn');
      for (final w in ['Regular', 'Medium', 'Bold', 'ExtraBold', 'Black']) {
        loader.addFont(rootBundle.load('assets/fonts/Vazirmatn-$w.ttf'));
      }
      await loader.load();
    }
    final dir = await Directory.systemTemp.createTemp('popo_test');
    // جعبه‌های حافظه‌ای: نوشتن بی‌درنگ کامل می‌شود و آزمون‌ها به دیسک وابسته نیستند.
    final store = await LocalStore.open(path: dir.path, inMemory: true, prefix: 'm${_n++}');
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    final content = await ContentRepository.load(rootBundle);
    final game = await GameData.load(rootBundle);
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return TestEnv._(dir, store, p, content, game, manifest.listAssets().toSet(), SilentAudio());
  }

  List<Override> get overrides => [
    storeProvider.overrideWithValue(store),
    prefsProvider.overrideWithValue(prefs),
    contentProvider.overrideWithValue(content),
    gameDataProvider.overrideWithValue(game),
    // هر ProviderScope نمونه‌ی خودش را می‌گیرد (Riverpod آن را هنگام بستن dispose می‌کند).
    assetsProvider.overrideWith((_) => AssetResolver()..setBundled(bundled)),
    audioProvider.overrideWithValue(audio),
  ];

  ProviderContainer container() => ProviderContainer(overrides: overrides);

  Future<void> dispose() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

/// برنامه‌ی کامل با مسیر شروع دلخواه.
Widget testApp(TestEnv env, {String location = '/home', ProviderContainer? container}) {
  final overrides = [...env.overrides, routerProvider.overrideWith((ref) => buildRouter(ref, initialLocation: location))];
  return container != null
      ? UncontrolledProviderScope(container: container, child: const PopoApp())
      : ProviderScope(overrides: overrides, child: const PopoApp());
}

Future<void> setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// چند فریم جلو می‌رود (انیمیشن‌های تکراری pumpAndSettle را بی‌پایان می‌کنند).
Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

GoRouter routerOf(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Scaffold).first));
