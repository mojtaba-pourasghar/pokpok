import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'toon.dart';

/// خوراکی‌ها و وسایل آشپزخانه.
final Map<String, ToonPainter> foodToons = {
  'orange': (k, p) => k.alive(p, () {
    k.circle(50, 58, 30, const Color(0xFFFF9800));
    for (var i = 0; i < 9; i++) {
      final a = i * 2.1;
      k.c.drawCircle(Offset(50 + math.cos(a) * 18, 58 + math.sin(a) * 18), 1.2, Paint()..color = const Color(0x55B85C00));
    }
    k.shine(38, 44, 9, 5);
    k.stroke([const Offset(50, 30), const Offset(51, 23)], const Color(0xFF6D4C41), 3);
    k.at(52, 25, () => k.oval(8, 0, 9, 4.5, const Color(0xFF66BB6A)), rot: -.4 + p.wave(.7) * .15);
    k.face(50, 58, 22, p);
  }),
  'orange_half': (k, p) => k.alive(p, () {
    k.oval(50, 66, 34, 22, const Color(0xFFFF9800));
    k.oval(50, 62, 29, 17, const Color(0xFFFFF3C4), line: false);
    k.oval(50, 62, 25, 14, const Color(0xFFFFB74D), line: false);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      k.stroke([const Offset(50, 62), Offset(50 + math.cos(a) * 24, 62 + math.sin(a) * 13)], const Color(0xFFFFF3C4), 1.6);
    }
    // قطره‌ی آب که می‌چکد
    final d = p.cycle(.8);
    k.c.drawCircle(Offset(70, 74 + d * 16), 2.6 * (1 - d * .5), Paint()..color = const Color(0xCCFFA726));
    k.face(50, 61, 15, p);
  }),
  'juicer': (k, p) {
    final press = p.act ? (p.wave(2.5) + 1) / 2 : 0.0;
    k.alive(p, () {
      k.rect(22, 62, 56, 28, 10, const Color(0xFF26C6DA));
      k.oval(50, 62, 30, 8, const Color(0xFF4DD0E1));
      // نیمه‌ی پرتقال که فشار داده می‌شود
      k.at(50, 52 + press * 6, () {
        k.oval(0, 0, 18, 12 - press * 3, const Color(0xFFFF9800));
        k.shine(-7, -5, 5, 2.5);
      }, rot: p.act ? p.t * 3 % (math.pi * 2) : 0);
      k.poly([const Offset(78, 70), const Offset(90, 74), const Offset(78, 78)], const Color(0xFF26C6DA));
      if (p.act) {
        final d = p.cycle(3);
        k.c.drawCircle(Offset(90, 78 + d * 12), 2.4, Paint()..color = const Color(0xFFFFA726));
      }
      k.face(50, 76, 13, p);
    });
  },
  'glass': (k, p) => k.alive(p, () {
    final level = p.act ? .3 + p.cycle(.25) * .6 : .0;
    final body = Path()
      ..moveTo(28, 26)
      ..lineTo(72, 26)
      ..lineTo(66, 90)
      ..lineTo(34, 90)
      ..close();
    k.c.drawPath(body, Paint()..color = const Color(0x55BBDEFB));
    if (level > 0) {
      final top = 90 - 62 * level;
      final w = Path()..moveTo(34 - (90 - top) * .09, top);
      for (var x = 0.0; x <= 1; x += .1) {
        w.lineTo(34 - (90 - top) * .09 + x * (32 + (90 - top) * .18), top + math.sin(x * 9 + p.t * 6) * 1.5);
      }
      w
        ..lineTo(66, 90)
        ..lineTo(34, 90)
        ..close();
      k.c.drawPath(w, Paint()..color = const Color(0xCC4FC3F7));
    }
    k.c.drawPath(
      body,
      Paint()
        ..color = const Color(0xFF90A4AE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    k.shine(37, 45, 3, 14, rot: .05, a: .7);
    k.face(50, 60, 16, p);
  }),
  'juice': (k, p) => k.alive(p, () {
    k.rect(28, 30, 44, 60, 6, const Color(0xFFFFB74D));
    k.poly([const Offset(28, 30), const Offset(38, 20), const Offset(72, 20), const Offset(72, 30)], const Color(0xFFFFCC80));
    k.circle(50, 46, 9, const Color(0xFFFF9800));
    k.at(52, 37, () => k.oval(4, 0, 5, 2.4, const Color(0xFF66BB6A)), rot: -.4);
    // نی خم‌شده که با مکیدن بالا و پایین می‌رود
    final sip = p.act ? p.wave(3) * 2 : 0.0;
    k.stroke([Offset(62, 22 + sip), Offset(62, 8 + sip), Offset(70, 2 + sip)], const Color(0xFFE91E63), 3.4);
    if (p.act) {
      for (var i = 0; i < 3; i++) {
        final b = p.cycle(1.5, i / 3);
        k.c.drawCircle(Offset(62, 20 - b * 14), 1.4, Paint()..color = const Color(0xFFFFA726));
      }
    }
    k.face(50, 68, 18, p);
  }),
  'flour': (k, p) => k.alive(p, () {
    k.poly(
      [const Offset(26, 90), const Offset(22, 50), const Offset(32, 26), const Offset(68, 26), const Offset(78, 50), const Offset(74, 90)],
      const Color(0xFFF5E6CC),
      smooth: true,
    );
    k.stroke([const Offset(34, 32), const Offset(50, 36), const Offset(66, 32)], const Color(0xFFBCAAA4), 3);
    k.oval(50, 24, 14, 5, const Color(0xFFFFFFFF));
    if (p.act) {
      for (var i = 0; i < 5; i++) {
        final d = p.cycle(1.2, i / 5);
        k.c.drawCircle(
          Offset(50 + (i - 2) * 6 + math.sin(d * 6) * 3, 22 - d * 18),
          2 + d * 3,
          Paint()..color = Colors.white.withValues(alpha: .7 * (1 - d)),
        );
      }
    }
    k.face(50, 62, 20, p);
  }),
  'water_jug': (k, p) {
    final tilt = p.act ? -.5 + p.wave(.5) * .05 : 0.0;
    k.alive(p, () {
      k.at(50, 88, () {
        k.c.translate(-50, -88);
        k.poly(
          [
            const Offset(32, 90),
            const Offset(30, 46),
            const Offset(38, 30),
            const Offset(64, 30),
            const Offset(70, 46),
            const Offset(68, 90),
          ],
          const Color(0xFF42A5F5),
          smooth: true,
        );
        k.poly([const Offset(30, 32), const Offset(22, 24), const Offset(40, 28)], const Color(0xFF42A5F5));
        k.stroke([const Offset(68, 40), const Offset(82, 46), const Offset(80, 64), const Offset(68, 70)], const Color(0xFF1E88E5), 5);
        k.oval(50, 30, 13, 3.5, const Color(0xFF90CAF9));
        k.shine(38, 50, 4, 10, rot: .1);
        k.face(50, 62, 18, p);
      }, rot: tilt);
      if (p.act) {
        for (var i = 0; i < 6; i++) {
          final d = p.cycle(2.5, i / 6);
          k.c.drawCircle(Offset(18 - d * 4, 40 + d * 50), 2.4, Paint()..color = const Color(0xCC4FC3F7));
        }
      }
    });
  },
  'bowl_mix': (k, p) => k.alive(p, () {
    final a = p.act ? p.t * 5 : p.wave(.3) * .4;
    // قاشق که در کاسه می‌چرخد (پشت لبه‌ی جلو)
    k.at(50 + math.cos(a) * 12, 52, () => k.rect(-3, -36, 6, 40, 3, const Color(0xFFD7A86E)), rot: math.sin(a) * .3);
    final bowl = Path()
      ..moveTo(14, 54)
      ..quadraticBezierTo(16, 92, 50, 92)
      ..quadraticBezierTo(84, 92, 86, 54)
      ..close();
    k.blob(bowl, const Color(0xFFE57373));
    k.oval(50, 54, 36, 8, const Color(0xFFFFF3E0));
    if (p.act) {
      for (var i = 0; i < 3; i++) {
        final aa = a + i * 2.1;
        k.stroke(
          [Offset(50 + math.cos(aa) * 26, 54 + math.sin(aa) * 5), Offset(50 + math.cos(aa + .8) * 18, 54 + math.sin(aa + .8) * 4)],
          const Color(0xFFE0C9A6),
          2,
        );
      }
    }
    k.shine(28, 68, 4, 9, rot: .5);
    k.face(50, 72, 16, p);
  }),
  'dough': (k, p) {
    final knead = p.act ? (p.wave(2) + 1) / 2 : 0.0;
    k.alive(p, () {
      k.rect(10, 76, 80, 14, 6, const Color(0xFFC68B4E));
      k.oval(50, 70 + knead * 3, 30 + knead * 6, 14 - knead * 4, const Color(0xFFF5DEB3));
      k.shine(40, 64, 7, 3);
      k.face(50, 70 + knead * 3, 12, p);
    }, squash: .06);
  },
  'oven': (k, p) => _oven(k, p, 1),
  'big_oven': (k, p) => _oven(k, p, 1.15),
  'bread': (k, p) => k.alive(p, () {
    k.rect(12, 78, 76, 12, 6, const Color(0xFFC68B4E));
    k.poly(
      [const Offset(18, 80), const Offset(20, 52), const Offset(38, 38), const Offset(62, 38), const Offset(80, 52), const Offset(82, 80)],
      const Color(0xFFE0A050),
      smooth: true,
    );
    for (final x in <double>[36.0, 50, 64]) {
      k.stroke([Offset(x - 5, 52), Offset(x + 5, 46)], const Color(0xFFFFE0B2), 3);
    }
    k.steam(50, 34, p, h: 20, a: .4);
    k.face(50, 64, 16, p);
  }),
  'carrot': (k, p) => k.alive(p, () {
    for (final (dx, r) in [(-6.0, -.4), (0.0, 0.0), (6.0, .4)]) {
      k.at(50 + dx, 28, () => k.oval(0, -10, 4, 11, const Color(0xFF66BB6A)), rot: r + p.wave(.8, dx) * .12);
    }
    k.poly([const Offset(34, 30), const Offset(66, 30), const Offset(52, 92), const Offset(48, 92)], const Color(0xFFFF8F00), smooth: true);
    for (final y in <double>[44.0, 58, 72]) {
      k.stroke([Offset(44, y), Offset(50, y + 1)], const Color(0xFFE65100), 1.6);
    }
    k.face(50, 44, 15, p);
  }),
  'potato': (k, p) => k.alive(p, () {
    k.poly(
      [
        const Offset(22, 70),
        const Offset(28, 44),
        const Offset(52, 36),
        const Offset(76, 46),
        const Offset(80, 72),
        const Offset(54, 90),
        const Offset(30, 86),
      ],
      const Color(0xFFC49A6C),
      smooth: true,
    );
    for (final o in const [Offset(34, 56), Offset(66, 52), Offset(60, 80)]) {
      k.c.drawCircle(o, 1.6, Paint()..color = const Color(0xFF8D6E63));
    }
    k.face(52, 64, 18, p);
  }),
  'tomato': (k, p) => k.alive(p, () {
    k.stroke([const Offset(30, 22), const Offset(50, 16), const Offset(72, 24)], const Color(0xFF558B2F), 3);
    for (final (x, y, r) in [(30.0, 44.0, 14.0), (70.0, 46.0, 14.0), (50.0, 68.0, 22.0)]) {
      k.stroke([Offset(x, y - r), Offset(x + (50 - x) * .2, y - r - 8)], const Color(0xFF558B2F), 2);
      k.circle(x, y + p.wave(.6, x / 100) * 1.2, r, const Color(0xFFE53935));
      k.shine(x - r * .4, y - r * .4, r * .25, r * .14);
    }
    k.face(50, 68, 16, p);
  }),
  'rotten_apple': (k, p) => k.alive(p, () {
    k.circle(50, 60, 28, const Color(0xFF8D6E63));
    for (final o in const [Offset(38, 52), Offset(62, 70), Offset(58, 48)]) {
      k.c.drawCircle(o, 5, Paint()..color = const Color(0xFF5D4037));
    }
    k.stroke([const Offset(50, 32), const Offset(48, 24)], const Color(0xFF4E342E), 3);
    // کرم که از سوراخ سرک می‌کشد
    final w = (p.wave(.6) + 1) / 2;
    k.at(74, 54 - w * 8, () {
      k.oval(0, 0, 5, 7, const Color(0xFFF48FB1));
      k.c.drawCircle(const Offset(-1.6, -2), 1.1, Paint()..color = Colors.black);
      k.c.drawCircle(const Offset(1.6, -2), 1.1, Paint()..color = Colors.black);
    }, rot: p.wave(1.2) * .3);
    k.face(46, 62, 16, p.mood == ToonMood.idle ? ToonPose(p.t, mood: ToonMood.sad, seed: p.seed) : p);
  }),
  'pot': (k, p) => _pot(k, p, soup: false),
  'soup': (k, p) => k.alive(p, () {
    final bowl = Path()
      ..moveTo(14, 56)
      ..quadraticBezierTo(18, 92, 50, 92)
      ..quadraticBezierTo(82, 92, 86, 56)
      ..close();
    k.blob(bowl, const Color(0xFF42A5F5));
    k.oval(50, 56, 36, 9, const Color(0xFFFFA726));
    for (final (x, c) in [(38.0, const Color(0xFFFF7043)), (56.0, const Color(0xFF66BB6A)), (48.0, const Color(0xFFFFEB3B))]) {
      k.circle(x + p.wave(.4, x) * 2, 56 + p.wave(.5, x) * 1, 3.6, c, line: false);
    }
    k.steam(50, 44, p, h: 30, n: 3);
    k.face(50, 74, 15, p);
  }),
  'egg': (k, p) {
    final crack = p.act ? (p.wave(3) + 1) / 2 : 0.0;
    k.alive(p, () {
      k.at(50 + crack * 2, 60, () {
        k.oval(0, 0, 22, 28, const Color(0xFFFFFDF5));
        k.shine(-8, -12, 5, 8);
      }, rot: p.act ? p.wave(4) * .15 : p.wave(.5) * .05);
      if (p.act) {
        k.stroke(
          [const Offset(30, 56), const Offset(38, 52), const Offset(44, 58), const Offset(52, 50)],
          const Color(0xFF8D6E63),
          1.6,
          smooth: false,
        );
      }
      k.face(50, 64, 15, p);
    }, squash: .05);
  },
  'eggs': (k, p) => k.alive(p, () {
    k.oval(50, 78, 38, 14, const Color(0xFFD4A84F));
    for (final (x, ph) in [(34.0, 0.0), (50.0, .3), (66.0, .6)]) {
      k.at(x, 64, () => k.oval(0, 0, 10, 13, const Color(0xFFFFFDF5)), rot: p.wave(.5, ph) * .12);
    }
    for (var i = 0; i < 8; i++) {
      k.stroke([Offset(16 + i * 9.0, 72), Offset(22 + i * 9.0, 84)], const Color(0xFFB8860B), 1.4);
    }
    k.face(50, 64, 10, p);
  }),
  'candle': (k, p) => k.alive(p, () {
    k.rect(40, 40, 20, 52, 4, const Color(0xFFF8BBD0));
    for (var y = 46.0; y < 88; y += 12) {
      k.stroke([Offset(40, y), Offset(60, y - 6)], const Color(0xFFE91E63), 3);
    }
    k.stroke([const Offset(50, 40), const Offset(50, 33)], const Color(0xFF4E342E), 2);
    // «ناراحت» یعنی شمع فوت شده: شعله نیست و دود بالا می‌رود؛ «مشغول» یعنی دارند فوتش می‌کنند.
    if (p.sad) {
      k.steam(50, 30, p, h: 26, n: 2, a: .5);
    } else {
      _flame(k, p, 50, 32, 1, lean: p.act ? .9 : 0);
    }
    k.face(50, 62, 12, p.sad ? ToonPose(p.t, mood: ToonMood.happy, seed: p.seed) : p);
  }),
  'cake': (k, p) => k.alive(p, () {
    k.oval(50, 88, 40, 6, const Color(0xFFE0E0E0));
    k.rect(16, 56, 68, 32, 10, const Color(0xFFFFE0B2));
    k.rect(16, 50, 68, 16, 8, const Color(0xFFF48FB1));
    for (var x = 20.0; x < 84; x += 12) {
      k.circle(x, 66, 4, const Color(0xFFF48FB1), line: false);
    }
    for (final x in <double>[34.0, 50, 66]) {
      k.rect(x - 2.5, 34, 5, 16, 2, const Color(0xFF81D4FA));
      _flame(k, p, x, 31, .7);
    }
    k.face(50, 74, 14, p);
  }),
  'milk': (k, p) => k.alive(p, () {
    k.rect(42, 14, 16, 12, 3, const Color(0xFF42A5F5));
    k.poly([
      const Offset(40, 26),
      const Offset(60, 26),
      const Offset(70, 42),
      const Offset(70, 90),
      const Offset(30, 90),
      const Offset(30, 42),
    ], Colors.white);
    k.rect(30, 50, 40, 22, 2, const Color(0xFF90CAF9), line: false);
    k.shine(36, 60, 2.5, 14, rot: 0);
    k.face(50, 62, 15, p);
  }),
  'fridge': (k, p) => k.alive(p, () {
    k.rect(24, 10, 52, 82, 10, const Color(0xFFF5F5F5));
    k.stroke([const Offset(24, 40), const Offset(76, 40)], const Color(0xFFBDBDBD), 2);
    k.rect(66, 18, 4, 14, 2, const Color(0xFFB0BEC5));
    k.rect(66, 46, 4, 18, 2, const Color(0xFFB0BEC5));
    if (p.act) k.glow(50, 60, 30, const Color(0xFF81D4FA), .3);
    k.face(46, 62, 18, p);
  }),
  'cheese': (k, p) => k.alive(p, () {
    k.poly([const Offset(16, 84), const Offset(84, 84), const Offset(84, 52), const Offset(28, 40)], const Color(0xFFFFCA28));
    for (final (x, y, r) in [(36.0, 66.0, 4.0), (62.0, 74.0, 5.0), (72.0, 58.0, 3.0)]) {
      k.c.drawCircle(Offset(x, y), r, Paint()..color = const Color(0xFFFFA000));
    }
    k.face(52, 64, 15, p);
  }),
  'lettuce': (k, p) => k.alive(p, () {
    k.at(50, 90, () {
      k.poly(
        [
          const Offset(-32, 0),
          const Offset(-36, -30),
          const Offset(-20, -56),
          const Offset(0, -64),
          const Offset(20, -56),
          const Offset(36, -30),
          const Offset(32, 0),
        ],
        const Color(0xFF8BC34A),
        smooth: true,
      );
      k.stroke([const Offset(0, -2), const Offset(0, -56)], const Color(0xFFDCEDC8), 3);
      for (final s in [-1.0, 1.0]) {
        k.stroke([const Offset(0, -18), Offset(s * 20, -34)], const Color(0xFFDCEDC8), 2);
        k.stroke([const Offset(0, -34), Offset(s * 16, -48)], const Color(0xFFDCEDC8), 2);
      }
    }, rot: p.wave(.5) * .06);
    k.face(50, 62, 14, p);
  }),
  'sandwich': (k, p) => k.alive(p, () {
    k.rect(16, 70, 68, 16, 8, const Color(0xFFE0A050));
    k.poly(
      [
        const Offset(14, 66),
        const Offset(30, 60),
        const Offset(46, 68),
        const Offset(62, 60),
        const Offset(86, 66),
        const Offset(84, 72),
        const Offset(16, 72),
      ],
      const Color(0xFF8BC34A),
      smooth: true,
    );
    k.rect(18, 56, 64, 10, 3, const Color(0xFFFFCA28));
    k.rect(16, 38 + p.wave(1) * 1.5, 68, 18, 9, const Color(0xFFE0A050));
    k.shine(32, 43, 8, 2.5, rot: 0);
    k.face(50, 46, 12, p);
  }),
  'honey': (k, p) => k.alive(p, () {
    k.poly(
      [const Offset(28, 40), const Offset(72, 40), const Offset(78, 70), const Offset(66, 90), const Offset(34, 90), const Offset(22, 70)],
      const Color(0xFFFFB300),
      smooth: true,
    );
    k.rect(30, 30, 40, 12, 4, const Color(0xFFFFE082));
    final d = p.cycle(.5);
    k.c.drawOval(Rect.fromCenter(center: Offset(34, 46 + d * 10), width: 5, height: 6 + d * 6), Paint()..color = const Color(0xFFFFA000));
    k.at(68 + p.wave(.4) * 14, 22 + p.wave(.9) * 4, () => _tinyBee(k, p));
    k.face(50, 66, 16, p);
  }),
  'pizza': (k, p) => k.alive(p, () {
    k.oval(50, 66, 38, 26, const Color(0xFFE0A050));
    k.oval(50, 64, 32, 21, const Color(0xFFFFD54F), line: false);
    for (final o in const [Offset(36, 58), Offset(62, 56), Offset(50, 72), Offset(68, 70), Offset(32, 72)]) {
      k.circle(o.dx, o.dy, 5, const Color(0xFFE53935), line: false);
    }
    k.steam(50, 44, p, h: 16, a: .35);
    k.face(50, 63, 13, p);
  }),
  'cookie': (k, p) => k.alive(p, () {
    k.at(50, 62, () {
      k.circle(0, 0, 28, const Color(0xFFD7A15E));
      for (final o in const [Offset(-14, -10), Offset(10, -14), Offset(14, 10), Offset(-8, 14), Offset(-18, 6)]) {
        k.c.drawCircle(o, 3.4, Paint()..color = const Color(0xFF5D4037));
      }
    }, rot: p.act ? p.t * 3 : p.wave(.3) * .1);
    k.face(50, 62, 15, p);
  }),
};

void _flame(Pen k, ToonPose p, double x, double y, double s, {double lean = 0}) {
  final f = (1 + p.wave(7, x) * .1 + p.wave(11, x) * .06) * (1 - lean * .35);
  k.glow(x, y - 4 * s, 12 * s, const Color(0xFFFFE082), .5);
  k.at(
    x,
    y,
    () {
      final out = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-6 * s, -6 * s, 0, -16 * s)
        ..quadraticBezierTo(6 * s, -6 * s, 0, 0);
      k.c.drawPath(out, Paint()..color = const Color(0xFFFF9800));
      final inn = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-3 * s, -4 * s, 0, -9 * s)
        ..quadraticBezierTo(3 * s, -4 * s, 0, 0);
      k.c.drawPath(inn, Paint()..color = const Color(0xFFFFF176));
    },
    sx: 1 / f,
    sy: f,
    rot: p.wave(3, x) * .08 + lean * (.7 + p.wave(9) * .15),
  );
}

