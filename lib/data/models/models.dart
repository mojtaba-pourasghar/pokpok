import 'dart:ui';

/// گروه سنی کودک؛ دشواری پازل‌ها و تعداد قطعه‌ها از این می‌آید.
enum AgeBand {
  toddler('۲ تا ۴ سال', 2),
  preschool('۴ تا ۶ سال', 4),
  early('۶ تا ۸ سال', 6);

  const AgeBand(this.label, this.minAge);
  final String label;
  final int minAge;

  static AgeBand parse(String? s) => AgeBand.values.firstWhere((b) => b.name == s, orElse: () => AgeBand.preschool);
}

class ChildProfile {
  const ChildProfile({required this.id, required this.name, required this.avatar, required this.ageBand, required this.createdAt});

  final String id;
  final String name;

  /// شناسه‌ی تصویر نماد (از art_manifest)، مثلاً «rabbit».
  final String avatar;
  final AgeBand ageBand;
  final DateTime createdAt;

  ChildProfile copyWith({String? name, String? avatar, AgeBand? ageBand}) =>
      ChildProfile(id: id, name: name ?? this.name, avatar: avatar ?? this.avatar, ageBand: ageBand ?? this.ageBand, createdAt: createdAt);

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'ageBand': ageBand.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
    id: j['id'] as String,
    name: (j['name'] ?? '') as String,
    avatar: (j['avatar'] ?? 'bunny') as String,
    ageBand: AgeBand.parse(j['ageBand'] as String?),
    createdAt: DateTime.tryParse((j['createdAt'] ?? '') as String) ?? DateTime.now(),
  );
}

enum AudioChannel { music, effects, ambient, voice }

/// تنظیمات هر کودک (جدا برای هر نمایه).
class ProfileSettings {
  const ProfileSettings({
    this.music = .55,
    this.effects = .9,
    this.ambient = .6,
    this.voice = 1,
    this.musicOn = true,
    this.effectsOn = true,
    this.ambientOn = true,
    this.voiceOn = true,
    this.reducedMotion = false,
    this.largeText = false,
    this.captions = true,
    this.language = 'fa',
  });

  final double music, effects, ambient, voice;
  final bool musicOn, effectsOn, ambientOn, voiceOn;
  final bool reducedMotion;
  final bool largeText;

  /// زیرنویس جمله‌های پوپو، تا بدون صدا هم کار قابل فهم باشد.
  final bool captions;
  final String language;

  double volume(AudioChannel c) => switch (c) {
    AudioChannel.music => musicOn ? music : 0,
    AudioChannel.effects => effectsOn ? effects : 0,
    AudioChannel.ambient => ambientOn ? ambient : 0,
    AudioChannel.voice => voiceOn ? voice : 0,
  };

  ProfileSettings copyWith({
    double? music,
    double? effects,
    double? ambient,
    double? voice,
    bool? musicOn,
    bool? effectsOn,
    bool? ambientOn,
    bool? voiceOn,
    bool? reducedMotion,
    bool? largeText,
    bool? captions,
    String? language,
  }) => ProfileSettings(
    music: music ?? this.music,
    effects: effects ?? this.effects,
    ambient: ambient ?? this.ambient,
    voice: voice ?? this.voice,
    musicOn: musicOn ?? this.musicOn,
    effectsOn: effectsOn ?? this.effectsOn,
    ambientOn: ambientOn ?? this.ambientOn,
    voiceOn: voiceOn ?? this.voiceOn,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    largeText: largeText ?? this.largeText,
    captions: captions ?? this.captions,
    language: language ?? this.language,
  );

  Map<String, Object?> toJson() => {
    'music': music,
    'effects': effects,
    'ambient': ambient,
    'voice': voice,
    'musicOn': musicOn,
    'effectsOn': effectsOn,
    'ambientOn': ambientOn,
    'voiceOn': voiceOn,
    'reducedMotion': reducedMotion,
    'largeText': largeText,
    'captions': captions,
    'language': language,
  };

