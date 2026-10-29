import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'toon.dart';

/// هنر و کاردستی، شب و آسمان، موسیقی، شهر و جشن، اسباب‌بازی‌ها.

const _rainbow = [Color(0xFFF44336), Color(0xFFFF9800), Color(0xFFFFEB3B), Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFF9C27B0)];

void _note(Pen k, double x, double y, double s, Color c, {double rot = 0}) => k.at(x, y, () {
  k.stroke([Offset(s * .5, 0), Offset(s * .5, -s * 2.2), Offset(s * 1.4, -s * 1.7)], shade(c, .2), s * .3);
  k.oval(0, 0, s * .65, s * .5, c);
}, rot: rot - .2);

/// پرچم سه‌گوش که در باد تکان می‌خورد.
void _pennant(Pen k, ToonPose p, double x, double y, double w, Color c, double ph) {
  final f = p.wave(1.3, ph) * 3;
  k.poly([Offset(x - w / 2, y), Offset(x + w / 2, y), Offset(x + f, y + w * 1.1)], c);
}

final Map<String, ToonPainter> thingToons = {
  // ── هنر و کاردستی ──
  'brush': (k, p) => k.alive(p, () {
    k.at(50, 56, () {
      k.rect(-4, -10, 8, 46, 4, const Color(0xFFC68B4E));
      k.rect(-6, -18, 12, 10, 2, const Color(0xFFB0BEC5));
      k.poly(
        [const Offset(-6, -18), const Offset(6, -18), const Offset(3, -36), const Offset(0, -40), const Offset(-3, -36)],
        const Color(0xFFE53935),
        smooth: true,
      );
      k.face(0, 14, 6, p);
    }, rot: p.act ? p.wave(2.5) * .5 : .4 + p.wave(.4) * .05);
    if (p.act) {
      for (var i = 0; i < 3; i++) {
        final d = p.cycle(1.5, i / 3);
        k.c.drawCircle(Offset(30 + i * 14.0, 88), 3 + d * 2, Paint()..color = _rainbow[i * 2].withValues(alpha: 1 - d));
      }
    }
  }, shadowW: 30),
  'bristles': (k, p) => k.alive(p, () {
    for (var i = 0; i < 9; i++) {
      final x = 38 + i * 3.0;
      k.stroke([Offset(x, 86), Offset(x + (i - 4) * 1.6 + p.wave(.7, i / 9) * 1.5, 46)], const Color(0xFF8D6E63), 3);
    }
    k.rect(34, 78, 32, 10, 3, const Color(0xFFB0BEC5));
  }),
  'paints': (k, p) => k.alive(p, () {
    final pal = Path()
      ..addOval(Rect.fromCenter(center: const Offset(50, 62), width: 78, height: 54))
      ..addOval(Rect.fromCircle(center: const Offset(64, 74), radius: 7))
      ..fillType = PathFillType.evenOdd;
    k.blob(pal, const Color(0xFFD7A86E));
    for (final (i, o) in const [Offset(28, 56), Offset(38, 44), Offset(54, 40), Offset(70, 48), Offset(30, 72), Offset(76, 62)].indexed) {
      k.circle(o.dx, o.dy + (p.act ? p.wave(2, i / 6) * 1.2 : 0), 6.2, _rainbow[i]);
    }
    k.at(78, 30, () => k.rect(-3, -20, 6, 36, 3, const Color(0xFFC68B4E)), rot: .6 + p.wave(.5) * .1);
    k.face(50, 60, 9, p);
  }),
  'clay': (k, p) => k.alive(p, () {
    final squish = p.act ? (p.wave(2) + 1) / 2 : 0.0;
    k.rect(24 - squish * 6, 50 + squish * 8, 52 + squish * 12, 40 - squish * 8, 10, const Color(0xFFE0855A));
    k.at(76, 40, () => k.rect(-2.5, -16, 5, 32, 2.5, const Color(0xFFC68B4E)), rot: .5);
    for (var i = 0; i < 3; i++) {
      k.stroke([Offset(32 + i * 12.0, 60 + squish * 6), Offset(38 + i * 12.0, 58 + squish * 6)], const Color(0xFFBF6A42), 1.6);
    }
    k.face(50, 72 + squish * 4, 13, p);
  }, squash: .05),
  'clay_bowl': (k, p) => k.alive(p, () {
    final bowl = Path()
      ..moveTo(16, 54)
      ..quadraticBezierTo(18, 92, 50, 92)
      ..quadraticBezierTo(82, 92, 84, 54)
      ..close();
    k.blob(bowl, const Color(0xFFE0855A));
    k.oval(50, 54, 34, 8, const Color(0xFFBF6A42));
    for (final (i, o) in const [Offset(30, 66), Offset(50, 72), Offset(70, 66), Offset(40, 82), Offset(60, 82)].indexed) {
      k.c.drawCircle(o, 3, Paint()..color = _rainbow[i]);
    }
    k.face(50, 70, 12, p);
  }),
  'pottery_wheel': (k, p) {
    final spin = p.act ? p.t * 8 : p.t * .5;
    k.alive(p, () {
      k.rect(30, 74, 40, 18, 5, const Color(0xFF8D6E63));
      k.oval(50, 72, 34, 8, const Color(0xFFB0BEC5));
      k.at(50, 72, () {
        for (var i = 0; i < 4; i++) {
          final a = spin + i * math.pi / 2;
          k.c.drawCircle(Offset(math.cos(a) * 26, math.sin(a) * 5), 1.6, Paint()..color = const Color(0xFF78909C));
        }
      });
      final w = 16 + math.sin(spin * 2) * 1.2;
      final pot = Path()
        ..moveTo(50 - w, 70)
        ..quadraticBezierTo(50 - w - 6, 52, 50 - w * .5, 40)
        ..lineTo(50 + w * .5, 40)
        ..quadraticBezierTo(50 + w + 6, 52, 50 + w, 70)
        ..close();
      k.blob(pot, const Color(0xFFE0855A));
      for (var i = 0; i < 3; i++) {
        final y = 46 + i * 8.0;
        final x = math.sin(spin + i) * 8;
        k.stroke([Offset(50 + x - 4, y), Offset(50 + x + 4, y)], const Color(0xFFBF6A42), 1.4);
      }
      k.face(50, 56, 9, p);
    });
  },
  'paper': (k, p) => k.alive(p, () {
    k.at(50, 60, () {
      final w = p.wave(.6) * 3;
      final sheet = Path()
        ..moveTo(-28, -30)
        ..quadraticBezierTo(0, -30 + w, 28, -30)
        ..lineTo(28, 30)
        ..quadraticBezierTo(0, 30 - w, -28, 30)
        ..close();
      k.blob(sheet, const Color(0xFF80DEEA));
      k.poly([const Offset(16, -30), const Offset(28, -30), const Offset(28, -18)], const Color(0xFF4DD0E1));
      k.face(0, 0, 13, p);
    }, rot: -.08);
  }),
  'lantern': (k, p) => k.alive(p, () {
    final swing = p.wave(.5) * .12;
    final glow = .55 + p.wave(1.3) * .12;
    k.stroke([const Offset(50, 4), const Offset(50, 22)], const Color(0xFF5D4037), 1.6);
    k.at(50, 20, () {
      k.glow(0, 34, 46, const Color(0xFFFFCC80), glow);
      k.rect(-10, 0, 20, 7, 2, const Color(0xFF5D4037));
      final body = Path()..addOval(Rect.fromCenter(center: const Offset(0, 34), width: 52, height: 54));
      k.blob(body, Color.lerp(const Color(0xFFFF7043), const Color(0xFFFFCC80), glow - .4)!);
      for (final x in <double>[-14, 0, 14]) {
        k.stroke([Offset(x * .6, 8), Offset(x, 34), Offset(x * .6, 60)], const Color(0xFFE64A19), 1.4);
      }
      k.rect(-10, 60, 20, 6, 2, const Color(0xFF5D4037));
      k.stroke([const Offset(0, 66), Offset(p.wave(1) * 2, 76)], const Color(0xFFFFB300), 2);
      k.face(0, 34, 12, p);
    }, rot: swing);
  }, shadowW: 40),
  'mask': (k, p) => k.alive(p, () {
    k.at(50, 56, () {
      for (final s in <double>[-1, 1]) {
        k.poly([Offset(s * 14, -18), Offset(s * 28, -36), Offset(s * 34, -10)], const Color(0xFFFF7043));
      }
      final m = Path()
        ..addOval(Rect.fromCenter(center: Offset.zero, width: 76, height: 50))
        ..addOval(Rect.fromCenter(center: const Offset(-15, -3), width: 18, height: 13))
        ..addOval(Rect.fromCenter(center: const Offset(15, -3), width: 18, height: 13))
        ..fillType = PathFillType.evenOdd;
      k.blob(m, const Color(0xFFFF9800));
      k.oval(0, 12, 12, 8, Colors.white, line: false);
      k.oval(0, 8, 4, 3, const Color(0xFF3E2723), line: false);
      for (final s in <double>[-1, 1]) {
        k.c.drawCircle(Offset(s * 15, -3), 3 + p.blink * -2 + 1, Paint()..color = const Color(0xFF2A2250));
        k.stroke([Offset(s * 26, 6), Offset(s * 34, 4)], const Color(0xFF3E2723), 1.2);
      }
      k.stroke([const Offset(-38, 0), const Offset(-46, -2)], const Color(0xFF9C27B0), 2);
    }, rot: p.wave(.4) * .08);
  }),
  'bunting': (k, p) => k.alive(p, () {
    k.stroke([const Offset(4, 30), Offset(50, 46 + p.wave(.5) * 2), const Offset(96, 30)], const Color(0xFF8D6E63), 1.8);
    for (var i = 0; i < 6; i++) {
      final x = 12 + i * 15.0;
      final y = 30 + math.sin(i / 5 * math.pi) * 16 + p.wave(.5) * 2 * math.sin(i / 5 * math.pi);
      _pennant(k, p, x, y, 12, _rainbow[i], i / 6);
    }
  }, squash: 0),
  'flag': (k, p) => k.alive(p, () {
    k.rect(30, 14, 5, 78, 2, const Color(0xFF8D6E63));
    final f = p.wave(1.2) * 4;
    final cloth = Path()
      ..moveTo(35, 18)
      ..quadraticBezierTo(55, 18 + f, 80, 28)
      ..quadraticBezierTo(60, 34 - f, 35, 50)
      ..close();
    k.blob(cloth, const Color(0xFFE91E63));
    k.star(52, 31, 5, const Color(0xFFFFEB3B));
    k.circle(32.5, 13, 4, const Color(0xFFFFB300));
  }, shadowW: 30),
  'map_piece': (k, p) => k.alive(p, () {
    k.at(50, 60, () {
      k.poly([
        const Offset(-26, -22),
        const Offset(-4, -26),
        const Offset(2, -18),
        const Offset(24, -24),
        const Offset(28, 4),
        const Offset(20, 24),
        const Offset(-6, 20),
        const Offset(-28, 26),
      ], const Color(0xFFF3D9A4));
      k.stroke([const Offset(-18, 10), const Offset(-6, 0), const Offset(6, 6), const Offset(18, -8)], const Color(0xFFE53935), 1.6);
      k.face(0, -6, 9, p);
    }, rot: p.wave(.5) * .15);
  }),
  'map': (k, p) => k.alive(p, () {
    k.rect(12, 26, 76, 60, 4, const Color(0xFFF3D9A4));
    for (final x in <double>[12, 88]) {
      k.oval(x, 56, 5, 32, const Color(0xFFD7B57A));
    }
    for (final o in const [Offset(30, 42), Offset(70, 70), Offset(36, 70)]) {
      k.poly([o + const Offset(-6, 6), o + const Offset(0, -6), o + const Offset(6, 6)], const Color(0xFF66BB6A));
    }
    // راه نقطه‌چین که پیش می‌رود
    final pts = [const Offset(24, 76), const Offset(40, 58), const Offset(56, 64), const Offset(62, 46), const Offset(76, 38)];
    final shown = p.act ? p.cycle(.4) : 1.0;
    for (var i = 0; i < 16; i++) {
      final t = i / 15;
      if (t > shown) break;
      final seg = (t * (pts.length - 1)).floor().clamp(0, pts.length - 2);
      final o = Offset.lerp(pts[seg], pts[seg + 1], t * (pts.length - 1) - seg)!;
      k.c.drawCircle(o, 1.6, Paint()..color = const Color(0xFFE53935));
    }
    k.stroke([const Offset(73, 34), const Offset(79, 42)], const Color(0xFFE53935), 2.4);
    k.stroke([const Offset(79, 34), const Offset(73, 42)], const Color(0xFFE53935), 2.4);
    k.face(50, 50, 9, p);
  }),
  'tent': (k, p) => k.alive(p, () {
    final flap = p.act ? (p.wave(1.5) + 1) * .1 : p.wave(.4) * .02;
    k.poly([const Offset(10, 90), const Offset(50, 22), const Offset(90, 90)], const Color(0xFFFF8F00));
    k.at(50, 22, () => k.poly([Offset.zero, const Offset(-12, 68), const Offset(12, 68)], const Color(0xFF6D4C41)), rot: 0);
    k.at(50, 22, () => k.poly([Offset.zero, const Offset(2, 68), const Offset(16, 68)], const Color(0xFFFFB74D)), rot: -flap);
    k.stroke([const Offset(50, 22), const Offset(50, 12)], const Color(0xFF8D6E63), 2.4);
    _pennant(k, p, 55, 12, 8, const Color(0xFFE53935), 0);
    k.face(30, 70, 10, p);
  }),
  'tent_cloth': (k, p) => k.alive(p, () {
    for (var i = 0; i < 3; i++) {
      k.rect(18, 76 - i * 14.0, 64, 14, 6, i.isEven ? const Color(0xFFFF8F00) : const Color(0xFFFFA726));
    }
    k.face(50, 68, 12, p);
  }),
  'firefly_jar': (k, p) => k.alive(p, () {
    k.glow(50, 60, 40, const Color(0xFFEEFF41), .4 + p.wave(.8) * .1);
    k.rect(26, 34, 48, 56, 12, const Color(0x55E1F5FE));
    for (var i = 0; i < 5; i++) {
      final x = 50 + math.sin(p.t * .8 + i * 1.7) * 14, y = 64 + math.cos(p.t * 1.1 + i) * 16;
      k.glow(x, y, 6, const Color(0xFFEEFF41), .5 + p.wave(2, i / 5) * .4);
      k.c.drawCircle(Offset(x, y), 2, Paint()..color = const Color(0xFFF4FF81));
    }
    k.c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(26, 34, 48, 56), const Radius.circular(12)),
      Paint()
        ..color = const Color(0xFF90A4AE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    k.rect(30, 26, 40, 10, 3, const Color(0xFF8D6E63));
    k.shine(34, 52, 2.5, 12, rot: 0);
    k.face(50, 76, 10, p);
  }),
  'telescope': (k, p) => k.alive(p, () {
    for (final r in <double>[.35, -.35, 0]) {
      k.at(50, 60, () => k.rect(-2, 0, 4, 34, 2, const Color(0xFF8D6E63)), rot: r);
    }
    k.at(50, 54, () {
      k.rect(-30, -8, 44, 16, 6, const Color(0xFF5C6BC0));
      k.rect(10, -11, 22, 22, 6, const Color(0xFF3949AB));
      k.oval(32, 0, 4, 11, const Color(0xFFB3E5FC));
      k.rect(-38, -5, 10, 10, 3, const Color(0xFFFFCA28));
      k.face(-8, 0, 8, p);
    }, rot: -.45 + (p.act ? p.wave(.5) * .15 : p.wave(.3) * .04));
    if (p.act) k.star(86, 12, 5 + p.wave(2) * 1.5, const Color(0xFFFFEB3B));
  }),
  'lens': (k, p) => k.alive(p, () {
    k.circle(50, 58, 28, const Color(0xFF90A4AE));
    k.circle(50, 58, 23, const Color(0xFFE1F5FE));
    final sweep = p.cycle(.3);
    k.shine(36 + sweep * 20, 46 + sweep * 10, 6, 3);
    k.eyes(50, 58, 18, 6, p);
  }),
  'tube': (k, p) => k.alive(p, () {
    k.at(50, 60, () {
      k.rect(-14, -32, 28, 64, 4, const Color(0xFFD7A86E));
      k.oval(0, -32, 14, 5, const Color(0xFF8D6E63));
      k.face(0, 4, 10, p);
    }, rot: p.act ? p.t * 2 : .2);
  }),
  'moon': (k, p) => k.alive(p, () {
    k.glow(50, 50, 46, const Color(0xFFFFF59D), .35 + p.wave(.3) * .08);
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: const Offset(50, 50), radius: 32)),
      Path()..addOval(Rect.fromCircle(center: const Offset(66, 40), radius: 28)),
    );
    k.blob(crescent, const Color(0xFFFFE082));
    k.at(32, 52, () {
      k.eyes(0, 0, 0, 3.6, p);
      k.mouth(4, 10, 6, p);
    });
    for (var i = 0; i < 3; i++) {
      final tw = (p.wave(1, i / 3) + 1) / 2;
      k.star(78 + i * 6.0, 66 + i * 10.0, 2 + tw * 2.5, const Color(0xFFFFF59D), line: false);
    }
  }, shadowW: 0),
  'star': (k, p) => k.alive(p, () {
    final tw = (p.wave(1.2) + 1) / 2;
    k.glow(50, 54, 40, const Color(0xFFFFF59D), .3 + tw * .2);
    k.star(50, 54, 32 + tw * 2, const Color(0xFFFFD54F), rot: p.act ? p.t * 2 : p.wave(.3) * .1);
    k.shine(40, 42, 6, 3);
    k.face(50, 56, 11, p);
  }),

  // ── موسیقی ──
  'drum': (k, p) {
    final hit = p.act ? p.cycle(2.5) : 1.0;
    k.alive(p, () {
      k.rect(18, 46, 64, 40, 8, const Color(0xFFE53935));
      for (var i = 0; i < 5; i++) {
        k.stroke([Offset(22 + i * 14.0, 50), Offset(28 + i * 14.0, 82)], Colors.white, 1.6);
      }
      k.oval(50, 46, 32, 9, const Color(0xFFFFF8E1));
      if (hit < .2) {
        k.oval(50, 46, 32 * (1 + hit), 9 * (1 + hit), const Color(0x44FFFFFF), line: false);
        _note(k, 80, 26 - hit * 20, 4, const Color(0xFF7E57C2));
      }
      for (final s in <double>[-1, 1]) {
        final up = p.act ? (s < 0 ? hit : (hit + .5) % 1) : .4;
        k.at(50 + s * 14, 40, () {
          k.rect(-2, -30, 4, 30, 2, const Color(0xFFC68B4E));
          k.circle(0, -30, 4, const Color(0xFFFFF8E1));
        }, rot: s * .5 - up * s * .6);
      }
      k.face(50, 66, 12, p);
    });
  },
  'drum_skin': (k, p) => k.alive(p, () {
    k.oval(50, 64, 34, 22, const Color(0xFFFFF8E1));
    k.oval(50, 64, 28, 17, const Color(0xFFFFFDE7), line: false);
    k.face(50, 62, 12, p);
  }),
  'xylophone': (k, p) {
    final note = (p.t * 3).floor() % 6;
    k.alive(p, () {
      for (var i = 0; i < 6; i++) {
        final lift = p.act && i == note ? -3 : 0;
        k.rect(14 + i * 12.0, 40 + i * 3.0 + lift, 10, 48 - i * 6.0, 3, _rainbow[i]);
        k.c.drawCircle(Offset(19 + i * 12.0, 46 + i * 3.0 + lift), 1.4, Paint()..color = Colors.white);
      }
      k.rect(10, 52, 80, 4, 2, const Color(0xFF8D6E63));
      k.rect(10, 74, 80, 4, 2, const Color(0xFF8D6E63));
      if (p.act) {
        k.at(19 + note * 12.0, 30, () {
          k.rect(-1.5, -20, 3, 22, 1.5, const Color(0xFFC68B4E));
          k.circle(0, 2, 4, const Color(0xFFE91E63));
        }, rot: .4);
        _note(k, 22 + note * 12.0, 20 - p.cycle(3) * 10, 3.5, _rainbow[note]);
      }
      k.face(50, 66, 10, p);
    });
  },
  'bar_red': (k, p) => k.alive(p, () {
    k.at(50, 64, () {
      k.rect(-36, -9, 72, 18, 5, const Color(0xFFF44336));
      k.c.drawCircle(const Offset(-28, 0), 2, Paint()..color = Colors.white);
      k.c.drawCircle(const Offset(28, 0), 2, Paint()..color = Colors.white);
      k.face(0, -1, 8, p);
    }, rot: p.act ? p.wave(6) * .04 : 0);
    if (p.act) _note(k, 70, 40 - p.cycle(1.5) * 14, 4, const Color(0xFFF44336));
  }),
  'flute': (k, p) => k.alive(p, () {
    k.at(50, 58, () {
      k.rect(-40, -6, 80, 12, 6, const Color(0xFFC5E1A5));
      for (final x in <double>[-24, -12, 0, 12, 24]) {
        k.c.drawCircle(Offset(x, 0), 2.4, Paint()..color = const Color(0xFF33691E));
      }
      k.rect(-40, -6, 8, 12, 4, const Color(0xFF8BC34A));
    }, rot: -.2);
    if (p.act || p.happy) {
      for (var i = 0; i < 3; i++) {
        final d = p.cycle(.8, i / 3);
        _note(k, 80 + d * 10, 40 - d * 30 + math.sin(d * 8) * 3, 3.5, _rainbow[i * 2]);
      }
    }
    k.face(44, 72, 9, p);
  }),
  'reed': (k, p) => k.alive(p, () {
    k.at(50, 92, () {
      k.stroke([Offset.zero, const Offset(2, -40), const Offset(-2, -80)], const Color(0xFF7CB342), 6);
      k.at(0, -50, () => k.oval(10, 0, 12, 3, const Color(0xFF8BC34A)), rot: -.4);
      k.face(1, -34, 8, p);
    }, rot: p.wave(.5) * .08);
  }, shadowW: 24),
  'song': (k, p) => k.alive(p, () {
    for (var i = 0; i < 5; i++) {
      final d = p.cycle(.35, i / 5);
      _note(k, 18 + i * 16.0 + math.sin(d * 6) * 3, 84 - d * 60, 5, _rainbow[i], rot: math.sin(d * 4) * .3);
    }
  }, shadowW: 0),
  'note': (k, p) => k.alive(p, () {
    k.at(46, 72, () {
      k.stroke([const Offset(9, 0), const Offset(9, -46), const Offset(26, -38)], const Color(0xFF5E35B1), 5);
      k.oval(0, 0, 13, 10, const Color(0xFF7E57C2));
      k.at(0, 0, () => k.face(0, -1, 7, p));
    }, rot: -.15 + p.wave(.8) * .12);
  }, shadowW: 30),

  // ── شهر ──
  'bridge': (k, p) => k.alive(
    p,
    () {
      final water = Path()..moveTo(0, 86);
      for (var x = 0.0; x <= 100; x += 5) {
        water.lineTo(x, 84 + math.sin(x / 9 + p.t * 2) * 1.6);
      }
      water
        ..lineTo(100, 100)
        ..lineTo(0, 100)
        ..close();
      k.c.drawPath(water, Paint()..color = const Color(0xFF4FC3F7));
      final arch = Path()
        ..moveTo(6, 66)
        ..quadraticBezierTo(50, 34, 94, 66)
        ..lineTo(94, 74)
        ..quadraticBezierTo(50, 44, 6, 74)
        ..close();
      k.blob(arch, const Color(0xFFC68B4E));
      for (var i = 0; i < 7; i++) {
        final x = 14 + i * 12.0;
        final y = 66 - math.sin((x - 6) / 88 * math.pi) * 15;
        k.rect(x - 1.5, y - 14, 3, 14, 1, const Color(0xFF8D6E63));
      }
      k.stroke([for (var x = 12.0; x <= 88; x += 4) Offset(x, 52 - math.sin((x - 6) / 88 * math.pi) * 15)], const Color(0xFF8D6E63), 2.4);
      k.face(50, 56, 9, p);
    },
    shadowW: 0,
    squash: 0,
  ),
  'traffic_light': (k, p) {
    final phase = p.act ? (p.t * .8).floor() % 3 : 0;
    k.alive(p, () {
      k.rect(46, 70, 8, 22, 2, const Color(0xFF616161));
      k.rect(30, 8, 40, 66, 10, const Color(0xFF37474F));
      for (final (i, c) in const [Color(0xFFF44336), Color(0xFFFFEB3B), Color(0xFF4CAF50)].indexed) {
        final on = i == phase;
        if (on) k.glow(50, 22 + i * 19.0, 16, c, .7);
        k.circle(50, 22 + i * 19.0, 7.5, on ? c : shade(c, .6));
        if (on) k.at(50, 22 + i * 19.0, () => k.eyes(0, -1, 6, 2.2, p));
      }
    });
  },
  'light_red': (k, p) => _lamp(k, p, const Color(0xFFF44336)),
  'light_yellow': (k, p) => _lamp(k, p, const Color(0xFFFFEB3B)),
  'light_green': (k, p) => _lamp(k, p, const Color(0xFF4CAF50)),
  'letter': (k, p) => k.alive(p, () {
    final open = p.act ? p.cycle(.5) : 0.0;
    k.at(50, 60, () {
      if (open > .2) k.rect(-20, -20 - open * 16, 40, 30, 3, Colors.white);
      k.rect(-30, -20, 60, 40, 5, const Color(0xFFF48FB1));
      k.poly([const Offset(-30, -20), Offset(0, -20 + (open > 0 ? -12 : 16)), const Offset(30, -20)], const Color(0xFFF06292));
      k.heart(0, 6, 8, const Color(0xFFE53935));
    }, rot: p.wave(.5) * .08);
  }),
  'mailbox': (k, p) => k.alive(p, () {
    final flagUp = p.act || p.happy;
    k.rect(46, 66, 8, 26, 2, const Color(0xFF8D6E63));
    final box = Path()
      ..moveTo(22, 70)
      ..lineTo(22, 44)
      ..arcToPoint(const Offset(78, 44), radius: const Radius.circular(28))
      ..lineTo(78, 70)
      ..close();
    k.blob(box, const Color(0xFFE53935));
    k.at(80, 56, () {
      k.rect(0, -2, 4, 18, 1, const Color(0xFF616161));
      k.rect(0, -2, 12, 8, 1, const Color(0xFFFFEB3B));
    }, rot: flagUp ? 0 : 1.4);
    k.face(50, 52, 12, p);
  }),
  'invitation': (k, p) => k.alive(p, () {
    final open = p.act ? .2 + p.cycle(.4) * .8 : .25;
    k.at(50, 90, () {
      k.rect(-34, -60, 34, 60, 4, const Color(0xFFFFF59D));
      k.at(0, 0, () => k.rect(0, -60, 34, 60, 4, const Color(0xFF81D4FA)), sx: math.cos(open * math.pi * .45));
    });
    for (var i = 0; i < 3; i++) {
      k.at(24 + i * 12.0, 30 + p.wave(.6, i / 3) * 3, () {
        k.oval(0, 0, 5, 6, _rainbow[i * 2]);
        k.stroke([const Offset(0, 6), const Offset(1, 16)], const Color(0xFF8D6E63), .8);
      });
    }
    k.face(32, 64, 10, p);
  }),
  'feast': (k, p) => k.alive(p, () {
    k.rect(8, 66, 84, 10, 4, const Color(0xFFC68B4E));
    k.rect(14, 76, 6, 16, 2, const Color(0xFF8D6E63));
    k.rect(80, 76, 6, 16, 2, const Color(0xFF8D6E63));
    k.rect(6, 62, 88, 8, 4, const Color(0xFFFFCDD2));
    k.circle(28, 54, 9, const Color(0xFFFF9800));
    k.rect(42, 40, 18, 22, 4, const Color(0xFFF48FB1));
    k.oval(72, 56, 12, 6, const Color(0xFFE0A050));
    k.steam(72, 48, p, h: 14, n: 2, a: .4);
    k.rect(49, 30, 3, 10, 1, const Color(0xFF81D4FA));
    k.glow(50.5, 28, 6, const Color(0xFFFFE082), .7 + p.wave(5) * .2);
    k.face(50, 50, 8, p);
  }, squash: .01),
  'decorations': (k, p) => k.alive(p, () {
    k.stroke([const Offset(0, 16), Offset(50, 32 + p.wave(.5) * 2), const Offset(100, 16)], const Color(0xFF8D6E63), 1.4);
    for (var i = 0; i < 6; i++) {
      _pennant(k, p, 10 + i * 16.0, 18 + math.sin(i / 5 * math.pi) * 12, 10, _rainbow[i], i / 6);
    }
    for (final (x, c) in [(24.0, const Color(0xFFFF7043)), (76.0, const Color(0xFFFFCA28))]) {
      k.at(x, 56, () {
        k.glow(0, 0, 18, c, .5);
        k.oval(0, 0, 12, 14, c);
      }, rot: p.wave(.6, x) * .1);
    }
    k.at(50, 68, () {
      k.oval(0, 0, 11, 13, const Color(0xFF66BB6A));
      k.stroke([const Offset(0, 13), Offset(p.wave(1) * 2, 26)], const Color(0xFF8D6E63), .8);
    }, rot: p.wave(.7) * .1);
  }, squash: 0),
  'concert': (k, p) => k.alive(p, () {
    k.rect(6, 70, 88, 20, 4, const Color(0xFF8D6E63));
    k.rect(6, 18, 88, 6, 2, const Color(0xFFAB47BC));
    for (final x in <double>[6, 88]) {
      k.rect(x, 18, 6, 54, 2, const Color(0xFF7B1FA2));
    }
    for (var i = 0; i < 3; i++) {
      final sweep = p.wave(.4, i / 3) * .3;
      final beam = Path()
        ..moveTo(26 + i * 24.0, 24)
        ..lineTo(18 + i * 24.0 + sweep * 30, 70)
        ..lineTo(34 + i * 24.0 + sweep * 30, 70)
        ..close();
      k.c.drawPath(beam, Paint()..color = _rainbow[i * 2].withValues(alpha: .25));
    }
    k.rect(28, 56, 14, 14, 3, const Color(0xFFE53935));
    k.rect(54, 60, 24, 10, 2, const Color(0xFF42A5F5));
    for (var i = 0; i < 2; i++) {
      final d = p.cycle(.6, i / 2);
      _note(k, 40 + i * 20.0, 50 - d * 26, 3.5, _rainbow[i + 3]);
    }
  }, squash: 0),
  'medal': (k, p) => k.alive(p, () {
    k.poly([const Offset(34, 8), const Offset(46, 8), const Offset(56, 46), const Offset(44, 46)], const Color(0xFF1E88E5));
    k.poly([const Offset(66, 8), const Offset(54, 8), const Offset(44, 46), const Offset(56, 46)], const Color(0xFFE53935));
    final turn = p.act || p.happy ? math.cos(p.t * 3) : 1.0;
    k.at(50, 64, () {
      k.glow(0, 0, 34, const Color(0xFFFFF59D), .4);
      k.circle(0, 0, 22, const Color(0xFFFFC107));
      k.circle(0, 0, 16, const Color(0xFFFFD54F));
      k.star(0, 0, 11, const Color(0xFFFFA000));
      k.shine(-8, -8, 5, 3);
    }, sx: turn.abs() * .9 + .1);
  }),
  'firework': (k, p) => k.alive(
    p,
    () {
      for (var b = 0; b < 3; b++) {
        final d = p.cycle(.5, b / 3);
        final o = Offset(26 + b * 24.0, 30 + (b % 2) * 18.0);
        for (var i = 0; i < 10; i++) {
          final a = i / 10 * math.pi * 2;
          final r = d * 20;
          k.c.drawCircle(
            o + Offset(math.cos(a), math.sin(a)) * r,
            2.4 * (1 - d) + .5,
            Paint()..color = _rainbow[(i + b * 2) % 6].withValues(alpha: 1 - d * .8),
          );
        }
        k.star(o.dx, o.dy, 3 * (1 - d), Colors.white, line: false);
      }
      final up = p.cycle(.8);
      k.stroke([Offset(50, 96 - up * 30), Offset(50, 100 - up * 30)], const Color(0xFFFFEB3B), 2);
    },
    shadowW: 0,
    squash: 0,
  ),

  // ── اسباب‌بازی‌ها ──
  'bubbles': (k, p) => k.alive(p, () {
    k.at(30, 70, () {
      k.rect(-2, 0, 4, 26, 2, const Color(0xFFF06292));
      k.c.drawCircle(
        const Offset(0, -6),
        8,
        Paint()
          ..color = const Color(0xFFF06292)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }, rot: -.4 + p.wave(.5) * .1);
    for (var i = 0; i < 5; i++) {
      final d = p.cycle(.3, i / 5);
      final o = Offset(34 + d * 50 + math.sin(d * 9 + i) * 4, 60 - d * 50);
      final r = 5 + i % 3 * 3.0;
      k.c.drawCircle(
        o,
        r,
        Paint()
          ..shader = SweepGradient(colors: [..._rainbow, _rainbow.first].map((c) => c.withValues(alpha: .5)).toList())
              .createShader(Rect.fromCircle(center: o, radius: r))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      k.c.drawCircle(o + Offset(-r * .35, -r * .35), r * .2, Paint()..color = Colors.white.withValues(alpha: .8));
    }
  }, shadowW: 24),
  'soap_bottle': (k, p) => k.alive(p, () {
    k.rect(42, 14, 16, 12, 3, const Color(0xFFF06292));
    k.rect(30, 26, 40, 64, 12, const Color(0xFF80DEEA));
    k.rect(30, 56, 40, 34, 12, const Color(0xFFB2EBF2), line: false);
    final d = p.cycle(.6);
    k.c.drawCircle(
      Offset(56, 12 - d * 14),
      3 + d * 2,
      Paint()
        ..color = const Color(0x8890CAF9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    k.face(50, 50, 12, p);
  }),
  'necklace': (k, p) => k.alive(p, () {
    for (var i = 0; i < 12; i++) {
      final a = math.pi * .15 + i / 11 * math.pi * .7 + p.wave(.4) * .03;
      k.circle(50 + math.cos(a) * 34, 24 + math.sin(a) * 52, 5, _rainbow[i % 6]);
    }
    k.heart(50, 82, 7, const Color(0xFFE91E63));
  }),
  'bead': (k, p) => k.alive(p, () {
    k.at(50, 62, () {
      k.circle(0, 0, 22, const Color(0xFF7E57C2));
      k.circle(0, 0, 5, const Color(0xFF4527A0));
      k.shine(-8, -9, 6, 3);
    }, rot: p.act ? p.t * 3 : 0);
    k.face(50, 68, 10, p);
  }),
  'kite': (k, p) => k.alive(p, () {
    final sw = p.wave(.5) * .15;
    k.at(50, 42, () {
      k.stroke([const Offset(0, 30), Offset(p.wave(1) * 6, 44), Offset(-p.wave(1) * 6, 58)], const Color(0xFF8D6E63), 1.4);
      for (var i = 0; i < 3; i++) {
        k.at(
          p.wave(1, i / 3) * 5,
          38 + i * 10.0,
          () => k.poly([const Offset(-4, -3), const Offset(4, 3), const Offset(4, -3), const Offset(-4, 3)], _rainbow[i * 2]),
        );
      }
      k.poly([const Offset(0, -34), const Offset(26, 0), const Offset(0, 30), const Offset(-26, 0)], const Color(0xFFE53935));
      k.poly([const Offset(0, -34), const Offset(26, 0), const Offset(0, 0)], const Color(0xFFFFCA28), line: false);
      k.poly([const Offset(0, 30), const Offset(-26, 0), const Offset(0, 0)], const Color(0xFF42A5F5), line: false);
      k.face(0, 0, 9, p);
    }, rot: sw);
  }, shadowW: 30),
  'robot': (k, p) => _robot(k, p, head: true, body: true),
  'robot_head': (k, p) => _robot(k, p, head: true, body: false),
  'robot_body': (k, p) => _robot(k, p, head: false, body: true),
  'dollhouse': (k, p) => k.alive(p, () {
    k.rect(18, 40, 64, 52, 4, const Color(0xFFF8BBD0));
    k.poly([const Offset(12, 44), const Offset(50, 12), const Offset(88, 44)], const Color(0xFFE91E63));
    final lit = p.act || p.happy;
    for (final (x, y) in [(26.0, 48.0), (58.0, 48.0)]) {
      if (lit) k.glow(x + 8, y + 7, 14, const Color(0xFFFFF59D), .6);
      k.rect(x, y, 16, 14, 3, lit ? const Color(0xFFFFF59D) : const Color(0xFF81D4FA));
    }
    k.rect(42, 70, 16, 22, 3, const Color(0xFF8D6E63));
    k.circle(54, 81, 1.4, const Color(0xFFFFEB3B));
    final smoke = p.cycle(.6);
    k.rect(66, 16, 8, 16, 2, const Color(0xFF8D6E63));
    k.c.drawCircle(Offset(70, 12 - smoke * 10), 3 + smoke * 3, Paint()..color = Colors.white.withValues(alpha: .6 * (1 - smoke)));
    k.face(50, 30, 8, p);
  }),
  'bug_book': (k, p) => k.alive(p, () {
    final page = p.act ? p.cycle(.6) : 0.0;
    k.rect(16, 30, 68, 56, 6, const Color(0xFF66BB6A));
    k.rect(20, 34, 60, 48, 4, Colors.white);
    k.at(50, 34, () => k.rect(0, 0, 30, 48, 3, const Color(0xFFF1F8E9)), sx: math.cos(page * math.pi));
    k.circle(34, 50, 5, const Color(0xFFE53935));
    k.circle(66, 64, 4, const Color(0xFFFFCA28));
    k.face(40, 68, 9, p);
  }),
  'photo_frame': (k, p) => k.alive(p, () {
    k.rect(18, 22, 64, 66, 6, const Color(0xFFFF7043));
    k.rect(26, 30, 48, 50, 3, const Color(0xFFB3E5FC));
    k.oval(50, 80, 22, 10, const Color(0xFF81C784), line: false);
    k.circle(62, 44, 6, const Color(0xFFFFEB3B), line: false);
    k.circle(42, 58, 8, const Color(0xFFFF9800));
    k.at(42, 58, () => k.eyes(0, -1, 6, 2, p));
    if (p.act) k.glow(50, 50, 40, Colors.white, .5 * (1 - p.cycle(1)));
  }),
  'rag_doll': (k, p) => k.alive(p, () {
    final arm = p.happy ? 2.2 : .5 + p.wave(.4) * .1;
    for (final s in <double>[-1, 1]) {
      k.at(50 + s * 14, 58, () => k.rect(-3.5, 0, 7, 22, 3.5, const Color(0xFFFFCCBC)), rot: s * arm);
      k.rect(50 + s * 8 - 4, 80, 8, 12, 3, const Color(0xFFFFCCBC));
    }
    k.poly([const Offset(36, 54), const Offset(64, 54), const Offset(70, 84), const Offset(30, 84)], const Color(0xFFE57373));
    for (var i = 0; i < 6; i++) {
      final a = math.pi + i / 5 * math.pi;
      k.circle(50 + math.cos(a) * 18, 36 + math.sin(a) * 18 + 4, 6, const Color(0xFFFF8F00));
    }
    k.circle(50, 38, 16, const Color(0xFFFFE0B2));
    for (final s in <double>[-1, 1]) {
      k.stroke([Offset(50 + s * 6 - 2, 34), Offset(50 + s * 6 + 2, 38)], const Color(0xFF3E2723), 1.4);
      k.stroke([Offset(50 + s * 6 + 2, 34), Offset(50 + s * 6 - 2, 38)], const Color(0xFF3E2723), 1.4);
    }
    k.cheeks(50, 43, 20, 2.6);
    k.mouth(50, 46, 6, p);
  }),
  'windmill': (k, p) => k.alive(p, () {
    k.poly([const Offset(38, 92), const Offset(44, 40), const Offset(56, 40), const Offset(62, 92)], const Color(0xFFFFF3E0));
    k.rect(46, 74, 8, 18, 3, const Color(0xFF8D6E63));
    final spin = p.t * (p.act ? 8 : 1.2);
    k.at(50, 38, () {
      for (var i = 0; i < 4; i++) {
        k.at(
          0,
          0,
          () => k.poly([const Offset(-3, 0), const Offset(3, 0), const Offset(8, -32), const Offset(-4, -32)], _rainbow[i]),
          rot: i * math.pi / 2,
        );
      }
      k.circle(0, 0, 5, const Color(0xFF8D6E63));
    }, rot: spin);
    k.face(50, 60, 8, p);
  }),
  'ball': (k, p) => k.alive(p, () {
    k.at(50, 62, () {
      k.circle(0, 0, 28, Colors.white);
      for (var i = 0; i < 3; i++) {
        final sector = Path()
          ..moveTo(0, 0)
          ..arcTo(Rect.fromCircle(center: Offset.zero, radius: 27), i * math.pi * 2 / 3, math.pi / 3, false)
          ..close();
        k.c.drawPath(sector, Paint()..color = _rainbow[i * 2]);
      }
      k.circle(0, 0, 5, const Color(0xFFFFEB3B));
      k.shine(-10, -12, 7, 4);
    }, rot: p.act || p.happy ? p.t * 4 : p.wave(.3) * .3);
  }, squash: .06),
  'balloon': (k, p) => k.alive(p, () {
    final sw = p.wave(.6) * .1;
    k.at(50, 44, () {
      k.stroke([const Offset(0, 30), Offset(p.wave(1) * 4, 42), Offset(-p.wave(1) * 3, 52)], const Color(0xFF9E9E9E), 1.2);
      k.poly([const Offset(-3, 30), const Offset(3, 30), const Offset(0, 26)], const Color(0xFFD32F2F));
      k.oval(0, 0, 22, 27, const Color(0xFFE53935));
      k.shine(-8, -12, 5, 8);
      k.face(0, 2, 11, p);
    }, rot: sw);
  }, shadowW: 26),
};

void _lamp(Pen k, ToonPose p, Color c) => k.alive(p, () {
  final on = p.act || p.happy || p.mood == ToonMood.idle;
  if (on) k.glow(50, 56, 38, c, .45 + p.wave(1) * .1);
  k.circle(50, 56, 26, const Color(0xFF37474F));
  k.circle(50, 56, 19, c);
  k.shine(42, 48, 5, 3);
  k.at(50, 56, () => k.face(0, 0, 10, p));
});

void _robot(Pen k, ToonPose p, {required bool head, required bool body}) => k.alive(p, () {
  final walk = p.act ? p.wave(2) * 3 : 0.0;
  if (body) {
    for (final s in <double>[-1, 1]) {
      k.rect(50 + s * 9 - 4, 78 + (s * walk).clamp(-3, 0), 8, 14, 2, const Color(0xFF78909C));
    }
    for (final s in <double>[-1, 1]) {
      k.at(50 + s * 20, 56, () {
        k.rect(-3, 0, 6, 18, 3, const Color(0xFF90A4AE));
        k.circle(0, 20, 4, const Color(0xFFFF7043));
      }, rot: s * (p.happy ? 2.4 : .3 + walk * .05));
    }
    k.rect(32, 52, 36, 30, 6, const Color(0xFF42A5F5));
    for (var i = 0; i < 3; i++) {
      k.circle(42 + i * 8.0, 66, 2.6, (p.t * 3).floor() % 3 == i ? const Color(0xFF76FF03) : const Color(0xFF1565C0), line: false);
    }
  }
  if (head) {
    final y = body ? 0.0 : 30.0;
    k.at(0, y, () {
      k.stroke([const Offset(50, 20), const Offset(50, 10)], const Color(0xFF78909C), 2);
      k.circle(50, 9, 3 + (p.act ? p.wave(3).abs() * 1.5 : 0), const Color(0xFFE53935));
      k.rect(32, 20, 36, 30, 8, const Color(0xFF90CAF9));
      k.rect(36, 26, 28, 16, 6, const Color(0xFF263238), line: false);
      for (final x in <double>[44, 56]) {
        k.c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, 33), width: 6, height: 6 * (1 - p.blink * .9)),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF76FF03),
        );
      }
      k.mouth(50, 44, 8, p, color: const Color(0xFF263238));
    });
  }
});
