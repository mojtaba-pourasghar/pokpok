import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'toon.dart';

/// ابزارها، قطعه‌ها و وسیله‌های نقلیه.

const _wood = Color(0xFFC68B4E);
const _metal = Color(0xFFB0BEC5);

/// بدنه‌ی ماشین با چرخ‌هایی که می‌چرخند، تکان فنری، دود اگزوز و چراغ جلو.
void _vehicle(
  Pen k,
  ToonPose p, {
  required void Function(double bounce) body,
  required List<(double, double)> wheels,
  double wheelR = 11,
  double speed = 1,
  double exhaustX = 10,
  double exhaustY = 78,
  bool smoke = true,
}) {
  final drive = p.act ? speed * 9 : (p.happy ? 3 : 0);
  final bounce = p.act ? p.wave(5).abs() * 2.2 : p.breath * .8;
  k.shadow(50, 84);
  if (smoke && p.act) {
    for (var i = 0; i < 4; i++) {
      final d = p.cycle(1.6, i / 4);
      k.c.drawCircle(
        Offset(exhaustX - d * 16, exhaustY - d * 10),
        3 + d * 6,
        Paint()..color = const Color(0xFFB0BEC5).withValues(alpha: .6 * (1 - d)),
      );
    }
  }
  k.at(0, -bounce, () => body(bounce), rot: p.sad ? .04 : 0);
  for (final (x, y) in wheels) {
    k.wheel(x, y, wheelR, p.t * drive);
  }
}

/// چراغ جلو که در حرکت می‌درخشد.
void _headlight(Pen k, ToonPose p, double x, double y) {
  k.circle(x, y, 4, const Color(0xFFFFF59D));
  if (p.act) k.glow(x + 6, y, 16, const Color(0xFFFFF59D), .55);
}