  factory ProfileSettings.fromJson(Map<String, dynamic> j) {
    double d(String k, double def) => (j[k] as num?)?.toDouble() ?? def;
    bool b(String k, bool def) => (j[k] as bool?) ?? def;
    return ProfileSettings(
      music: d('music', .55),
      effects: d('effects', .9),
      ambient: d('ambient', .6),
      voice: d('voice', 1),
      musicOn: b('musicOn', true),
      effectsOn: b('effectsOn', true),
      ambientOn: b('ambientOn', true),
      voiceOn: b('voiceOn', true),
      reducedMotion: b('reducedMotion', false),
      largeText: b('largeText', false),
      captions: b('captions', true),
      language: (j['language'] ?? 'fa') as String,
    );
  }
}

/// یک نوبت بازی، برای تاریخچه‌ی محلی (فقط برای والدین؛ به جایی فرستاده نمی‌شود).
class ActivityRecord {
  const ActivityRecord({required this.activityId, required this.title, required this.at, required this.seconds});

  final String activityId;
  final String title;
  final DateTime at;
  final int seconds;

  Map<String, Object?> toJson() => {'a': activityId, 't': title, 'at': at.toIso8601String(), 's': seconds};

  factory ActivityRecord.fromJson(Map<String, dynamic> j) => ActivityRecord(
    activityId: j['a'] as String,
    title: (j['t'] ?? '') as String,
    at: DateTime.tryParse((j['at'] ?? '') as String) ?? DateTime.now(),
    seconds: (j['s'] as num?)?.toInt() ?? 0,
  );
}

/// پیشرفت هر کودک: برچسب‌های جمع‌شده، تاریخچه، آخرین جهان و فعالیت‌های تمام‌شده.
class Progress {
  const Progress({this.stickers = const {}, this.history = const [], this.lastWorld, this.lastRoute, this.completed = const {}});

  final Set<String> stickers;
  final List<ActivityRecord> history;
  final String? lastWorld;

  /// مسیر آخرین فعالیت باز، برای ادامه‌ی طبیعی پس از بازگشت به برنامه.
  final String? lastRoute;
  final Set<String> completed;

  static const historyLimit = 200;

  Progress copyWith({
    Set<String>? stickers,
    List<ActivityRecord>? history,
    String? lastWorld,
    String? lastRoute,
    bool clearLastRoute = false,
    Set<String>? completed,
  }) => Progress(
    stickers: stickers ?? this.stickers,
    history: history ?? this.history,
    lastWorld: lastWorld ?? this.lastWorld,
    lastRoute: clearLastRoute ? null : (lastRoute ?? this.lastRoute),
    completed: completed ?? this.completed,
  );

  Map<String, Object?> toJson() => {
    'stickers': stickers.toList()..sort(),
    'history': [for (final h in history) h.toJson()],
    'lastWorld': lastWorld,
    'lastRoute': lastRoute,
    'completed': completed.toList()..sort(),
  };

  factory Progress.fromJson(Map<String, dynamic> j) => Progress(
    stickers: {for (final s in (j['stickers'] ?? const []) as List) s as String},
    history: [for (final h in (j['history'] ?? const []) as List) ActivityRecord.fromJson(Map<String, dynamic>.from(h as Map))],
    lastWorld: j['lastWorld'] as String?,
    lastRoute: j['lastRoute'] as String?,
    completed: {for (final s in (j['completed'] ?? const []) as List) s as String},
  );
}

/// یک خط نقاشی.
class Stroke {
  const Stroke({required this.color, required this.width, required this.points, this.eraser = false});

  final Color color;
  final double width;

  /// نقطه‌ها نسبت به اندازه‌ی بوم (۰ تا ۱) ذخیره می‌شوند تا نقاشی در هر اندازه‌ی صفحه درست باز شود.
  final List<Offset> points;
  final bool eraser;

  Map<String, Object?> toJson() => {
    'c': color.toARGB32(),
    'w': width,
    'e': eraser,
    'p': [
      for (final p in points) ...[_r(p.dx), _r(p.dy)],
    ],
  };

  static double _r(double v) => (v * 10000).roundToDouble() / 10000;

  factory Stroke.fromJson(Map<String, dynamic> j) {
    final flat = [for (final v in (j['p'] ?? const []) as List) (v as num).toDouble()];
    return Stroke(
      color: Color((j['c'] as num).toInt()),
      width: (j['w'] as num).toDouble(),
      eraser: (j['e'] as bool?) ?? false,
      points: [for (var i = 0; i + 1 < flat.length; i += 2) Offset(flat[i], flat[i + 1])],
    );
  }
}

