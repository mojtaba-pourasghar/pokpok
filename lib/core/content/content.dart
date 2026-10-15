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

class WorldDef {
  const WorldDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.art,
    required this.route,
    required this.mapX,
    required this.mapY,
    this.scenes = const [],
    this.voice,
    this.card,
  });

  final String id;
  final String title;
  final String subtitle;
  final String art;
  final String route;

  /// جای جهان روی نقشه (۰ تا ۱).
  final double mapX, mapY;
  final List<String> scenes;
  final String? voice;

  /// تصویر کارت نقشه (رستری)؛ اگر نباشد [art] نشان داده می‌شود.
  final String? card;

  factory WorldDef.fromJson(Map<String, dynamic> j) => WorldDef(
    id: j['id'] as String,
    title: j['title'] as String,
    subtitle: (j['subtitle'] ?? '') as String,
    art: j['art'] as String,
    route: j['route'] as String,
    mapX: (j['mapX'] as num).toDouble(),
    mapY: (j['mapY'] as num).toDouble(),
    scenes: [for (final s in (j['scenes'] ?? const []) as List) s as String],
    voice: j['voice'] as String?,
    card: j['card'] as String?,
  );
}

/// واکنش یک شیء به لمس.
class TapAction {
  const TapAction({this.anim, this.sound, this.toggle = false, this.advance = false, this.say, this.burst = true});

  final String? anim;
  final String? sound;
  final bool toggle;

  /// رفتن به مرحله‌ی بعدی تصویر (states)، چرخه‌ای.
  final bool advance;
  final String? say;
  final bool burst;

  factory TapAction.fromJson(Map<String, dynamic> j) => TapAction(
    anim: j['anim'] as String?,
    sound: j['sound'] as String?,
    toggle: (j['toggle'] as bool?) ?? false,
    advance: (j['advance'] as bool?) ?? false,
    say: j['say'] as String?,
    burst: (j['burst'] as bool?) ?? true,
  );
}

/// پس از واکنش، شیء رهاشده چه می‌شود.
enum AfterDrop {
  /// همان‌جا که رها شد می‌ماند (میوه روی بشقاب).
  stay,

  /// به جای قبلی‌اش برمی‌گردد (غذا دادن به حیوان).
  back,

  /// ناپدید می‌شود (مواد در قابلمه، اسباب‌بازی در سبد).
  hide,
}

/// واکنش یک شیء وقتی شیء دیگری با برچسب [tag] رویش رها شود.
class DropReaction {
  const DropReaction({
    required this.tag,
    this.anim = 'jump',
    this.sound,
    this.say,
    this.then = AfterDrop.stay,
    this.advance = false,
    this.turnOn = false,
  });

  final String tag;
  final String anim;
  final String? sound;
  final String? say;
  final AfterDrop then;

  /// مقصد یک مرحله جلو می‌رود (دانه ← جوانه ← گل).
  final bool advance;
  final bool turnOn;

  factory DropReaction.fromJson(Map<String, dynamic> j) => DropReaction(
    tag: j['tag'] as String,
    anim: (j['anim'] ?? 'jump') as String,
    sound: j['sound'] as String?,
    say: j['say'] as String?,
    then: switch (j['then']) {
      'hide' => AfterDrop.hide,
      'return' => AfterDrop.back,
      _ => AfterDrop.stay,
    },
    advance: (j['advance'] as bool?) ?? false,
    turnOn: (j['turnOn'] as bool?) ?? false,
  );
}

enum DragMode { none, free, path }

class SceneObjectDef {
  const SceneObjectDef({
    required this.id,
    required this.art,
    required this.x,
    required this.y,
    required this.size,
    this.label,
    this.tags = const [],
    this.drag = DragMode.none,
    this.path,
    this.tap,
    this.accepts = const [],
    this.states = const [],
    this.glow = false,
    this.hit = const Rect.fromLTRB(.1, .1, .9, .95),
    this.z = 0,
    this.flip = false,
    this.persist = true,
  });

  final String id;

  /// شناسه‌ی تصویر در art_manifest.json.
  final String art;

  /// برچسب فارسی برای خواننده‌ی صفحه (دسترس‌پذیری).
  final String? label;

  /// مرکز شیء نسبت به صحنه (۰ تا ۱).
  final double x, y;

  /// اندازه نسبت به ضلع کوچک‌تر صحنه.
  final double size;
  final List<String> tags;
  final DragMode drag;
  final String? path;
  final TapAction? tap;
  final List<DropReaction> accepts;

  /// تصویرهای مرحله‌ها (برای رشد گیاه و…)؛ مرحله‌ی ۰ همان [art] است اگر خالی باشد.
  final List<String> states;

  /// وقتی روشن است دورش نور می‌تابد (چراغ، تلویزیون).
  final bool glow;

