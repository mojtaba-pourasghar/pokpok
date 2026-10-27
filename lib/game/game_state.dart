import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/storage/local_store.dart';
import 'game_data.dart';
import 'scoring.dart';

/// بهترین نتیجه‌ی یک بخش.
class SectionRecord {
  const SectionRecord({required this.stars, required this.seconds, required this.plays});

  final int stars;
  final int seconds;
  final int plays;

  Map<String, Object?> toJson() => {'stars': stars, 'seconds': seconds, 'plays': plays};

  factory SectionRecord.fromJson(Map<String, dynamic> j) => SectionRecord(
    stars: (j['stars'] as num?)?.toInt() ?? 0,
    seconds: (j['seconds'] as num?)?.toInt() ?? 0,
    plays: (j['plays'] as num?)?.toInt() ?? 0,
  );
}

/// پیشرفت بازی یک کودک: ستاره‌ها (خرج نمی‌شوند)، سکه‌ها (خرج می‌شوند)، کوله‌پشتی، ابزارها و …
class GameProgress {
  const GameProgress({
    this.records = const {},
    this.coins = 0,
    this.lifetimeCoins = 0,
    this.backpack = const {},
    this.tools = const {},
    this.combos = const {},
    this.secrets = const {},
    this.films = const {},
    this.ordersDay = '',
    this.ordersDone = const [],
    this.lastBonusDay = '',
    this.streak = 0,
  });

  final Map<String, SectionRecord> records;
  final int coins;
  final int lifetimeCoins;

  /// هر چیزی که ساخته (فصل‌ها، کیت‌ها، دستورهای ساخت).
  final Set<String> backpack;
  final Set<String> tools;
  final Set<String> combos;

  /// جاهای پنهانی که پیدا کرده (sectionId).
  final Set<String> secrets;

  /// فیلم پایان فصل‌هایی که دیده.
  final Set<String> films;

  /// روز سفارش‌های امروز (yyyy-mm-dd) و شماره‌ی سفارش‌های انجام‌شده.
  final String ordersDay;
  final List<int> ordersDone;
  final String lastBonusDay;
  final int streak;

  int get stars => records.values.fold(0, (a, r) => a + r.stars);
  int starsOf(String sectionId) => records[sectionId]?.stars ?? 0;
  bool done(String sectionId) => records.containsKey(sectionId);
  MakerRank get rank => MakerRank.of(lifetimeCoins);

  GameProgress copyWith({
    Map<String, SectionRecord>? records,
    int? coins,
    int? lifetimeCoins,
    Set<String>? backpack,
    Set<String>? tools,
    Set<String>? combos,
    Set<String>? secrets,
    Set<String>? films,
    String? ordersDay,
    List<int>? ordersDone,
    String? lastBonusDay,
    int? streak,
  }) => GameProgress(
    records: records ?? this.records,
    coins: coins ?? this.coins,
    lifetimeCoins: lifetimeCoins ?? this.lifetimeCoins,
    backpack: backpack ?? this.backpack,
    tools: tools ?? this.tools,
    combos: combos ?? this.combos,
    secrets: secrets ?? this.secrets,
    films: films ?? this.films,
    ordersDay: ordersDay ?? this.ordersDay,
    ordersDone: ordersDone ?? this.ordersDone,
    lastBonusDay: lastBonusDay ?? this.lastBonusDay,
    streak: streak ?? this.streak,
  );

  Map<String, Object?> toJson() => {
    'records': {for (final e in records.entries) e.key: e.value.toJson()},
    'coins': coins,
    'lifetimeCoins': lifetimeCoins,
    'backpack': backpack.toList(),
    'tools': tools.toList(),
    'combos': combos.toList(),
    'secrets': secrets.toList(),
    'films': films.toList(),
    'ordersDay': ordersDay,
    'ordersDone': ordersDone,
    'lastBonusDay': lastBonusDay,
    'streak': streak,
  };

  factory GameProgress.fromJson(Map<String, dynamic> j) {
    Set<String> set(String k) => {for (final x in (j[k] ?? const []) as List) x as String};
    return GameProgress(
      records: {
        for (final e in Map<String, dynamic>.from((j['records'] ?? const {}) as Map).entries)
          e.key: SectionRecord.fromJson(Map<String, dynamic>.from(e.value as Map)),
      },
      coins: (j['coins'] as num?)?.toInt() ?? 0,
      lifetimeCoins: (j['lifetimeCoins'] as num?)?.toInt() ?? 0,
      backpack: set('backpack'),
      tools: set('tools'),
      combos: set('combos'),
      secrets: set('secrets'),
      films: set('films'),
      ordersDay: (j['ordersDay'] ?? '') as String,
      ordersDone: [for (final x in (j['ordersDone'] ?? const []) as List) (x as num).toInt()],
      lastBonusDay: (j['lastBonusDay'] ?? '') as String,
      streak: (j['streak'] as num?)?.toInt() ?? 0,
    );
  }
}

/// نتیجه‌ی تمام کردن یک بخش، برای صفحه‌ی ستاره‌ها.
class SectionOutcome {
  const SectionOutcome({required this.stars, required this.coins, required this.firstTime, required this.newRecord, required this.fast});

