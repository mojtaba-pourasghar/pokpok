import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../data/models/models.dart';
import '../construction/build_screen.dart' show BlockShape;

/// منطق خالص پازل‌ها (بدون رابط کاربری) تا جدا آزمون شود.
/// دشواری فقط با تعداد قطعه‌ها و طول الگو بالا می‌رود؛ زمان‌سنج و امتیاز منفی در کار نیست.
class PuzzleLevel {
  const PuzzleLevel({required this.pieces, required this.colors, required this.patternKind, required this.pairs});

  final int pieces;
  final int colors;

  /// ۰: AB، ۱: ABC، ۲: AAB
  final int patternKind;
  final int pairs;

  static PuzzleLevel forAge(AgeBand band) => switch (band) {
    AgeBand.toddler => const PuzzleLevel(pieces: 3, colors: 2, patternKind: 0, pairs: 3),
    AgeBand.preschool => const PuzzleLevel(pieces: 4, colors: 3, patternKind: 1, pairs: 4),
    AgeBand.early => const PuzzleLevel(pieces: 5, colors: 4, patternKind: 2, pairs: 6),
  };
}

class ShapeItem {
  const ShapeItem(this.shape, this.color);

  final BlockShape shape;
  final Color color;
}

const puzzleColors = [Color(0xFFF2574E), Color(0xFF3778F6), Color(0xFFFFD34F), Color(0xFF3DBE6B)];
const puzzleColorNames = ['قرمز', 'آبی', 'زرد', 'سبز'];

List<ShapeItem> shapeRound(int n, math.Random r) {
  final shapes = [...BlockShape.values]..shuffle(r);
  final colors = [...puzzleColors, const Color(0xFFA77BEF)]..shuffle(r);
  return [for (var i = 0; i < n; i++) ShapeItem(shapes[i % shapes.length], colors[i % colors.length])];
}

/// قطعه‌های مرتب‌سازی رنگ: هر رنگ دست‌کم دو قطعه.
List<ShapeItem> sortRound(int colors, math.Random r) {
  final items = <ShapeItem>[];
  for (var c = 0; c < colors; c++) {
    for (var k = 0; k < 2; k++) {
      items.add(ShapeItem(BlockShape.values[r.nextInt(BlockShape.values.length)], puzzleColors[c]));
    }
  }
  return items..shuffle(r);
}

class PatternRound {
  const PatternRound(this.sequence, this.answer, this.options);

  /// دنباله‌ی نمایش‌داده‌شده (شناسه‌ی تصویر)، که یک جای خالی در انتها دارد.
  final List<String> sequence;
  final String answer;
  final List<String> options;
}

const patternArt = ['apple', 'banana', 'carrot', 'flower_red', 'flower_yellow', 'fish', 'ball', 'sun', 'cloud', 'duck'];

PatternRound patternRound(int kind, math.Random r) {
  final pool = [...patternArt]..shuffle(r);
  final unit = switch (kind) {
    0 => [pool[0], pool[1]],
    1 => [pool[0], pool[1], pool[2]],
    _ => [pool[0], pool[0], pool[1]],
  };
  final length = unit.length * 2 + (kind == 0 ? 2 : 1);
  final full = [for (var i = 0; i < length + 1; i++) unit[i % unit.length]];
  final answer = full.last;
  final others = {...unit, pool[3]}..remove(answer);
  final options = [answer, ...others.take(2)]..shuffle(r);
  return PatternRound(full.sublist(0, length), answer, options);
}

/// کارت‌های بازی حافظه: هر تصویر دو بار.
List<String> matchDeck(int pairs, math.Random r) {
  final pool = ['cow', 'cat', 'dog', 'duck', 'frog', 'rabbit', 'bee', 'fish', 'sheep', 'chick']..shuffle(r);
  return [...pool.take(pairs), ...pool.take(pairs)]..shuffle(r);
}