  /// ناحیه‌ی لمس نسبت به جعبه‌ی شیء (۰ تا ۱).
  final Rect hit;
  final int z;
  final bool flip;
  final bool persist;

  String artFor(int stage) => states.isEmpty ? art : states[stage.clamp(0, states.length - 1)];

  factory SceneObjectDef.fromJson(Map<String, dynamic> j) {
    final dragRaw = (j['drag'] ?? 'none') as String;
    DragMode drag = DragMode.none;
    String? path;
    if (dragRaw == 'free') drag = DragMode.free;
    if (dragRaw.startsWith('path:')) {
      drag = DragMode.path;
      path = dragRaw.substring(5);
    }
    final hit = (j['hit'] as List?)?.map((v) => (v as num).toDouble()).toList();
    return SceneObjectDef(
      id: j['id'] as String,
      art: j['art'] as String,
      label: j['label'] as String?,
      x: (j['x'] as num).toDouble(),
      y: (j['y'] as num).toDouble(),
      size: (j['size'] as num?)?.toDouble() ?? .22,
      tags: [for (final t in (j['tags'] ?? const []) as List) t as String],
      drag: drag,
      path: path,
      tap: j['tap'] == null ? null : TapAction.fromJson(Map<String, dynamic>.from(j['tap'] as Map)),
      accepts: [for (final a in (j['accepts'] ?? const []) as List) DropReaction.fromJson(Map<String, dynamic>.from(a as Map))],
      states: [for (final s in (j['states'] ?? const []) as List) s as String],
      glow: (j['glow'] as bool?) ?? false,
      hit: hit == null || hit.length != 4 ? const Rect.fromLTRB(.1, .1, .9, .95) : Rect.fromLTRB(hit[0], hit[1], hit[2], hit[3]),
      z: (j['z'] as num?)?.toInt() ?? 0,
      flip: (j['flip'] as bool?) ?? false,
      persist: (j['persist'] as bool?) ?? true,
    );
  }
}

/// هدف یک فعالیت نقش‌آفرینی (مثلاً «سه میوه در سبد»).
class SceneGoal {
  const SceneGoal({required this.target, this.tag, this.count = 1, this.stage, this.on});

  final String target;
  final String? tag;
  final int count;
  final int? stage;
  final bool? on;

  factory SceneGoal.fromJson(Map<String, dynamic> j) => SceneGoal(
    target: j['target'] as String,
    tag: j['tag'] as String?,
    count: (j['count'] as num?)?.toInt() ?? 1,
    stage: (j['stage'] as num?)?.toInt(),
    on: j['on'] as bool?,
  );
}

class SceneDef {
  const SceneDef({
    required this.id,
    required this.world,
    required this.title,
    required this.icon,
    required this.background,
    required this.objects,
    this.paths = const {},
    this.goals = const [],
    this.sticker,
    this.intro,
    this.done,
    this.ambient,
    this.hint,
    this.want = const [],
  });

  final String id;
  final String world;
  final String title;
  final String icon;

  /// شناسه‌ی نقاش پس‌زمینه (lib/features/worlds/backgrounds).
  final String background;
  final List<SceneObjectDef> objects;

  /// مسیرهای حرکت (مثل جاده) با نقطه‌های نسبی.
  final Map<String, List<Offset>> paths;
  final List<SceneGoal> goals;
  final String? sticker;
  final String? intro;
  final String? done;
  final String? ambient;

  /// راهنمای کوتاه زیر عنوان برای فعالیت‌های هدف‌دار.
  final String? hint;

  /// فهرست خرید (شناسه‌ی اشیایی که باید پیدا شوند)، برای نمایش در بالای صحنه.
  final List<String> want;

  bool get hasGoals => goals.isNotEmpty;

  factory SceneDef.fromJson(Map<String, dynamic> j) => SceneDef(
    id: j['id'] as String,
    world: j['world'] as String,
    title: j['title'] as String,
    icon: j['icon'] as String,
    background: j['background'] as String,
    objects: [for (final o in (j['objects'] ?? const []) as List) SceneObjectDef.fromJson(Map<String, dynamic>.from(o as Map))],
    paths: {
      for (final e in ((j['paths'] ?? const {}) as Map).entries)
        e.key as String: [for (final p in e.value as List) Offset(((p as List)[0] as num).toDouble(), (p[1] as num).toDouble())],
    },
    goals: [for (final g in (j['goals'] ?? const []) as List) SceneGoal.fromJson(Map<String, dynamic>.from(g as Map))],
    sticker: j['sticker'] as String?,
    intro: j['intro'] as String?,
    done: j['done'] as String?,
    ambient: j['ambient'] as String?,
    hint: j['hint'] as String?,
    want: [for (final w in (j['want'] ?? const []) as List) w as String],
  );
}

