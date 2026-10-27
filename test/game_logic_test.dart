import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/app/providers.dart';
import 'package:popo/data/models/models.dart';
import 'package:popo/game/game_data.dart';
import 'package:popo/game/game_state.dart';
import 'package:popo/game/scoring.dart';

import 'helpers.dart';

void main() {
  group('stars', () {
    test('three for clean and fast, two for clean but slow or a little help, one otherwise', () {
      expect(Scoring.stars(hints: 0, mistakes: 1, seconds: 80, target: 100), 3);
      expect(Scoring.stars(hints: 0, mistakes: 0, seconds: 150, target: 100), 2, reason: 'clean but slow');
      expect(Scoring.stars(hints: 2, mistakes: 3, seconds: 150, target: 100), 2, reason: 'some help, within 2× time');
      expect(Scoring.stars(hints: 2, mistakes: 3, seconds: 250, target: 100), 1, reason: 'some help and very slow');
      expect(Scoring.stars(hints: 3, mistakes: 0, seconds: 10, target: 100), 1, reason: 'too many hints');
      expect(Scoring.stars(hints: 0, mistakes: 6, seconds: 10, target: 100), 1, reason: 'too many mistakes');
    });

    test('time does not count for the youngest, and is more generous for 4–6', () {
      expect(Scoring.targetFor(100, AgeBand.toddler), isNull);
      expect(Scoring.targetFor(100, AgeBand.preschool), 150);
      expect(Scoring.targetFor(100, AgeBand.early), 100);
      expect(Scoring.targetFor(100, AgeBand.early, timeOn: false), isNull);
      expect(Scoring.stars(hints: 0, mistakes: 0, seconds: 9999), 3, reason: 'no target → time never costs a star');
    });

    test('coins: full the first time, half on a replay, full plus a bonus for a new record', () {
      expect(Scoring.coins(points: 40, firstTime: true, newRecord: false), 40);
      expect(Scoring.coins(points: 40, firstTime: false, newRecord: false), 20);
      expect(Scoring.coins(points: 40, firstTime: false, newRecord: true), 60);
    });

    test('maker rank comes from lifetime coins', () {
      expect(MakerRank.of(0), MakerRank.apprentice);
      expect(MakerRank.of(150), MakerRank.maker);
      expect(MakerRank.of(1300), MakerRank.grandMaster);
      expect(MakerRank.grandMaster.next, isNull);
    });
  });

  group('progress', () {
    late TestEnv env;
    late ProviderContainer c;
    late GameData data;

    setUp(() async {
      env = await TestEnv.create();
      c = env.container();
      data = env.game;
    });

    tearDown(() async {
      c.dispose();
      await env.dispose();
    });

    RunStats run({int hints = 0, int mistakes = 0, int points = 30}) => RunStats()
      ..hints = hints
      ..mistakes = mistakes
      ..points = points;

    test('finishing a section keeps the best stars, adds coins and puts the item in the backpack', () async {
      final s = data.sections['c1s1']!;
      final g = c.read(gameProvider.notifier);
      final first = await g.finish(s, run(hints: 3), target: 100);
      expect(first.stars, 1);
      expect(first.coins, 30);
      expect(c.read(gameProvider).backpack, contains('juice'));

      final better = await g.finish(s, run(), target: 100);
      expect(better.stars, 3);
      expect(better.newRecord, isTrue);
      expect(better.coins, 30 + Scoring.recordBonus);

      final worse = await g.finish(s, run(hints: 5), target: 100);
      expect(worse.stars, 1);
      expect(c.read(gameProvider).starsOf('c1s1'), 3, reason: 'stars never go down');
      expect(worse.coins, 15, reason: 'a replay still pays half');
      expect(c.read(gameProvider).records['c1s1']!.plays, 3);

      // سکه‌ها و ستاره‌ها بعد از باز کردن دوباره‌ی برنامه می‌مانند.
      final again = GameRepository(env.store).load(c.read(activeIdProvider));
      expect(again.stars, 3);
      expect(again.coins, c.read(gameProvider).coins);
    });

    test('tools are bought with coins; spending never lowers stars or the rank', () async {
      final g = c.read(gameProvider.notifier);
      final tool = data.tools.first;
      expect(await g.buy(tool), isFalse, reason: 'no coins yet');
      await g.addCoins(tool.price + 5);
      final starsBefore = c.read(gameProvider).stars;
      final lifetime = c.read(gameProvider).lifetimeCoins;
      expect(await g.buy(tool), isTrue);
      expect(c.read(gameProvider).coins, 5);
      expect(c.read(gameProvider).tools, contains(tool.id));
      expect(c.read(gameProvider).stars, starsBefore);
      expect(c.read(gameProvider).lifetimeCoins, lifetime);
      expect(await g.buy(tool), isTrue, reason: 'owned tools stay owned and cost nothing again');
      expect(c.read(gameProvider).coins, 5);
    });

    test('daily bonus: once a day, 50 coins on the seventh day in a row', () async {
      final g = c.read(gameProvider.notifier);
      final day = DateTime(2026, 3, 1);
      expect(await g.dailyBonus(day), 10);
      expect(await g.dailyBonus(day), 0);
      for (var i = 1; i < 6; i++) {
        expect(await g.dailyBonus(day.add(Duration(days: i))), 10);
      }
      expect(await g.dailyBonus(day.add(const Duration(days: 6))), 50);
      expect(await g.dailyBonus(day.add(const Duration(days: 9))), 10, reason: 'a gap restarts the streak');
      expect(c.read(gameProvider).streak, 1);
    });

    test('orders pay once per day; combos pay once ever; secrets once per section', () async {
      final g = c.read(gameProvider.notifier);
      final day = DateTime(2026, 3, 1);
      await g.completeOrder(0, now: day);
      await g.completeOrder(0, now: day);
      expect(c.read(gameProvider).coins, 15);
      expect(g.ordersToday(day), [0]);
      expect(g.ordersToday(day.add(const Duration(days: 1))), isEmpty);
      expect(await g.discoverCombo(data.combos.first), isTrue);
      expect(await g.discoverCombo(data.combos.first), isFalse);
      expect(await g.findSecret('c1s1'), isTrue);
      expect(await g.findSecret('c1s1'), isFalse);
      expect(c.read(gameProvider).coins, 15 + 25 + Scoring.secret);
    });

    test('each child has their own game progress', () async {
      final profiles = c.read(profilesProvider.notifier);
      final a = await profiles.create(name: 'آرا', avatar: 'cat', ageBand: AgeBand.toddler);
      await c.read(gameProvider.notifier).addCoins(40);
      await profiles.create(name: 'نیما', avatar: 'dog', ageBand: AgeBand.early);
      expect(c.read(gameProvider).coins, 0);
      await profiles.select(a.id);
      expect(c.read(gameProvider).coins, 40);
    });
  });
}
