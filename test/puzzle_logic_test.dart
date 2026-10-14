import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:popo/data/models/models.dart';
import 'package:popo/features/puzzles/puzzle_logic.dart';
import 'package:popo/features/parental_dashboard/parent_gate_screen.dart';

void main() {
  test('difficulty grows with age band', () {
    final t = PuzzleLevel.forAge(AgeBand.toddler), e = PuzzleLevel.forAge(AgeBand.early);
    expect(t.pieces, lessThan(e.pieces));
    expect(t.colors, lessThan(e.colors));
    expect(t.pairs, lessThan(e.pairs));
  });

  test('shape rounds use distinct shapes', () {
    final r = shapeRound(5, Random(1));
    expect(r.map((s) => s.shape).toSet(), hasLength(5));
  });

  test('sort rounds give each colour at least two pieces', () {
    final r = sortRound(3, Random(2));
    for (final c in puzzleColors.take(3)) {
      expect(r.where((s) => s.color == c).length, greaterThanOrEqualTo(2));
    }
  });

  test('pattern answer continues the sequence and is among the options', () {
    for (var kind = 0; kind < 3; kind++) {
      for (var seed = 0; seed < 20; seed++) {
        final p = patternRound(kind, Random(seed));
        expect(p.options, contains(p.answer));
        expect(p.options.toSet(), hasLength(p.options.length));
        final unit = switch (kind) {
          0 => 2,
          1 => 3,
          _ => 3,
        };
        expect(p.answer, p.sequence[p.sequence.length - unit]);
      }
    }
  });

  test('memory deck holds every picture exactly twice', () {
    final d = matchDeck(4, Random(3));
    expect(d, hasLength(8));
    for (final a in d.toSet()) {
      expect(d.where((x) => x == a), hasLength(2));
    }
  });

  test('parent gate challenge is three digits 1–9', () {
    final g = gateChallenge(Random(4));
    expect(g, hasLength(3));
    expect(g.every((d) => d >= 1 && d <= 9), isTrue);
  });
}
