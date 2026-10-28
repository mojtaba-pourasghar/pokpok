import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

/// یک جمله‌ی گوینده (پوپو). متن همیشه هست؛ فایل صوتی ممکن است هنوز ضبط نشده باشد.
class VoiceLine {
  const VoiceLine({required this.id, required this.text, required this.file, this.group, this.delayMs = 0});

  final String id;
  final String text;

  /// مسیر نسبت به assets/audio، مثل voice/app_splash_welcome.mp3
  final String file;
  final String? group;
  final int delayMs;

  factory VoiceLine.fromJson(Map<String, dynamic> j) => VoiceLine(
    id: j['id'] as String,
    text: j['text'] as String,
    file: j['file'] as String,
    group: j['group'] as String?,
    delayMs: (j['delayMs'] as num?)?.toInt() ?? 0,
  );
}

class ArtAsset {
  const ArtAsset({required this.id, required this.group, required this.path});

  final String id;
  final String group;
  final String path;
}

/// یکی از بازی‌های دیگر سازنده در کافه‌بازار (activities.json ← otherGames)، برای بخش والدین.
class OtherGame {
  const OtherGame({required this.package, required this.title, this.subtitle = '', this.color = '#A77BEF'});

  final String package;
  final String title;
  final String subtitle;
  final String color;

  factory OtherGame.fromJson(Map<String, dynamic> j) => OtherGame(
    package: j['package'] as String,
    title: j['title'] as String,
    subtitle: (j['subtitle'] as String?) ?? '',
    color: (j['color'] as String?) ?? '#A77BEF',
  );
}

/// محتوای متنی پایه: جمله‌های پوپو، فهرست تصویرها (asset_manifest) و «بازی‌های دیگر ما».
/// داستان بازی جداست: lib/game/game_data.dart (assets/content/game.json).
class ContentRepository {
  ContentRepository({required this.voiceLines, required this.art, this.otherGames = const []});

  final Map<String, VoiceLine> voiceLines;
  final Map<String, ArtAsset> art;
  final List<OtherGame> otherGames;

  final _rand = Random();
  final Map<String, String> _lastPick = {};

  static Future<Map<String, dynamic>> _json(AssetBundle b, String path) async =>
      Map<String, dynamic>.from(jsonDecode(await b.loadString(path)) as Map);

  static Future<ContentRepository> load(AssetBundle bundle) async {
    final voiceJ = await _json(bundle, 'assets/content/voice_lines.json');
    final artJ = await _json(bundle, 'assets/content/asset_manifest.json');
    final gamesJ = await _json(bundle, 'assets/content/other_games.json');
    return ContentRepository(
      voiceLines: {for (final l in voiceJ['lines'] as List) l['id'] as String: VoiceLine.fromJson(Map<String, dynamic>.from(l as Map))},
      art: _artIndex((artJ['assets'] as List).cast<Map>()),
      otherGames: [for (final g in (gamesJ['otherGames'] ?? const []) as List) OtherGame.fromJson(Map<String, dynamic>.from(g as Map))],
    );
  }

  /// شناسه ← تصویر. طرح برداری (SVG) جای اصلی است؛ تصویری که فقط رستری دارد هم با مسیر خودش ثبت می‌شود.
  static Map<String, ArtAsset> _artIndex(List<Map> assets) {
    final out = <String, ArtAsset>{};
    for (final a in assets) {
      final path = a['path'] as String;
      if (!path.startsWith('art/')) continue;
      final id = a['id'] as String;
      final isSvg = path.endsWith('.svg');
      if (isSvg || !out.containsKey(id)) out[id] = ArtAsset(id: id, group: a['group'] as String, path: path);
    }
    return out;
  }

  VoiceLine? voice(String? id) => id == null ? null : voiceLines[id];

  /// یک جمله‌ی تصادفی از گروه، بدون تکرار پشت سر هم.
  VoiceLine? pick(String group) {
    final options = voiceLines.values.where((l) => l.group == group).toList();
    if (options.isEmpty) return null;
    if (options.length > 1) options.removeWhere((l) => l.id == _lastPick[group]);
    final l = options[_rand.nextInt(options.length)];
    _lastPick[group] = l.id;
    return l;
  }

  String artPath(String id) => art[id]?.path ?? 'art/animals/rabbit.svg';
}
