import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/assets/asset_resolver.dart';
import 'core/audio/just_audio_service.dart';
import 'core/content/content.dart';
import 'core/storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Hive.initFlutter('popo');
  final store = await LocalStore.open();
  final prefs = await SharedPreferences.getInstance();
  final content = await ContentRepository.load(rootBundle);
  final assets = AssetResolver();
  await assets.init(rootBundle);

  runApp(
    ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
        prefsProvider.overrideWithValue(prefs),
        contentProvider.overrideWithValue(content),
        assetsProvider.overrideWith((_) => assets),
        audioProvider.overrideWithValue(JustAudioService(assets)),
      ],
      child: const PopoApp(),
    ),
  );
}
