import 'dart:convert';

import 'package:flutter/services.dart';

/// داستان پوپو، همان‌طور که tools/content/build_game.py در assets/content/game.json نوشته است:
/// فصل‌ها، بخش‌ها، چیزهایی که کودک می‌سازد، کیت‌های کارگاه ستاره، ابزارهای فروشگاه، ترکیب‌ها و سفارش‌ها.
class GameData {
  GameData({
    required this.friends,
    required this.items,
    required this.chapters,
    required this.kits,
    required this.tools,
    required this.combos,
    required this.orders,
    required this.emoji,
  });

  final Map<String, Friend> friends;
  final Map<String, ItemDef> items;
  final List<ChapterDef> chapters;
  final List<KitDef> kits;
  final List<ToolDef> tools;
  final List<ComboDef> combos;
  final List<OrderDef> orders;

  /// شکلک جایگزین هر تصویر، تا وقتی تصویرش ساخته نشده است.
  final Map<String, String> emoji;

  static Future<GameData> load(AssetBundle bundle) async =>
      GameData.fromJson(jsonDecode(await bundle.loadString('assets/content/game.json')) as Map<String, dynamic>);

  factory GameData.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> m(Object? o) => Map<String, dynamic>.from(o as Map);
    final items = {for (final e in m(j['items']).entries) e.key: ItemDef.fromJson(m(e.value))};
    return GameData(
      friends: {for (final e in m(j['friends']).entries) e.key: Friend.fromJson(e.key, m(e.value))},
      items: items,
      chapters: [for (final (i, c) in (j['chapters'] as List).indexed) ChapterDef.fromJson(m(c), i)],
      kits: [for (final k in j['kits'] as List) KitDef.fromJson(m(k))],
      tools: [for (final t in j['tools'] as List) ToolDef.fromJson(m(t))],
      combos: [for (final c in j['combos'] as List) ComboDef.fromJson(m(c))],
      orders: [for (final o in j['orders'] as List) OrderDef.fromJson(m(o))],
      emoji: {for (final e in m(j['art']).entries) e.key: e.value as String},
    );
  }

  ItemDef item(String id) => items[id]!;
  Friend friend(String id) => friends[id] ?? Friend(id: id, name: id, emoji: '🙂');

  /// هر بخش (فصل، کیت یا دستور ساخت ابزار) با شناسه‌اش.
  late final Map<String, SectionDef> sections = {
    for (final c in chapters)
      for (final s in c.sections) s.id: s,
    for (final k in kits) k.section.id: k.section,
    for (final t in tools)
      for (final r in t.recipes) r.id: r,
  };

  ChapterDef? chapterOf(String sectionId) {
    for (final c in chapters) {
      if (c.sections.any((s) => s.id == sectionId)) return c;
    }
    return null;
  }

  ChapterDef chapter(String id) => chapters.firstWhere((c) => c.id == id);

  int get totalSections => chapters.fold(0, (a, c) => a + c.sections.length);
}

class Friend {
  const Friend({required this.id, required this.name, required this.emoji});

  final String id;
  final String name;
  final String emoji;

  /// تصویر رستری شخصیت.
  String get art => 'art/characters/$id.webp';

  factory Friend.fromJson(String id, Map<String, dynamic> j) => Friend(id: id, name: j['name'] as String, emoji: j['emoji'] as String);
}

/// چیزی که کودک می‌سازد.
class ItemDef {
  const ItemDef({
    required this.id,
    required this.title,
    required this.kind,
    required this.sound,
    required this.use,
    required this.quiz,
    this.taste,
    this.target,
    this.tags = const [],
  });

  final String id;
  final String title;

  /// نوع شیء؛ «امتحان و کشف» از روی آن انتخاب می‌شود: drink، food، tool، light، vehicle، instrument و …
  final String kind;
  final String sound;

  /// یک جمله درباره‌ی کاربرد.
  final String use;
  final String? taste;

  /// تصویری که ابزار رویش کار می‌کند (میخ برای چکش).
  final String? target;
  final List<String> tags;
  final Quiz quiz;

  bool get isFood => kind == 'food' || kind == 'drink';

  factory ItemDef.fromJson(Map<String, dynamic> j) => ItemDef(
    id: j['id'] as String,
    title: j['title'] as String,
    kind: j['kind'] as String,
    sound: j['sound'] as String,
    use: j['use'] as String,
    taste: j['taste'] as String?,
    target: j['target'] as String?,
    tags: [for (final t in (j['tags'] ?? const []) as List) t as String],
    quiz: Quiz.fromJson(Map<String, dynamic>.from(j['quiz'] as Map)),
  );
}

class Quiz {
  const Quiz({required this.question, required this.options, required this.answer});

  final String question;
  final List<({String art, String label})> options;
  final int answer;

  factory Quiz.fromJson(Map<String, dynamic> j) => Quiz(
    question: j['q'] as String,
    options: [for (final o in j['options'] as List) (art: (o as Map)['art'] as String, label: o['label'] as String)],
    answer: (j['answer'] as num).toInt(),
  );
}

/// یک گام بازی: نام موتور و تنظیماتش (همان‌طور که در JSON آمده).
class StepDef {
  const StepDef(this.engine, this.say, this.p);

  final String engine;

  /// متن راهنمای پوپو برای این گام.
  final String say;
  final Map<String, dynamic> p;

