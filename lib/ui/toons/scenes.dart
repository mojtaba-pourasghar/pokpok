import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'creatures.dart';
import 'food.dart';
import 'things.dart';
import 'toon.dart';
import 'workshop.dart';

/// کارت‌های صحنه‌ی «مشکل» (کوله‌پشتی و پرسش‌ها): هر کارت یک صحنه‌ی کوچک زنده است.

/// کارت گرد با آسمان/زمین و [draw] روی آن.
void _card(Pen k, ToonPose p, List<Color> sky, void Function() draw, {Color ground = const Color(0xFF9CCC65)}) {
  final r = RRect.fromRectAndRadius(const Rect.fromLTWH(6, 6, 88, 88), const Radius.circular(18));
  k.c.save();
  k.c.clipRRect(r);
  k.c.drawRect(
    const Rect.fromLTWH(6, 6, 88, 88),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: sky,
      ).createShader(const Rect.fromLTWH(6, 6, 88, 88)),
  );
  k.c.drawOval(const Rect.fromLTWH(-10, 70, 120, 50), Paint()..color = ground);
  draw();
  k.c.restore();
  k.c.drawRRect(
    r,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4,
  );
}

/// یک کارتون دیگر در جای ([x],[y]) با مقیاس [s] (مرکز پایین).
void _put(Pen k, ToonPainter t, ToonPose p, double x, double y, double s) => k.at(
  x,
  y,
  () {
    k.c.translate(-50, -92);
    t(k, p);
  },
  sx: s,
  sy: s,
);

ToonPose _as(ToonPose p, ToonMood m) => ToonPose(p.t, mood: m, seed: p.seed);

const _day = [Color(0xFF81D4FA), Color(0xFFE1F5FE)];
const _night = [Color(0xFF1A237E), Color(0xFF3949AB)];