final Map<String, ToonPainter> workshopToons = {
  'hammer': (k, p) {
    final swing = p.act ? (math.sin(p.t * math.pi * 3) + 1) / 2 : 0.0;
    k.alive(p, () {
      k.at(56, 88, () {
        k.rect(-5, -64, 10, 64, 4, _wood);
        k.rect(-22, -76, 44, 18, 5, const Color(0xFF78909C));
        k.rect(18, -74, 8, 14, 3, const Color(0xFF607D8B));
        k.shine(-12, -72, 8, 2.5, rot: 0);
        k.face(0, -66, 10, p);
      }, rot: -.3 + swing * -.7 + (p.act ? 0 : p.wave(.4) * .05));
      if (p.act && swing < .1) k.star(20, 88, 6, const Color(0xFFFFEB3B));
    });
  },
  'hammer_head': (k, p) => k.alive(p, () {
    k.rect(18, 52, 64, 26, 7, const Color(0xFF78909C));
    k.rect(76, 54, 10, 22, 3, const Color(0xFF607D8B));
    k.rect(44, 70, 12, 8, 2, const Color(0xFF455A64));
    k.shine(32, 58, 10, 3, rot: 0);
    k.face(46, 64, 13, p);
  }),
  'hammer_handle': (k, p) => k.alive(p, () {
    k.at(50, 90, () {
      k.rect(-8, -78, 16, 78, 7, const Color(0xFFC68B4E));
      k.rect(-9, -20, 18, 20, 6, const Color(0xFF8D5524));
      for (var y = -70.0; y < -24; y += 12) {
        k.stroke([Offset(-5, y), Offset(5, y + 5)], const Color(0xFFA0683A), 1.4);
      }
      k.face(0, -48, 11, p);
    }, rot: .12 + p.wave(.4) * .05);
  }),
  'screw': (k, p) => k.alive(p, () {
    final turn = p.act ? p.t * 6 : 0.0;
    k.at(50, 70, () {
      k.poly([const Offset(-8, -6), const Offset(8, -6), const Offset(2, 22), const Offset(-2, 22)], _metal);
      for (var y = -2.0; y < 18; y += 5) {
        k.stroke(
          [Offset(-7 + y * .25, y + math.sin(turn) * 1.5), Offset(7 - y * .25, y + 3 + math.sin(turn) * 1.5)],
          const Color(0xFF78909C),
          1.6,
        );
      }
      k.oval(0, -10, 18, 7, const Color(0xFFCFD8DC));
      k.at(0, -10, () => k.stroke([const Offset(-10, 0), const Offset(10, 0)], const Color(0xFF546E7A), 2.4), rot: turn, sy: .4);
    });
    k.face(50, 46, 10, p);
  }, shadowW: 36),
  'nail': (k, p) => k.alive(p, () {
    final sink = p.act ? p.cycle(1.5) * 10 : 0.0;
    k.at(50, 30 + sink, () {
      k.oval(0, 0, 14, 4, const Color(0xFFCFD8DC));
      k.poly([const Offset(-3, 2), const Offset(3, 2), const Offset(1, 56), const Offset(-1, 56)], _metal);
      k.shine(-6, -1, 5, 1.2, rot: 0);
    });
    k.face(50, 50, 9, p);
  }, shadowW: 24),
  'plank': (k, p) => k.alive(p, () {
    k.at(50, 66, () {
      k.rect(-44, -13, 88, 26, 5, const Color(0xFFC68B4E));
      for (final x in <double>[-30, -2, 22]) {
        k.stroke([Offset(x, -7), Offset(x + 10, -4), Offset(x + 18, -8)], const Color(0xFFA0683A), 1.6);
        k.stroke([Offset(x + 4, 6), Offset(x + 14, 8)], const Color(0xFFA0683A), 1.2);
      }
      k.oval(-32, 0, 4, 3, const Color(0xFF8D5A2B));
      k.face(6, 0, 13, p);
    }, rot: -.06 + p.wave(.4) * .03);
  }),
  'flashlight': (k, p) => k.alive(p, () {
    final on = p.act || p.happy;
    if (on) {
      final beam = Path()
        ..moveTo(70, 46)
        ..lineTo(100, 26)
        ..lineTo(100, 74)
        ..lineTo(70, 56)
        ..close();
      k.c.drawPath(beam, Paint()..color = const Color(0xFFFFF59D).withValues(alpha: .45 + p.wave(2) * .08));
    }
    k.rect(16, 42, 44, 18, 8, const Color(0xFFFFCA28));
    k.poly([const Offset(58, 40), const Offset(72, 34), const Offset(72, 68), const Offset(58, 62)], const Color(0xFFFFB300));
    k.oval(72, 51, 3, 16, on ? const Color(0xFFFFFDE7) : const Color(0xFFE0E0E0));
    k.rect(32, 38, 10, 6, 2, on ? const Color(0xFFE53935) : const Color(0xFF9E9E9E));
    k.face(36, 52, 10, p);
  }),
  'battery': (k, p) => k.alive(p, () {
    k.rect(44, 18, 12, 8, 3, const Color(0xFFBDBDBD));
    k.rect(32, 24, 36, 66, 8, const Color(0xFF424242));
    k.rect(32, 24, 36, 22, 8, const Color(0xFFFFB300));
    final charge = p.act ? p.cycle(.8) : 1.0;
    for (var i = 0; i < 3; i++) {
      k.rect(38, 78 - i * 10.0, 24, 6, 2, i / 3 < charge ? const Color(0xFF76FF03) : const Color(0xFF616161), line: false);
    }
    k.face(50, 52, 12, p);
  }),
  'bulb': (k, p) => k.alive(p, () {
    final on = p.act || p.happy;
    if (on) k.glow(50, 42, 40, const Color(0xFFFFF176), .7 + p.wave(1.5) * .1);
    k.circle(50, 42, 24, on ? const Color(0xFFFFF59D) : const Color(0xFFE3F2FD));
    k.stroke(
      [const Offset(44, 54), const Offset(46, 42), const Offset(50, 48), const Offset(54, 42), const Offset(56, 54)],
      on ? const Color(0xFFFF8F00) : const Color(0xFF90A4AE),
      1.8,
    );
    k.rect(40, 62, 20, 18, 4, const Color(0xFF9E9E9E));
    for (final y in <double>[66, 72]) {
      k.stroke([Offset(40, y), Offset(60, y + 2)], const Color(0xFF616161), 1.4);
    }
    k.rect(44, 80, 12, 6, 3, const Color(0xFF616161));
    k.shine(40, 30, 5, 7);
    k.face(50, 36, 11, p);
  }),
  'cart': (k, p) => _vehicle(
    k,
    p,
    smoke: false,
    wheels: [(30, 82), (70, 82)],
    wheelR: 12,
    body: (b) {
      k.stroke([const Offset(88, 66), const Offset(98, 56)], const Color(0xFF8D5A2B), 3);
      k.rect(14, 48, 72, 28, 5, _wood);
      for (final x in <double>[30, 50, 70]) {
        k.stroke([Offset(x, 50), Offset(x, 74)], const Color(0xFFA0683A), 1.6);
      }
      k.face(50, 62, 11, p);
    },
  ),
  'wheel': (k, p) => k.alive(p, () {
    k.wheel(50, 62, 26, p.act ? p.t * 8 : p.wave(.3) * .4);
    k.at(50, 62, () => k.face(0, 0, 8, p));
  }),
  'box': (k, p) => k.alive(p, () {
    final flap = p.act ? (p.wave(2) + 1) * .3 : 0.0;
    k.at(
      22,
      40,
      () => k.poly([Offset.zero, const Offset(-14, -10), const Offset(10, -10), const Offset(28, 0)], const Color(0xFFC49A6C)),
      rot: -flap,
    );
    k.at(
      78,
      40,
      () => k.poly([Offset.zero, const Offset(14, -10), const Offset(-10, -10), const Offset(-28, 0)], const Color(0xFFC49A6C)),
      rot: flap,
    );
    k.rect(22, 40, 56, 50, 4, const Color(0xFFD7A86E));
    k.rect(44, 40, 12, 22, 0, const Color(0xFFE6C29A), line: false);
    k.face(50, 70, 13, p);
  }),
  'toy_car': (k, p) => _toyCar(k, p, wheels: true),
  'car_body': (k, p) => _toyCar(k, p, wheels: false),
  'car_key': (k, p) => k.alive(p, () {
    k.at(
      50,
      58,
      () {
        k.rect(-4, -4, 8, 34, 3, const Color(0xFFFFC107));
        for (final s in <double>[-1, 1]) {
          k.oval(s * 14, -12, 13, 9, const Color(0xFFFFD54F));
          k.c.drawCircle(Offset(s * 15, -12), 3.4, Paint()..color = const Color(0xFFFFF8E1));
        }
        k.circle(0, -4, 6, const Color(0xFFFFB300));
      },
      rot: p.act ? p.t * 5 : p.wave(.5) * .2,
      sx: p.act ? math.cos(p.t * 5).abs() * .5 + .5 : 1,
    );
  }, shadowW: 40),
  'junk_spoon': (k, p) => k.alive(p, () {
    k.at(50, 60, () {
      k.oval(0, -26, 14, 19, const Color(0xFFCFD8DC));
      k.oval(0, -24, 9, 13, const Color(0xFFB0BEC5), line: false);
      k.rect(-4, -8, 8, 46, 4, const Color(0xFFCFD8DC));
      k.face(0, -24, 9, p);
    }, rot: .45 + p.wave(.4) * .06);
  }, shadowW: 36),
  'junk_sock': (k, p) => k.alive(p, () {
    k.at(50, 60, () {
      final sock = Path()
        ..moveTo(-12, -30)
        ..lineTo(10, -30)
        ..lineTo(10, 8)
        ..quadraticBezierTo(30, 10, 30, 22)
        ..quadraticBezierTo(30, 32, 6, 30)
        ..quadraticBezierTo(-12, 30, -12, 14)
        ..close();
      k.blob(sock, const Color(0xFF4FC3F7));
      for (final y in <double>[-22, -10, 2]) {
        k.rect(-12, y, 22, 5, 0, const Color(0xFFFF7043), line: false);
      }
      k.face(-1, 8, 9, p);
    }, rot: p.wave(.5) * .08);
  }),
  'saw': (k, p) {
    final cut = p.act ? p.wave(2.5) * 8 : 0.0;
    k.alive(p, () {
      k.at(50 + cut, 60, () {
        final blade = Path()
          ..moveTo(-38, -10)
          ..lineTo(18, -14)
          ..lineTo(18, 10)
          ..lineTo(-38, 4)
          ..close();
        k.blob(blade, const Color(0xFFCFD8DC));
        for (var x = -36.0; x < 16; x += 6) {
          k.poly(
            [Offset(x, 4 - (x + 38) * .1), Offset(x + 3, 9 - (x + 38) * .1), Offset(x + 6, 4 - (x + 38) * .1)],
            const Color(0xFF90A4AE),
            line: false,
          );
        }
        k.rect(14, -16, 26, 28, 9, const Color(0xFFD84315));
        k.oval(28, -2, 6, 7, const Color(0xFFFFCCBC), line: false);
        k.face(-12, -4, 9, p);
      }, rot: -.1);
      if (p.act) {
        for (var i = 0; i < 3; i++) {
          final d = p.cycle(2, i / 3);
          k.c.drawCircle(Offset(22 + i * 3.0, 74 + d * 14), 1.6, Paint()..color = const Color(0xFFD7A86E));
        }
      }
    });
  },
  'drill': (k, p) => k.alive(p, () {
    final spin = p.act ? p.t * 30 : 0.0;
    k.rect(36, 56, 18, 34, 6, const Color(0xFF424242));
    k.rect(20, 38, 54, 22, 9, const Color(0xFF43A047));
    k.rect(72, 44, 8, 10, 2, const Color(0xFF616161));
    k.at(80, 49, () {
      k.rect(0, -2.5, 16, 5, 1, _metal);
      for (var x = 2.0; x < 16; x += 4) {
        k.stroke([Offset(x, -2.5 + math.sin(spin + x) * .5), Offset(x + 2, 2.5)], const Color(0xFF78909C), 1.2);
      }
    });
    k.face(42, 48, 10, p);
    if (p.act) k.stroke([const Offset(96, 40), const Offset(98, 36)], const Color(0xFFFFEB3B), 1.6);
  }),
  'wrench': (k, p) => k.alive(p, () {
    k.at(50, 58, () {
      k.rect(-5, -8, 10, 46, 5, const Color(0xFF90A4AE));
      // سر آچار با دهانه‌ی باز
      final jaw = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: const Offset(0, -18), radius: 15)),
        Path()..addRect(const Rect.fromLTWH(-5, -36, 10, 16)),
      );
      k.blob(jaw, const Color(0xFF90A4AE));
      k.circle(0, 32, 5, const Color(0xFF78909C));
      k.c.drawCircle(const Offset(0, 32), 2.4, Paint()..color = const Color(0xFFECEFF1));
      k.at(0, 10, () => k.face(0, 0, 8, p));
    }, rot: p.act ? p.wave(1.5) * .6 : .45 + p.wave(.4) * .05);
  }, shadowW: 40),
  'glue_gun': (k, p) => k.alive(p, () {
    k.rect(30, 56, 16, 32, 6, const Color(0xFFFFA726));
    k.rect(18, 36, 60, 24, 10, const Color(0xFFFF7043));
    k.poly([const Offset(76, 44), const Offset(90, 48), const Offset(76, 52)], _metal);
    k.rect(8, 42, 12, 10, 3, const Color(0xFFFFF59D));
    if (p.act) {
      final d = p.cycle(1);
      k.c.drawOval(Rect.fromCenter(center: Offset(91, 52 + d * 10), width: 5, height: 6 + d * 4), Paint()..color = const Color(0xEEFFFFFF));
    }
    k.face(46, 48, 10, p);
  }),
  'magnifier': (k, p) => k.alive(p, () {
    k.at(50, 54, () {
      k.rect(14, 14, 10, 34, 5, _wood);
      k.circle(0, 0, 24, const Color(0xFF8D6E63));
      k.circle(0, 0, 19, const Color(0xFFE1F5FE));
      k.shine(-8, -8, 7, 4);
      k.eyes(0, 2, 18, 7, p);
    }, rot: -.5 + (p.act ? p.wave(1) * .2 : p.wave(.4) * .05));
  }),
  'magnet': (k, p) => k.alive(p, () {
    final pull = p.act ? p.cycle(1.2) : 0.0;
    final m = Path()
      ..moveTo(18, 48)
      ..addArc(Rect.fromCircle(center: const Offset(50, 48), radius: 32), math.pi, math.pi)
      ..lineTo(82, 82)
      ..lineTo(64, 82)
      ..lineTo(64, 48)
      ..arcTo(Rect.fromCircle(center: const Offset(50, 48), radius: 14), 0, -math.pi, false)
      ..lineTo(36, 82)
      ..lineTo(18, 82)
      ..close();
    k.blob(m, const Color(0xFFE53935));
    k.rect(18, 72, 18, 12, 2, const Color(0xFFCFD8DC));
    k.rect(64, 72, 18, 12, 2, const Color(0xFFCFD8DC));
    if (p.act) {
      for (final x in <double>[27, 73]) {
        for (var i = 0; i < 2; i++) {
          k.stroke([Offset(x - 5, 88 + i * 4 + (1 - pull) * 3), Offset(x + 5, 88 + i * 4 + (1 - pull) * 3)], const Color(0xFFFFEB3B), 1.6);
        }
      }
    }
    k.face(50, 30, 11, p);
  }),
  'magnet_fish': (k, p) => k.alive(p, () {
    k.stroke([const Offset(20, 90), const Offset(40, 40), const Offset(76, 14)], const Color(0xFF8D6E63), 4);
    final bob = p.wave(.7) * 4;
    k.stroke([const Offset(76, 14), Offset(80, 50 + bob)], const Color(0xFF9E9E9E), 1.2);
    k.rect(75, 50 + bob, 10, 6, 2, const Color(0xFFE53935));
    k.at(68, 78, () {
      k.oval(0, 0, 12, 7, const Color(0xFF4FC3F7));
      k.poly([const Offset(10, 0), const Offset(18, -6), const Offset(18, 6)], const Color(0xFF4FC3F7));
      k.c.drawCircle(const Offset(-5, -1), 1.4, Paint()..color = Colors.black);
    }, rot: p.wave(1) * .15);
  }),
  'scissors': (k, p) {
    final snip = p.act ? (p.wave(3) + 1) * .22 : .14;
    k.alive(p, () {
      for (final s in <double>[-1, 1]) {
        k.at(50, 54, () {
          final blade = Path()
            ..moveTo(-3, 0)
            ..lineTo(3, 0)
            ..lineTo(1.5, -38)
            ..quadraticBezierTo(0, -42, -1, -38)
            ..close();
          k.blob(blade, const Color(0xFFCFD8DC));
          k.c.save();
          k.c.translate(s * 7, 20);
          final ring = Path()
            ..addOval(Rect.fromCenter(center: Offset.zero, width: 22, height: 18))
            ..addOval(Rect.fromCenter(center: Offset.zero, width: 12, height: 9))
            ..fillType = PathFillType.evenOdd;
          k.blob(ring, s < 0 ? const Color(0xFFE91E63) : const Color(0xFF29B6F6));
          k.c.restore();
          k.stroke([Offset(s * 2, 2), Offset(s * 6, 12)], s < 0 ? const Color(0xFFE91E63) : const Color(0xFF29B6F6), 5);
        }, rot: s * snip);
      }
      k.circle(50, 54, 3, const Color(0xFF616161));
      k.at(50, 30, () => k.eyes(0, 0, 0, 3.4, p));
    });
  },
  'sewing_machine': (k, p) => k.alive(p, () {
    final needle = p.act ? p.wave(4).abs() * 6 : 0.0;
    k.rect(8, 80, 84, 10, 4, const Color(0xFF8D6E63));
    // پایه و بازوی دستگاه
    final body = Path()
      ..moveTo(14, 80)
      ..lineTo(14, 30)
      ..quadraticBezierTo(14, 22, 22, 22)
      ..lineTo(76, 22)
      ..quadraticBezierTo(84, 22, 84, 30)
      ..lineTo(84, 46)
      ..lineTo(34, 46)
      ..lineTo(34, 80)
      ..close();
    k.blob(body, const Color(0xFFF06292));
    k.rect(36, 70, 52, 10, 3, const Color(0xFFF8BBD0));
    // سوزن و نخ
    k.rect(74, 46, 6, 8, 1.5, const Color(0xFFB0BEC5));
    k.stroke([const Offset(77, 54), Offset(77, 60 + needle)], const Color(0xFF78909C), 1.6);
    k.stroke([const Offset(30, 18), const Offset(50, 14), const Offset(77, 54)], const Color(0xFFE53935), .8);
    // قرقره‌ی نخ روی سر دستگاه
    k.rect(26, 10, 8, 12, 2, const Color(0xFFE53935));
    // چرخ دستی کنار
    k.at(10, 38, () {
      k.circle(0, 0, 8, const Color(0xFFB0BEC5));
      k.stroke([const Offset(-6, 0), const Offset(6, 0)], const Color(0xFF78909C), 1.6);
    }, rot: p.act ? p.t * 8 : 0);
    // پارچه‌ای که زیر سوزن رد می‌شود
    final shift = p.act ? p.cycle(.5) * 10 : 0.0;
    k.rect(54 - shift, 64, 30, 6, 1, const Color(0xFF81D4FA));
    k.at(50, 34, () => k.face(0, 0, 9, p));
  }),
  'tire': (k, p) {
    final puff = p.act ? .85 + p.cycle(.6) * .25 : 1.0;
    k.alive(p, () {
      k.at(
        50,
        60,
        () {
          k.circle(0, 0, 30, const Color(0xFF37474F));
          for (var i = 0; i < 12; i++) {
            final a = i * math.pi / 6 + (p.happy ? p.t * 4 : 0);
            k.stroke([Offset(math.cos(a) * 24, math.sin(a) * 24), Offset(math.cos(a) * 29, math.sin(a) * 29)], const Color(0xFF263238), 3);
          }
          k.circle(0, 0, 15, const Color(0xFFB0BEC5));
          k.circle(0, 0, 5, const Color(0xFF78909C));
        },
        sx: puff,
        sy: puff * (p.sad ? .8 : 1),
      );
      k.at(50, 60, () => k.eyes(0, -20, 18, 4.6, p));
    });
  },
  'fuel': (k, p) => k.alive(p, () {
    k.rect(26, 34, 50, 56, 8, const Color(0xFFE53935));
    k.rect(30, 22, 24, 10, 4, const Color(0xFFC62828));
    k.rect(60, 24, 10, 14, 3, const Color(0xFFFFCA28));
    k.stroke([const Offset(32, 44), const Offset(70, 82)], const Color(0xFFC62828), 3);
    k.stroke([const Offset(70, 44), const Offset(32, 82)], const Color(0xFFC62828), 3);
    k.face(51, 62, 13, p);
  }),
  'peg': (k, p) => k.alive(p, () {
    final sink = p.act ? p.cycle(1.5) * 8 : 0.0;
    k.at(50, 36 + sink, () {
      k.rect(-14, -6, 28, 10, 3, const Color(0xFFFFB300));
      k.poly([const Offset(-5, 4), const Offset(5, 4), const Offset(0, 50)], _metal);
      k.face(0, 0, 7, p);
    });
  }, shadowW: 24),
  'pole': (k, p) => k.alive(p, () {
    k.at(50, 92, () {
      k.rect(-4, -80, 8, 80, 4, const Color(0xFF90A4AE));
      k.circle(0, -80, 5, const Color(0xFFFF7043));
    }, rot: p.wave(.4) * .05);
  }, shadowW: 20),
  'rock': (k, p) => k.alive(p, () {
    k.poly(
      [const Offset(18, 88), const Offset(22, 62), const Offset(40, 46), const Offset(62, 44), const Offset(80, 58), const Offset(84, 88)],
      const Color(0xFF9E9E9E),
      smooth: true,
    );
    k.oval(36, 54, 8, 4, const Color(0xFF8BC34A), line: false);
    k.face(52, 68, 14, p.mood == ToonMood.idle ? ToonPose(p.t, mood: ToonMood.sad, seed: p.seed) : p);
  }, squash: .01),
  'cone': (k, p) => k.alive(p, () {
    k.rect(18, 82, 64, 9, 3, const Color(0xFFFF6D00));
    k.poly([const Offset(28, 84), const Offset(44, 16), const Offset(56, 16), const Offset(72, 84)], const Color(0xFFFF9100));
    k.poly([const Offset(36, 52), const Offset(64, 52), const Offset(67, 64), const Offset(33, 64)], Colors.white, line: false);
    k.poly([const Offset(41, 30), const Offset(59, 30), const Offset(61, 38), const Offset(39, 38)], Colors.white, line: false);
    k.face(50, 72, 9, p);
  }),
  'bus': (k, p) => _vehicle(
    k,
    p,
    wheels: [(26, 82), (74, 82)],
    wheelR: 10,
    exhaustX: 6,
    body: (b) {
      final body = Path()
        ..addRRect(
          RRect.fromRectAndCorners(
            const Rect.fromLTWH(6, 28, 88, 52),
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(20),
            bottomLeft: const Radius.circular(8),
            bottomRight: const Radius.circular(10),
          ),
        );
      k.blob(body, const Color(0xFFFFC928));
      k.rect(6, 64, 88, 6, 0, const Color(0xFFFF9F1C), line: false);
      // گلگیرها
      for (final x in <double>[26, 74]) {
        k.c.drawCircle(Offset(x, 82), 13, Paint()..color = shade(const Color(0xFFFFC928), .45));
      }
      // پنجره‌ها و مسافرها
      for (var i = 0; i < 3; i++) {
        final x = 12 + i * 17.0;
        k.rect(x, 36, 14, 16, 3, const Color(0xFFB3E5FC));
        final c = [const Color(0xFFA1704A), const Color(0xFFF7F3F0), const Color(0xFFB0BEC5)][i];
        final bob = p.wave(1.2, i / 3) * 1.2;
        k.circle(x + 7, 49 + bob, 5, c);
        k.c.drawCircle(Offset(x + 5.4, 48 + bob), .9, Paint()..color = Colors.black);
        k.c.drawCircle(Offset(x + 8.6, 48 + bob), .9, Paint()..color = Colors.black);
        k.shine(x + 4, 39, 2, 4, rot: .2);
      }
      // در
      k.rect(63, 36, 10, 30, 2, const Color(0xFF90CAF9));
      k.stroke([const Offset(68, 36), const Offset(68, 66)], const Color(0xFF5C9BD5), 1.2);
      // شیشه‌ی جلو با چشم‌ها
      k.rect(77, 34, 14, 22, 5, const Color(0xFFB3E5FC));
      k.at(84, 44, () => k.eyes(0, 0, 7, 2.8, p));
      k.mouth(84, 60, 6, p);
      k.rect(88, 70, 8, 6, 2, const Color(0xFFB0BEC5));
      _headlight(k, p, 92, 64);
      k.rect(4, 66, 5, 7, 2, const Color(0xFFE53935));
      k.rect(14, 26, 60, 4, 2, const Color(0xFFFFE082));
    },
  ),
  'train': (k, p) {
    final turn = p.act ? p.t * 8 : (p.happy ? p.t * 3 : 0.0);
    k.shadow(50, 86);
    final bounce = p.act ? p.wave(5).abs() * 1.6 : p.breath * .6;
    if (p.act || p.happy) {
      for (var i = 0; i < 5; i++) {
        final d = p.cycle(1.4, i / 5);
        k.c.drawCircle(
          Offset(68 - d * 34, 14 - d * 12 - bounce),
          4 + d * 7,
          Paint()..color = Colors.white.withValues(alpha: .85 * (1 - d)),
        );
      }
    }
    k.at(0, -bounce, () {
      // کابین
      k.rect(10, 34, 32, 44, 5, const Color(0xFFE53935));
      k.rect(6, 28, 40, 8, 3, const Color(0xFFB71C1C));
      k.rect(16, 42, 20, 16, 4, const Color(0xFFB3E5FC));
      k.at(26, 50, () => k.eyes(0, 0, 9, 3, p));
      k.mouth(26, 55, 5, p);
      // دیگ بخار با حلقه‌ها
      final boiler = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(40, 48, 46, 26), const Radius.circular(13)));
      k.blob(boiler, const Color(0xFF1E88E5));
      for (final x in <double>[52, 66]) {
        k.rect(x, 48, 3, 26, 1, const Color(0xFFFFC928), line: false);
      }
      k.rect(64, 30, 10, 20, 3, const Color(0xFF424242));
      k.rect(61, 26, 16, 6, 3, const Color(0xFF616161));
      k.circle(52, 46, 4, const Color(0xFFFFC928));
      // دماغه و جلو
      k.poly([const Offset(86, 66), const Offset(96, 82), const Offset(86, 82)], const Color(0xFF9E9E9E));
      _headlight(k, p, 88, 56);
    });
    // چرخ‌ها و میله‌ی رابط که با هم می‌چرخند
    final pts = <Offset>[];
    for (final (x, r) in [(22.0, 9.0), (48.0, 11.0), (74.0, 11.0)]) {
      k.wheel(x, 82, r, turn, tire: const Color(0xFFC62828), hub: const Color(0xFFFFE082));
      pts.add(Offset(x + math.cos(turn) * r * .5, 82 + math.sin(turn) * r * .5));
    }
    k.stroke([pts[1], pts[2]], const Color(0xFF9E9E9E), 2.4, smooth: false);
  },
  'rail': (k, p) => k.alive(p, () {
    for (var i = 0; i < 6; i++) {
      k.rect(14 + i * 13.0, 56, 7, 32, 2, _wood);
    }
    k.rect(8, 62, 84, 5, 2, const Color(0xFF90A4AE));
    k.rect(8, 76, 84, 5, 2, const Color(0xFF90A4AE));
  }, squash: 0),
  'rocket': (k, p) {
    final fly = p.act ? p.wave(6) * 1.5 : 0.0;
    k.alive(p, () {
      k.at(50 + fly, 50, () {
        if (p.act || p.happy) {
          final f = 1 + p.wave(9) * .15;
          k.at(0, 34, () {
            k.poly([const Offset(-10, 0), const Offset(0, 30), const Offset(10, 0)], const Color(0xFFFF9800));
            k.poly([const Offset(-5, 0), const Offset(0, 18), const Offset(5, 0)], const Color(0xFFFFF176), line: false);
          }, sy: f);
        }
        for (final s in <double>[-1, 1]) {
          k.poly([Offset(s * 12, 14), Offset(s * 24, 34), Offset(s * 12, 30)], const Color(0xFFE53935));
        }
        final body = Path()
          ..moveTo(0, -40)
          ..quadraticBezierTo(20, -20, 14, 32)
          ..lineTo(-14, 32)
          ..quadraticBezierTo(-20, -20, 0, -40)
          ..close();
        k.blob(body, const Color(0xFFECEFF1));
        k.c.save();
        k.c.clipPath(body);
        k.rect(-20, -42, 40, 14, 0, const Color(0xFFE53935), line: false);
        k.c.restore();
        k.circle(0, -6, 9, const Color(0xFF4FC3F7));
        k.at(0, -6, () => k.eyes(0, 0, 8, 2.6, p));
        k.mouth(0, 12, 6, p);
      }, rot: p.act ? 0 : p.wave(.4) * .05);
    }, shadowW: 44);
  },
  'submarine': (k, p) => k.alive(p, () {
    final bob = p.wave(.6) * 2;
    k.at(0, bob, () {
      k.at(12, 60, () {
        k.rect(-6, -2, 6, 4, 1, const Color(0xFF9E9E9E));
        k.at(-8, 0, () => k.oval(0, 0, 3, 10, const Color(0xFF9E9E9E)), sy: math.cos(p.t * (p.act ? 18 : 3)).abs() * .9 + .1);
      });
      k.rect(52, 22, 6, 18, 2, const Color(0xFF9E9E9E));
      k.rect(52, 22, 14, 5, 2, const Color(0xFF9E9E9E));
      k.oval(54, 60, 38, 22, const Color(0xFFFFCA28));
      k.rect(40, 34, 26, 14, 6, const Color(0xFFFFB300));
      for (final x in <double>[44, 64, 82]) {
        k.circle(x, 60, 6, const Color(0xFF4FC3F7));
        k.shine(x - 2, 58, 2, 1.2);
      }
      k.at(82, 60, () => k.eyes(0, 0, 0, 4.4, p));
      k.mouth(80, 72, 6, p);
    });
    for (var i = 0; i < 3; i++) {
      final d = p.cycle(.8, i / 3);
      k.c.drawCircle(
        Offset(60 + i * 6.0, 34 - d * 26),
        1.6 + d * 2,
        Paint()
          ..color = const Color(0x8890CAF9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }, shadowW: 70),
  'bicycle': (k, p) {
    final turn = p.act ? p.t * 8 : 0.0;
    k.alive(p, () {
      for (final x in <double>[26, 74]) {
        k.c.drawCircle(
          Offset(x, 72),
          17,
          Paint()
            ..color = const Color(0xFF37474F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        k.at(x, 72, () {
          for (var i = 0; i < 6; i++) {
            final a = turn + i * math.pi / 3;
            k.stroke([Offset.zero, Offset(math.cos(a) * 15, math.sin(a) * 15)], const Color(0xFFB0BEC5), 1);
          }
        });
      }
      k.stroke(
        [const Offset(26, 72), const Offset(44, 48), const Offset(66, 48), const Offset(74, 72)],
        const Color(0xFFE53935),
        4,
        smooth: false,
      );
      k.stroke([const Offset(44, 48), const Offset(50, 72), const Offset(66, 48)], const Color(0xFFE53935), 4, smooth: false);
      k.stroke([const Offset(66, 48), const Offset(70, 34), const Offset(78, 32)], const Color(0xFF424242), 3, smooth: false);
      k.rect(36, 40, 14, 5, 2, const Color(0xFF424242));
      k.at(
        50,
        72,
        () => k.stroke(
          [Offset(math.cos(turn) * 6, math.sin(turn) * 6), Offset(-math.cos(turn) * 6, -math.sin(turn) * 6)],
          const Color(0xFF616161),
          2.4,
        ),
      );
      // زنگ
      if (p.happy) k.circle(76, 30, 3, const Color(0xFFFFEB3B));
    }, squash: .01);
  },
};

void _toyCar(Pen k, ToonPose p, {required bool wheels}) => _vehicle(
  k,
  p,
  wheels: wheels ? [(28, 80), (72, 80)] : const [],
  wheelR: 11,
  exhaustX: 8,
  body: (b) {
    const red = Color(0xFFE53935);
    // کابین با دو شیشه
    final roof = Path()
      ..moveTo(26, 52)
      ..quadraticBezierTo(30, 28, 50, 27)
      ..quadraticBezierTo(70, 27, 76, 52)
      ..close();
    k.blob(roof, red);
    k.poly([const Offset(33, 50), const Offset(37, 34), const Offset(49, 32), const Offset(49, 50)], const Color(0xFFB3E5FC), line: false);
    k.poly([const Offset(53, 50), const Offset(53, 32), const Offset(64, 34), const Offset(70, 50)], const Color(0xFFB3E5FC), line: false);
    k.shine(40, 38, 2, 5, rot: .3);
    // چشم‌ها پشت شیشه‌ی جلو
    k.at(61, 42, () => k.eyes(0, 0, 8, 3, p));
    // بدنه با گلگیرها
    final body = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 48, 88, 26), const Radius.circular(13)));
    k.blob(body, red);
    for (final x in <double>[28, 72]) {
      k.c.drawCircle(Offset(x, 80), 14, Paint()..color = shade(red, .5));
    }
    k.stroke([const Offset(50, 52), const Offset(50, 70)], shade(red, .3), 1.2);
    k.rect(53, 58, 6, 2, 1, Colors.white, line: false);
    k.rect(90, 64, 7, 6, 2, const Color(0xFFB0BEC5));
    k.rect(3, 64, 7, 6, 2, const Color(0xFFB0BEC5));
    k.mouth(84, 60, 6, p);
    _headlight(k, p, 88, 55);
    k.rect(6, 53, 4, 6, 2, const Color(0xFFFF8A80), line: false);
    // کلید کوکی پشت ماشین می‌چرخد
    k.at(4, 50, () {
      k.rect(-6, -2, 6, 4, 1, const Color(0xFFFFC107));
      k.oval(-8, 0, 3, 8, const Color(0xFFFFD54F));
    }, sy: wheels ? math.cos(p.t * (p.act ? 10 : 1.5)).abs() * .7 + .3 : 1);
    if (!wheels) {
      for (final x in <double>[28, 72]) {
        k.c.drawCircle(
          Offset(x, 78),
          10,
          Paint()
            ..color = Colors.white.withValues(alpha: .6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  },
);