class Artwork {
  const Artwork({required this.id, required this.createdAt, required this.strokes, this.background = 0xFFFFFFFF});

  final String id;
  final DateTime createdAt;
  final List<Stroke> strokes;
  final int background;

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'bg': background,
    'strokes': [for (final s in strokes) s.toJson()],
  };

  factory Artwork.fromJson(Map<String, dynamic> j) => Artwork(
    id: j['id'] as String,
    createdAt: DateTime.tryParse((j['createdAt'] ?? '') as String) ?? DateTime.now(),
    background: (j['bg'] as num?)?.toInt() ?? 0xFFFFFFFF,
    strokes: [for (final s in (j['strokes'] ?? const []) as List) Stroke.fromJson(Map<String, dynamic>.from(s as Map))],
  );
}

/// یک نت ضبط‌شده در استودیوی موسیقی.
class SongNote {
  const SongNote({required this.sound, required this.atMs});

  /// مسیر منطقی صدا، مثل audio/instruments/piano_c4.mp3
  final String sound;
  final int atMs;

  Map<String, Object?> toJson() => {'s': sound, 't': atMs};
  factory SongNote.fromJson(Map<String, dynamic> j) => SongNote(sound: j['s'] as String, atMs: (j['t'] as num).toInt());
}

class Song {
  const Song({required this.id, required this.createdAt, required this.notes});

  final String id;
  final DateTime createdAt;
  final List<SongNote> notes;

  int get lengthMs => notes.isEmpty ? 0 : notes.last.atMs;

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'notes': [for (final n in notes) n.toJson()],
  };

  factory Song.fromJson(Map<String, dynamic> j) => Song(
    id: j['id'] as String,
    createdAt: DateTime.tryParse((j['createdAt'] ?? '') as String) ?? DateTime.now(),
    notes: [for (final n in (j['notes'] ?? const []) as List) SongNote.fromJson(Map<String, dynamic>.from(n as Map))],
  );
}

/// وضعیت ذخیره‌شده‌ی یک شیء در صحنه (جای جدید، روشن/خاموش، مرحله‌ی رشد).
class ObjectState {
  const ObjectState({required this.x, required this.y, this.on = false, this.stage = 0, this.hidden = false});

  final double x, y;
  final bool on;
  final int stage;
  final bool hidden;

  ObjectState copyWith({double? x, double? y, bool? on, int? stage, bool? hidden}) =>
      ObjectState(x: x ?? this.x, y: y ?? this.y, on: on ?? this.on, stage: stage ?? this.stage, hidden: hidden ?? this.hidden);

  Map<String, Object?> toJson() => {'x': x, 'y': y, 'on': on, 'st': stage, 'h': hidden};

  factory ObjectState.fromJson(Map<String, dynamic> j) => ObjectState(
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    on: (j['on'] as bool?) ?? false,
    stage: (j['st'] as num?)?.toInt() ?? 0,
    hidden: (j['h'] as bool?) ?? false,
  );

  @override
  bool operator ==(Object other) =>
      other is ObjectState && other.x == x && other.y == y && other.on == on && other.stage == stage && other.hidden == hidden;

  @override
  int get hashCode => Object.hash(x, y, on, stage, hidden);
}

/// یک قطعه در کارگاه ساخت‌وساز.
class BuildPiece {
  const BuildPiece({required this.uid, required this.kind, required this.x, required this.y, this.rotation = 0});

  final String uid;
  final String kind;
  final double x, y;
  final int rotation;

  BuildPiece copyWith({double? x, double? y, int? rotation}) =>
      BuildPiece(uid: uid, kind: kind, x: x ?? this.x, y: y ?? this.y, rotation: rotation ?? this.rotation);

  Map<String, Object?> toJson() => {'u': uid, 'k': kind, 'x': x, 'y': y, 'r': rotation};

  factory BuildPiece.fromJson(Map<String, dynamic> j) => BuildPiece(
    uid: j['u'] as String,
    kind: j['k'] as String,
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    rotation: (j['r'] as num?)?.toInt() ?? 0,
  );
}