  String str(String k, [String def = '']) => (p[k] as String?) ?? def;
  String? opt(String k) => p[k] as String?;
  int integer(String k, [int def = 1]) => (p[k] as num?)?.toInt() ?? def;
  List<String> list(String k) => [for (final x in (p[k] ?? const []) as List) x as String];
  List<Map<String, dynamic>> maps(String k) => [for (final x in (p[k] ?? const []) as List) Map<String, dynamic>.from(x as Map)];

  factory StepDef.fromJson(Map<String, dynamic> j) => StepDef(j['engine'] as String, j['say'] as String, j);
}

class SectionDef {
  const SectionDef({
    required this.id,
    required this.title,
    required this.makes,
    required this.mission,
    required this.steps,
    required this.targetSec,
    this.secret,
  });

  final String id;
  final String title;

  /// شناسه‌ی چیزی که در این بخش ساخته می‌شود.
  final String makes;
  final String mission;
  final List<StepDef> steps;

  /// زمان هدف برای سه ستاره (ثانیه، برای ۷–۸ ساله‌ها).
  final int targetSec;

  /// ابزار فروشگاهی که در این بخش جای پنهانی پیدا می‌کند.
  final String? secret;

  /// همه‌ی چیزهایی که از کوله‌پشتی لازم است.
  List<String> get needs => [
    for (final s in steps)
      if (s.engine == 'use') s.str('need'),
    for (final s in steps)
      if (s.engine == 'serve') ...s.maps('pairs').map((p) => p['item'] as String),
  ];

  factory SectionDef.fromJson(Map<String, dynamic> j) => SectionDef(
    id: j['id'] as String,
    title: j['title'] as String,
    makes: j['makes'] as String,
    mission: j['mission'] as String,
    // شناسه‌ی بخش و شماره‌ی گام برای پیدا کردن جمله‌های گوینده («c2s1.s1.done»).
    steps: [
      for (final (i, s) in (j['steps'] as List).indexed)
        StepDef.fromJson({...Map<String, dynamic>.from(s as Map), '_section': j['id'], '_index': i + 1}),
    ],
    targetSec: (j['targetSec'] as num?)?.toInt() ?? 120,
    secret: j['secret'] as String?,
  );
}

class ChapterDef {
  const ChapterDef({
    required this.id,
    required this.index,
    required this.title,
    required this.friend,
    required this.bg,
    required this.color,
    required this.ambient,
    required this.intro,
    required this.film,
    required this.next,
    required this.sections,
    this.night = false,
  });

  final String id;
  final int index;
  final String title;
  final String friend;
  final String bg;
  final String color;
  final String ambient;
  final String intro;
  final List<String> film;
  final String next;
  final List<SectionDef> sections;
  final bool night;

  String get background => 'art/backgrounds/$bg.webp';

  factory ChapterDef.fromJson(Map<String, dynamic> j, int index) => ChapterDef(
    id: j['id'] as String,
    index: index,
    title: j['title'] as String,
    friend: j['friend'] as String,
    bg: j['bg'] as String,
    color: j['color'] as String,
    ambient: j['ambient'] as String,
    intro: j['intro'] as String,
    film: [for (final f in j['film'] as List) f as String],
    next: (j['next'] ?? '') as String,
    night: (j['night'] as bool?) ?? false,
    sections: [for (final s in j['sections'] as List) SectionDef.fromJson(Map<String, dynamic>.from(s as Map))],
  );
}

/// کیت کارگاه ستاره: وقتی جمع ستاره‌ها به [stars] برسد خودش باز می‌شود.
class KitDef {
  const KitDef(this.section, this.stars);

  final SectionDef section;
  final int stars;

  factory KitDef.fromJson(Map<String, dynamic> j) => KitDef(SectionDef.fromJson(j), (j['stars'] as num).toInt());
}

/// ابزار فروشگاه: با سکه خریده می‌شود و دستورهای ساخت تازه باز می‌کند.
class ToolDef {
  const ToolDef({
    required this.id,
    required this.title,
    required this.price,
    required this.sound,
    required this.safety,
    required this.recipes,
  });

  final String id;
  final String title;
  final int price;
  final String sound;
  final String safety;
  final List<SectionDef> recipes;

  factory ToolDef.fromJson(Map<String, dynamic> j) => ToolDef(
    id: j['id'] as String,
    title: j['title'] as String,
    price: (j['price'] as num).toInt(),
    sound: j['sound'] as String,
    safety: j['safety'] as String,
    recipes: [for (final r in j['recipes'] as List) SectionDef.fromJson(Map<String, dynamic>.from(r as Map))],
  );
}

class ComboDef {
  const ComboDef(this.items, this.text, this.fx);

  final List<String> items;
  final String text;
  final String fx;

  String get id => items.join('+');

  factory ComboDef.fromJson(Map<String, dynamic> j) =>
      ComboDef([for (final i in j['items'] as List) i as String], j['text'] as String, (j['fx'] ?? '') as String);
}

class OrderDef {
  const OrderDef(this.friend, this.tag, this.text);

  final String friend;
  final String tag;
  final String text;

  factory OrderDef.fromJson(Map<String, dynamic> j) => OrderDef(j['friend'] as String, j['tag'] as String, j['text'] as String);
}
