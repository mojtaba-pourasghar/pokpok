import '../data/models/models.dart';

/// آنچه در یک بار بازی یک بخش اتفاق افتاد.
class RunStats {
  int hints = 0;
  int mistakes = 0;

  /// امتیازها (هر امتیاز یک سکه): گام بی‌اشتباه، وسیله‌ی درست، جواب درست.
  int points = 0;
  final Stopwatch clock = Stopwatch();

  int get seconds => clock.elapsed.inSeconds;
}

/// قاعده‌های ستاره و سکه (سند طراحی، بخش «ستاره و امتیاز»).
abstract final class Scoring {
  static const stepClean = 5;
  static const useRight = 10;
  static const useFirstTry = 5;
  static const quizRight = 10;
  static const secret = 10;
  static const recordBonus = 20;

  /// زمان هدف برای این سن. برای ۲ تا ۴ ساله‌ها زمان حساب نمی‌شود (null).
  static int? targetFor(int targetSec, AgeBand age, {bool timeOn = true}) => switch (age) {
    _ when !timeOn => null,
    AgeBand.toddler => null,
    AgeBand.preschool => (targetSec * 1.5).round(),
    AgeBand.early => targetSec,
  };

  /// ۳ ستاره: بی‌راهنما، حداکثر ۱ اشتباه، در زمان هدف.
  /// ۲ ستاره: حداکثر ۲ راهنما و ۳ اشتباه و کمتر از دو برابر زمان؛ یا کار تمیز ولی دیر.
  /// ۱ ستاره: تمام شده.
  static int stars({required int hints, required int mistakes, required int seconds, int? target}) {
    final clean = hints == 0 && mistakes <= 1;
    final good = hints <= 2 && mistakes <= 3;
    final fast = target == null || seconds <= target;
    final inTime = target == null || seconds <= target * 2;
    if (clean && fast) return 3;
    if (clean || (good && inTime)) return 2;
    return 1;
  }

  /// سکه‌ی این بار: بار اول همه‌ی امتیازها؛ تکرار نصف، و اگر رکورد شکست کامل و جایزه.
  static int coins({required int points, required bool firstTime, required bool newRecord}) {
    if (firstTime) return points;
    if (newRecord) return points + recordBonus;
    return (points / 2).ceil();
  }
}

/// مرتبه‌ی سازنده از جمع همه‌ی سکه‌هایی که تا حالا گرفته (خرج کردن کمش نمی‌کند).
enum MakerRank {
  apprentice('شاگرد', 0),
  maker('سازنده', 150),
  master('استاد', 500),
  grandMaster('استاد بزرگ', 1200);

  const MakerRank(this.title, this.from);
  final String title;
  final int from;

  static MakerRank of(int lifetimeCoins) => values.lastWhere((r) => lifetimeCoins >= r.from);

  MakerRank? get next => index + 1 < values.length ? values[index + 1] : null;
}