class ActivityDef {
  const ActivityDef({
    required this.id,
    required this.title,
    required this.category,
    required this.art,
    required this.route,
    this.minAge = 2,
  });

  final String id;
  final String title;
  final String category;
  final String art;
  final String route;
  final int minAge;

  factory ActivityDef.fromJson(Map<String, dynamic> j) => ActivityDef(
    id: j['id'] as String,
    title: j['title'] as String,
    category: j['category'] as String,
    art: j['art'] as String,
    route: j['route'] as String,
    minAge: (j['minAge'] as num?)?.toInt() ?? 2,
  );
}

class CategoryDef {
  const CategoryDef({required this.id, required this.title, required this.art, required this.color});

  final String id;
  final String title;
  final String art;
  final Color color;
}

class StickerDef {
  const StickerDef({required this.id, required this.art, required this.title});

  final String id;
  final String art;
  final String title;
}

class ArtAsset {
  const ArtAsset({required this.id, required this.group, required this.path});

  final String id;
  final String group;
  final String path;
}

/// همه‌ی محتوای متنی برنامه (جهان‌ها، صحنه‌ها، فعالیت‌ها، جمله‌ها)، بارگذاری‌شده از assets/content.
/// برای افزودن جهان یا صحنه‌ی تازه فقط فایل JSON اضافه می‌شود، نه کد.
class ContentRepository {
  ContentRepository({
    required this.worlds,
    required this.scenes,
    required this.activities,
    required this.categories,
    required this.stickers,
    required this.voiceLines,
    required this.art,
  });

  final List<WorldDef> worlds;
  final Map<String, SceneDef> scenes;
  final List<ActivityDef> activities;
  final List<CategoryDef> categories;
  final Map<String, StickerDef> stickers;
  final Map<String, VoiceLine> voiceLines;
  final Map<String, ArtAsset> art;

  final _rand = Random();
  final Map<String, String> _lastPick = {};

  static Future<Map<String, dynamic>> _json(AssetBundle b, String path) async =>
      Map<String, dynamic>.from(jsonDecode(await b.loadString(path)) as Map);

  static Future<ContentRepository> load(AssetBundle bundle) async {
    final worldsJ = await _json(bundle, 'assets/content/worlds.json');
    final actJ = await _json(bundle, 'assets/content/activities.json');
    final voiceJ = await _json(bundle, 'assets/content/voice_lines.json');
    final artJ = await _json(bundle, 'assets/content/asset_manifest.json');
    final scenes = <String, SceneDef>{};
    for (final file in (worldsJ['sceneFiles'] as List).cast<String>()) {
      final j = await _json(bundle, 'assets/content/scenes/$file');
      for (final s in (j['scenes'] as List)) {
        final def = SceneDef.fromJson(Map<String, dynamic>.from(s as Map));
        scenes[def.id] = def;
      }
    }
    return ContentRepository(
      worlds: [for (final w in worldsJ['worlds'] as List) WorldDef.fromJson(Map<String, dynamic>.from(w as Map))],
      scenes: scenes,
      activities: [for (final a in actJ['activities'] as List) ActivityDef.fromJson(Map<String, dynamic>.from(a as Map))],
      categories: [
        for (final c in actJ['categories'] as List)
          CategoryDef(
            id: c['id'] as String,
            title: c['title'] as String,
            art: c['art'] as String,
            color: Color(int.parse('FF${(c['color'] as String).substring(1)}', radix: 16)),
          ),
      ],
      stickers: {
        for (final s in actJ['stickers'] as List)
          s['id'] as String: StickerDef(id: s['id'] as String, art: s['art'] as String, title: s['title'] as String),
      },
      voiceLines: {for (final l in voiceJ['lines'] as List) l['id'] as String: VoiceLine.fromJson(Map<String, dynamic>.from(l as Map))},
      art: _artIndex((artJ['assets'] as List).cast<Map>()),
    );
  }

  /// شناسه ← تصویر. طرح برداری (SVG) جای اصلی است؛ تصویری که فقط رستری دارد (کارت‌ها،
  /// پس‌زمینه‌ها، حالت‌های پوپو) هم با مسیر WebP خودش ثبت می‌شود.
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

  WorldDef? world(String id) {
    for (final w in worlds) {
      if (w.id == id) return w;
    }
    return null;
  }

  List<SceneDef> scenesOf(String worldId) => [
    for (final id in world(worldId)?.scenes ?? const <String>[])
      if (scenes[id] != null) scenes[id]!,
  ];

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

  String artPath(String id) => art[id]?.path ?? 'art/nature/cloud.svg';

  ActivityDef? activity(String id) {
    for (final a in activities) {
      if (a.id == id) return a;
    }
    return null;
  }
}
