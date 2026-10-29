import 'creatures.dart';
import 'food.dart';
import 'scenes.dart';
import 'things.dart';
import 'toon.dart';
import 'workshop.dart';

export 'toon.dart';

/// همه‌ی کارتون‌های زنده بر اساس شناسه‌ی تصویر (همان شناسه‌های art در build_game.py).
final Map<String, ToonPainter> toons = {...creatureToons, ...foodToons, ...workshopToons, ...thingToons, ...sceneToons};
