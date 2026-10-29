import 'package:flutter/painting.dart';

import 'creatures.dart';
import 'food.dart';
import 'scenes.dart';
import 'things.dart';
import 'toon.dart';
import 'workshop.dart';

export 'toon.dart';

/// همه‌ی کارتون‌های زنده بر اساس شناسه‌ی تصویر (همان شناسه‌های art در build_game.py).
final Map<String, ToonPainter> toons = {...creatureToons, ...foodToons, ...workshopToons, ...thingToons, ...sceneToons};

/// جای واقعی شکل در بوم ۱۰۰×۱۰۰ (برای بازی‌هایی که باید روی خود شیء کار کنند، مثل بریدن).
const Map<String, Rect> toonBounds = {
  'orange': Rect.fromLTRB(20, 24, 80, 90),
  'dough': Rect.fromLTRB(16, 42, 84, 78),
  'carrot': Rect.fromLTRB(34, 18, 66, 92),
  'cheese': Rect.fromLTRB(16, 40, 84, 84),
  'paper': Rect.fromLTRB(22, 30, 78, 90),
  'drum_skin': Rect.fromLTRB(16, 42, 84, 86),
  'reed': Rect.fromLTRB(36, 12, 64, 92),
  'plank': Rect.fromLTRB(6, 52, 94, 80),
};

/// جای شکل [id] در بوم ۱۰۰×۱۰۰؛ اگر ثبت نشده باشد تقریباً همه‌ی بوم.
Rect toonBoundsOf(String id) => toonBounds[id] ?? const Rect.fromLTRB(14, 14, 86, 92);