void _tinyBee(Pen k, ToonPose p) {
  final flap = p.wave(14).abs();
  k.oval(-3, -5, 4, 3 * flap + .5, Colors.white.withValues(alpha: .8), line: false);
  k.oval(3, -5, 4, 3 * flap + .5, Colors.white.withValues(alpha: .8), line: false);
  k.oval(0, 0, 6, 4.5, const Color(0xFFFFD54F));
  k.stroke([const Offset(-1, -4), const Offset(-1, 4)], const Color(0xFF3E2723), 1.6);
  k.stroke([const Offset(2.5, -4), const Offset(2.5, 4)], const Color(0xFF3E2723), 1.6);
}

void _oven(Pen k, ToonPose p, double scale) => k.alive(p, () {
  k.at(
    50,
    92,
    () {
      k.c.translate(-50, -92);
      k.rect(18, 22, 64, 70, 10, const Color(0xFFEF6C00));
      k.rect(18, 22, 64, 14, 8, const Color(0xFFFFA726));
      for (final x in <double>[30.0, 44, 58, 70]) {
        k.circle(x, 29, 3.2, const Color(0xFFFFFFFF));
      }
      final heat = p.act ? .6 + p.wave(2) * .3 : .25;
      k.rect(28, 46, 44, 32, 8, Color.lerp(const Color(0xFF4E342E), const Color(0xFFFFB300), heat)!);
      k.glow(50, 62, 26, const Color(0xFFFFE082), heat * .6);
      k.rect(28, 40, 44, 4, 2, const Color(0xFFBDBDBD));
      if (p.act) k.steam(50, 20, p, h: 16, a: .4);
      k.face(50, 58, 14, p);
    },
    sx: scale,
    sy: scale,
  );
});

void _pot(Pen k, ToonPose p, {required bool soup}) => k.alive(p, () {
  final boil = p.act ? (p.wave(3) + 1) / 2 : 0.0;
  k.rect(16, 50, 68, 40, 12, const Color(0xFFE53935));
  k.rect(8, 56, 12, 6, 3, const Color(0xFFB71C1C));
  k.rect(80, 56, 12, 6, 3, const Color(0xFFB71C1C));
  // درِ قابلمه که با جوشیدن بالا می‌پرد
  k.at(50, 48 - boil * 5, () {
    k.oval(0, 0, 36, 7, const Color(0xFFEF5350));
    k.circle(0, -7, 4, const Color(0xFF424242));
  }, rot: p.act ? p.wave(5) * .05 : 0);
  if (p.act) k.steam(50, 36, p, h: 24, n: 4);
  k.shine(26, 64, 3, 10, rot: 0);
  k.face(50, 70, 16, p);
});