  final int stars;
  final int coins;
  final bool firstTime;
  final bool newRecord;
  final bool fast;
}

class GameRepository {
  GameRepository(this._store);

  final LocalStore _store;
  static const _box = 'game';

  GameProgress load(String profileId) {
    final j = _store.readJson(_box, profileId);
    return j == null ? const GameProgress() : GameProgress.fromJson(j);
  }

  Future<void> save(String profileId, GameProgress p) => _store.writeJson(_box, profileId, p.toJson());
}

final gameDataProvider = Provider<GameData>((_) => throw UnimplementedError('gameDataProvider'));
final gameRepoProvider = Provider((ref) => GameRepository(ref.watch(storeProvider)));

String dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class GameNotifier extends Notifier<GameProgress> {
  @override
  GameProgress build() => ref.watch(gameRepoProvider).load(ref.watch(activeIdProvider));

  Future<void> _save(GameProgress p) async {
    state = p;
    await ref.read(gameRepoProvider).save(ref.read(activeIdProvider), p);
  }

  Future<void> addCoins(int n) => _save(state.copyWith(coins: state.coins + n, lifetimeCoins: state.lifetimeCoins + n));

  /// یک بخش تمام شد: ستاره (بهترین می‌ماند)، سکه، و شیء ساخته‌شده در کوله.
  Future<SectionOutcome> finish(SectionDef s, RunStats run, {int? target}) async {
    final old = state.records[s.id];
    final stars = Scoring.stars(hints: run.hints, mistakes: run.mistakes, seconds: run.seconds, target: target);
    final firstTime = old == null;
    final newRecord = !firstTime && (stars > old.stars || (stars == old.stars && run.seconds < old.seconds));
    final coins = Scoring.coins(points: run.points, firstTime: firstTime, newRecord: newRecord);
    final best = firstTime || newRecord
        ? SectionRecord(stars: stars, seconds: run.seconds, plays: (old?.plays ?? 0) + 1)
        : SectionRecord(stars: old.stars, seconds: old.seconds, plays: old.plays + 1);
    await _save(
      state.copyWith(
        records: {...state.records, s.id: best},
        coins: state.coins + coins,
        lifetimeCoins: state.lifetimeCoins + coins,
        backpack: {...state.backpack, s.makes},
      ),
    );
    return SectionOutcome(
      stars: stars,
      coins: coins,
      firstTime: firstTime,
      newRecord: newRecord,
      fast: target != null && run.seconds <= target,
    );
  }

  /// خرید ابزار؛ false اگر سکه کافی نیست.
  Future<bool> buy(ToolDef t) async {
    if (state.tools.contains(t.id)) return true;
    if (state.coins < t.price) return false;
    await _save(state.copyWith(coins: state.coins - t.price, tools: {...state.tools, t.id}));
    return true;
  }

  /// true اگر ترکیب تازه بود (سکه می‌دهد).
  Future<bool> discoverCombo(ComboDef c, {int reward = 25}) async {
    if (state.combos.contains(c.id)) return false;
    await _save(state.copyWith(combos: {...state.combos, c.id}, coins: state.coins + reward, lifetimeCoins: state.lifetimeCoins + reward));
    return true;
  }

  Future<bool> findSecret(String sectionId) async {
    if (state.secrets.contains(sectionId)) return false;
    await _save(
      state.copyWith(
        secrets: {...state.secrets, sectionId},
        coins: state.coins + Scoring.secret,
        lifetimeCoins: state.lifetimeCoins + Scoring.secret,
      ),
    );
    return true;
  }

  Future<void> sawFilm(String chapterId) => _save(state.copyWith(films: {...state.films, chapterId}));

  /// سفارش‌های امروز: هر روز از نو.
  List<int> ordersToday([DateTime? now]) => state.ordersDay == dayKey(now ?? DateTime.now()) ? state.ordersDone : const [];

  Future<void> completeOrder(int index, {int reward = 15, DateTime? now}) async {
    final today = dayKey(now ?? DateTime.now());
    final done = state.ordersDay == today ? state.ordersDone : const <int>[];
    if (done.contains(index)) return;
    await _save(
      state.copyWith(
        ordersDay: today,
        ordersDone: [...done, index],
        coins: state.coins + reward,
        lifetimeCoins: state.lifetimeCoins + reward,
      ),
    );
  }

  /// جایزه‌ی روزانه‌ی ورود: ۱۰ سکه، روز هفتمِ پشت سر هم ۵۰. مقدار سکه یا ۰ اگر امروز گرفته.
  Future<int> dailyBonus([DateTime? now]) async {
    final n = now ?? DateTime.now();
    final today = dayKey(n);
    if (state.lastBonusDay == today) return 0;
    final yesterday = dayKey(DateTime(n.year, n.month, n.day - 1));
    final streak = state.lastBonusDay == yesterday ? state.streak + 1 : 1;
    final reward = streak % 7 == 0 ? 50 : 10;
    await _save(
      state.copyWith(lastBonusDay: today, streak: streak, coins: state.coins + reward, lifetimeCoins: state.lifetimeCoins + reward),
    );
    return reward;
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameProgress>(GameNotifier.new);