final Map<String, ToonPainter> sceneToons = {
  'old_shoe': (k, p) => k.alive(p, () {
    final shoe = Path()
      ..moveTo(16, 86)
      ..lineTo(16, 56)
      ..quadraticBezierTo(18, 44, 34, 44)
      ..lineTo(46, 44)
      ..quadraticBezierTo(50, 62, 66, 64)
      ..quadraticBezierTo(88, 66, 88, 80)
      ..lineTo(88, 86)
      ..close();
    k.blob(shoe, const Color(0xFF8D6E63));
    k.rect(14, 84, 76, 6, 3, const Color(0xFF5D4037));
    for (var i = 0; i < 3; i++) {
      k.stroke([Offset(34 + i * 6.0, 50 + i * 3.0), Offset(44 + i * 6.0, 48 + i * 3.0)], const Color(0xFFEFEBE9), 1.6);
    }
    // مگس کوچک
    k.at(70 + p.wave(.8) * 10, 34 + p.wave(1.3) * 6, () {
      k.c.drawCircle(Offset.zero, 2.4, Paint()..color = const Color(0xFF424242));
      k.oval(-2, -3, 2, 2.6 * p.wave(14).abs() + .4, Colors.white.withValues(alpha: .8), line: false);
    });
    k.face(32, 64, 11, _as(p, p.mood == ToonMood.idle ? ToonMood.sad : p.mood));
  }),
  'q_thirsty': (k, p) => _card(k, p, const [Color(0xFFFFE082), Color(0xFFFFF8E1)], () {
    // آفتاب داغ
    k.glow(80, 20, 22, const Color(0xFFFFB300), .6);
    k.circle(80, 20, 9, const Color(0xFFFFCA28));
    _put(k, creatureToons['bunny']!, _as(p, ToonMood.sad), 44, 90, .7);
    _put(k, foodToons['glass']!, p, 76, 90, .32);
    final d = p.cycle(.7);
    k.c.drawOval(Rect.fromCenter(center: Offset(30, 34 + d * 10), width: 3, height: 5), Paint()..color = const Color(0xFF4FC3F7));
  }, ground: const Color(0xFFFFCC80)),
  'q_sleep': (k, p) => _card(k, p, _night, () {
    k.rect(14, 62, 72, 20, 6, const Color(0xFF8D6E63));
    k.rect(18, 54, 20, 12, 5, Colors.white);
    _put(k, creatureToons['bear']!, ToonPose(0, seed: p.seed), 30, 70, .34);
    k.rect(30, 60, 54, 16, 6, const Color(0xFF7E57C2));
    for (var i = 0; i < 3; i++) {
      final d = p.cycle(.5, i / 3);
      k.c.save();
      final tp = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            fontSize: 6 + i * 2.0,
            color: Colors.white.withValues(alpha: 1 - d),
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(k.c, Offset(44 + i * 7 + d * 6, 40 - d * 20 - i * 4));
      k.c.restore();
    }
    k.star(74, 20, 4, const Color(0xFFFFF59D), line: false);
  }, ground: const Color(0xFF5C6BC0)),
  'q_paint': (k, p) => _card(k, p, _day, () {
    k.stroke([const Offset(56, 86), const Offset(64, 26)], const Color(0xFF8D6E63), 3);
    k.stroke([const Offset(80, 86), const Offset(70, 26)], const Color(0xFF8D6E63), 3);
    k.rect(52, 24, 32, 40, 3, Colors.white);
    final pr = p.cycle(.3);
    for (var i = 0; i < 4; i++) {
      if (i / 4 < pr) {
        k.circle(
          60 + (i % 2) * 14.0,
          34 + (i ~/ 2) * 16.0,
          5,
          const [Color(0xFFF44336), Color(0xFFFFEB3B), Color(0xFF4CAF50), Color(0xFF2196F3)][i],
          line: false,
        );
      }
    }
    _put(k, creatureToons['parrot']!, _as(p, ToonMood.act), 32, 90, .55);
  }),
  'q_hungry': (k, p) => _card(k, p, const [Color(0xFFFFCCBC), Color(0xFFFFF3E0)], () {
    _put(k, creatureToons['bear']!, _as(p, ToonMood.sad), 46, 90, .66);
    k.oval(78, 82, 12, 4, Colors.white);
    // شکم قار و قور می‌کند
    final g = p.cycle(1.2);
    k.c.drawCircle(
      const Offset(46, 72),
      4 + g * 8,
      Paint()
        ..color = Colors.white.withValues(alpha: .7 * (1 - g))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }, ground: const Color(0xFFBCAAA4)),
  'q_cold': (k, p) => _card(k, p, const [Color(0xFF90CAF9), Color(0xFFE3F2FD)], () {
    for (var i = 0; i < 8; i++) {
      final d = p.cycle(.3, i / 8);
      k.c.drawCircle(Offset(10 + (i * 13) % 84 + math.sin(d * 6 + i) * 3, 6 + d * 80), 1.8, Paint()..color = Colors.white);
    }
    k.at(math.sin(p.t * 40) * .8, 0, () => _put(k, creatureToons['owl']!, _as(p, ToonMood.sad), 50, 88, .62));
  }, ground: Colors.white),
  'q_flowers': (k, p) => _card(k, p, const [Color(0xFFFFE082), Color(0xFFFFF8E1)], () {
    for (var i = 0; i < 3; i++) {
      final x = 26 + i * 24.0;
      k.at(x, 84, () {
        k.stroke([Offset.zero, const Offset(2, -18), const Offset(10, -24)], const Color(0xFF9E9D24), 2.4);
        k.at(12, -24, () => k.oval(0, 0, 6, 4, const Color(0xFFBA68C8)), rot: 1.2);
      }, rot: p.wave(.3, i / 3) * .05);
    }
    k.glow(80, 18, 20, const Color(0xFFFFB300), .5);
  }, ground: const Color(0xFFD7CCC8)),
  'q_dark': (k, p) => _card(k, p, const [Color(0xFF0D1333), Color(0xFF1A237E)], () {
    k.rect(18, 22, 22, 24, 3, const Color(0xFF283593));
    k.stroke([const Offset(29, 22), const Offset(29, 46)], const Color(0xFF1A237E), 2);
    k.c.drawCircle(const Offset(26, 30), 3, Paint()..color = const Color(0xFFFFF59D));
    // دو چشم در تاریکی
    for (final x in <double>[60, 70]) {
      k.c.drawOval(Rect.fromCenter(center: Offset(x, 60), width: 6, height: 7 * (1 - p.blink)), Paint()..color = Colors.white);
      k.c.drawCircle(Offset(x + p.wave(.3) * 1.2, 60), 1.6 * (1 - p.blink), Paint()..color = Colors.black);
    }
  }, ground: const Color(0xFF0D1333)),
  'q_carry': (k, p) => _card(k, p, _day, () {
    for (var i = 0; i < 3; i++) {
      _put(k, workshopToons['box']!, ToonPose(0, seed: i), 36 + (i == 2 ? 10 : 0), 92 - i * 18.0, .38);
    }
    k.at(math.sin(p.t * 30) * .6, 0, () => _put(k, creatureToons['squirrel']!, _as(p, ToonMood.sad), 76, 90, .4));
    k.c.drawOval(Rect.fromCenter(center: Offset(68, 46 + p.cycle(.8) * 6), width: 3, height: 4), Paint()..color = const Color(0xFF4FC3F7));
  }),
  'q_nail': (k, p) => _card(k, p, const [Color(0xFFFFE0B2), Color(0xFFFFF3E0)], () {
    k.rect(14, 64, 40, 10, 2, const Color(0xFFC68B4E));
    k.rect(46, 58, 40, 10, 2, const Color(0xFFD7A86E));
    _put(k, workshopToons['nail']!, p, 50, 70, .4);
    k.stroke([const Offset(52, 40), const Offset(56, 34)], const Color(0xFFFFB300), 1.6);
    k.stroke([const Offset(46, 40), const Offset(42, 34)], const Color(0xFFFFB300), 1.6);
  }, ground: const Color(0xFFBCAAA4)),
  'q_travel': (k, p) => _card(k, p, _day, () {
    final road = Path()
      ..moveTo(36, 100)
      ..quadraticBezierTo(70, 76, 40, 62)
      ..quadraticBezierTo(16, 50, 52, 36)
      ..quadraticBezierTo(60, 32, 66, 30);
    k.c.drawPath(
      road,
      Paint()
        ..color = const Color(0xFF9E9E9E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
    final metric = road.computeMetrics().first;
    final pos = metric.getTangentForOffset(metric.length * (1 - p.cycle(.15)));
    if (pos != null) k.c.drawCircle(pos.position, 3, Paint()..color = const Color(0xFFE53935));
    k.rect(62, 20, 18, 14, 2, const Color(0xFFF8BBD0));
    k.poly([const Offset(60, 22), const Offset(71, 12), const Offset(82, 22)], const Color(0xFFE91E63));
  }),
  'q_music': (k, p) => _card(k, p, const [Color(0xFFE1BEE7), Color(0xFFF3E5F5)], () {
    _put(k, thingToons['song']!, p, 50, 92, .8);
  }, ground: const Color(0xFFCE93D8)),
  'q_rain': (k, p) => _card(k, p, const [Color(0xFF78909C), Color(0xFFB0BEC5)], () {
    for (var i = 0; i < 10; i++) {
      final d = p.cycle(1.4, i / 10);
      k.stroke([Offset(22 + i * 6.0 - d * 4, 36 + d * 50), Offset(20 + i * 6.0 - d * 4, 42 + d * 50)], const Color(0xFF4FC3F7), 1.6);
    }
    k.at(50 + p.wave(.2) * 4, 24, () {
      for (final (x, r) in [(-14.0, 10.0), (0.0, 14.0), (14.0, 10.0)]) {
        k.circle(x, 0, r, const Color(0xFFECEFF1), line: false);
      }
      k.rect(-24, 0, 48, 10, 5, const Color(0xFFECEFF1), line: false);
      k.eyes(0, 2, 10, 2.6, _as(p, ToonMood.sad));
    });
  }),
  'q_lost': (k, p) => _card(k, p, _night, () {
    for (final x in <double>[16, 84]) {
      k.poly([Offset(x - 12, 92), Offset(x, 30), Offset(x + 12, 92)], const Color(0xFF1B5E20));
    }
    _put(k, creatureToons['baby_owl']!, _as(p, ToonMood.sad), 50 + p.wave(.3) * 4, 90, .6);
    final tp = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(k.c, Offset(62, 24 + p.wave(1) * 2));
  }, ground: const Color(0xFF2E7D32)),
  'q_sky': (k, p) => _card(k, p, _night, () {
    final rnd = math.Random(3);
    for (var i = 0; i < 14; i++) {
      final tw = (p.wave(.8, i / 14) + 1) / 2;
      k.star(10 + rnd.nextDouble() * 80, 10 + rnd.nextDouble() * 55, 1.5 + tw * 2, const Color(0xFFFFF59D), line: false);
    }
    _put(k, thingToons['moon']!, p, 70, 60, .4);
  }, ground: const Color(0xFF283593)),
  'q_party': (k, p) => _card(k, p, const [Color(0xFFFFF9C4), Color(0xFFFFFDE7)], () {
    for (final (i, x) in <double>[30, 48, 66].indexed) {
      _put(k, thingToons['balloon']!, ToonPose(p.t, seed: i), x, 70, .42);
    }
    k.rect(38, 70, 24, 18, 3, const Color(0xFF42A5F5));
    k.rect(48, 70, 4, 18, 0, const Color(0xFFFFEB3B), line: false);
    k.rect(36, 66, 28, 6, 2, const Color(0xFF1E88E5));
  }),
  'q_swim': (k, p) => _card(k, p, _day, () {
    k.rect(10, 56, 80, 34, 6, const Color(0xFF29B6F6));
    for (var r = 0; r < 3; r++) {
      final y = 62 + r * 9.0;
      k.stroke(
        [for (var x = 12.0; x <= 88; x += 6) Offset(x, y + math.sin(x / 6 + p.t * 3 + r) * 1.2)],
        Colors.white.withValues(alpha: .6),
        1.2,
      );
    }
    _put(k, creatureToons['fish']!, p, 50 + p.wave(.3) * 14, 84, .4);
  }),
  'q_cross': (k, p) => _card(k, p, _day, () {
    k.rect(6, 70, 88, 24, 0, const Color(0xFF616161), line: false);
    for (var i = 0; i < 6; i++) {
      k.rect(10 + i * 14.0, 74, 8, 16, 1, Colors.white, line: false);
    }
    final walk = p.cycle(.15);
    _put(k, creatureToons['bunny']!, _as(p, ToonMood.act), 10 + walk * 80, 92, .32);
    _put(k, thingToons['traffic_light']!, const ToonPose(1.4, mood: ToonMood.act), 82, 70, .4);
  }),
  'q_eat': (k, p) => _card(k, p, const [Color(0xFFFFE0B2), Color(0xFFFFF3E0)], () {
    k.oval(50, 66, 30, 14, Colors.white);
    k.oval(50, 64, 22, 9, const Color(0xFFF5F5F5), line: false);
    k.at(80, 60, () => k.rect(-2, -20, 4, 34, 2, const Color(0xFFB0BEC5)), rot: .2 + p.wave(.5) * .05);
    k.oval(80, 40, 5, 7, const Color(0xFFB0BEC5));
    k.steam(50, 54, p, h: 16, n: 2, a: .4);
  }, ground: const Color(0xFFD7CCC8)),
  'q_wear': (k, p) => _card(k, p, _day, () {
    _put(k, creatureToons['cat']!, _as(p, ToonMood.happy), 50, 92, .66);
    k.at(50, 42, () {
      final m = Path()
        ..addOval(Rect.fromCenter(center: Offset.zero, width: 30, height: 12))
        ..addOval(Rect.fromCenter(center: const Offset(-6, 0), width: 7, height: 5))
        ..addOval(Rect.fromCenter(center: const Offset(6, 0), width: 7, height: 5))
        ..fillType = PathFillType.evenOdd;
      k.blob(m, const Color(0xFFE91E63));
    }, rot: p.wave(.4) * .06);
  }),
  'q_water': (k, p) => _card(k, p, _day, () {
    final d = p.cycle(.6);
    k.at(50, 30 + d * 30, () {
      final drop = Path()
        ..moveTo(0, -20)
        ..quadraticBezierTo(16, 4, 0, 12)
        ..quadraticBezierTo(-16, 4, 0, -20)
        ..close();
      k.blob(drop, const Color(0xFF29B6F6));
      k.shine(-4, -2, 2.5, 5);
    }, sy: d > .9 ? .6 : 1);
    k.c.drawOval(
      Rect.fromCenter(center: const Offset(50, 80), width: 10 + d * 30, height: 3 + d * 6),
      Paint()
        ..color = const Color(0xFF29B6F6).withValues(alpha: 1 - d)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }),
};
