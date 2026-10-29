import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'toon.dart';

/// شخصیت‌های داستان، حیوان‌ها و چیزهای باغ.

/// بدن یک حیوانک ایستاده: پاها، بدن، دست‌ها (که در خوشحالی بالا می‌روند و در کار تکان می‌خورند)،
/// سر با چشم و پوزه. [back] پشت بدن (دم)، [ears] پشت سر، [hat] روی سر، [outfit] روی بدن.
void critter(
  Pen k,
  ToonPose p, {
  required Color fur,
  Color? belly,
  Color? muzzle,
  Color nose = const Color(0xFF3E2723),
  void Function()? back,
  void Function()? ears,
  void Function()? hat,
  void Function()? outfit,
  void Function()? snout,
  double headR = 23,
}) {
  k.alive(
    p,
    () {
      back?.call();
      // پاها
      final step = p.act ? p.wave(2) * 3 : 0.0;
      k.oval(40, 89 - math.max(0.0, step), 8, 5, shade(fur, .1));
      k.oval(60, 89 - math.max(0.0, -step), 8, 5, shade(fur, .1));
      // دست‌ها
      double arm(double side) {
        if (p.happy) return side * (2.2 + p.wave(3, side) * .3);
        if (p.act) return side > 0 ? 2.4 + p.wave(2.5) * .5 : .5;
        if (p.sad) return side * .15;
        return side * (.45 + p.wave(.4, side) * .08);
      }

      for (final side in <double>[-1, 1]) {
        k.at(50 + side * 19, 64, () => k.oval(0, 10, 6, 11, fur), rot: arm(side));
      }
      k.oval(50, 72, 22, 19, fur);
      if (belly != null) k.oval(50, 75, 13, 12, belly, line: false);
      outfit?.call();
      // سر کمی تاب می‌خورد
      k.at(50, 38, () {
        k.c.translate(-50, -38);
        ears?.call();
        k.circle(50, 38, headR, fur);
        if (muzzle != null) k.oval(50, 47, 11, 8, muzzle, line: false);
        snout?.call();
        if (muzzle != null) k.oval(50, 43, 3.6, 2.6, nose, line: false);
        k.eyes(50, 34, 17, 5.4, p);
        k.cheeks(50, 45, 28, 3.2);
        k.mouth(50, 50, 8, p);
        hat?.call();
      }, rot: p.sad ? -.08 : p.wave(.35) * .05);
    },
    shadowW: 56,
    squash: .025,
  );
}

final Map<String, ToonPainter> creatureToons = {
  // ── دوستان ──
  'bear': (k, p) => critter(
    k,
    p,
    fur: const Color(0xFFA1704A),
    muzzle: const Color(0xFFE6C29A),
    ears: () {
      for (final x in <double>[30, 70]) {
        k.circle(x, 20, 8, const Color(0xFFA1704A));
        k.circle(x, 20, 4, const Color(0xFFE6C29A), line: false);
      }
    },
    outfit: () {
      k.poly([const Offset(36, 60), const Offset(64, 60), const Offset(68, 88), const Offset(32, 88)], Colors.white);
      k.rect(44, 70, 12, 8, 3, const Color(0xFFFFCDD2));
    },
    hat: () {
      k.rect(37, 14, 26, 8, 3, Colors.white);
      for (final x in <double>[40, 50, 60]) {
        k.circle(x, 10 + (x == 50 ? -2 : 0), 7, Colors.white);
      }
    },
  ),
  'bunny': (k, p) => critter(
    k,
    p,
    fur: const Color(0xFFF7F3F0),
    muzzle: Colors.white,
    nose: const Color(0xFFF48FB1),
    ears: () {
      for (final (x, r) in [(40.0, -.15), (60.0, .15)]) {
        k.at(x, 22, () {
          k.oval(0, -14, 6.5, 17, const Color(0xFFF7F3F0));
          k.oval(0, -13, 3.5, 13, const Color(0xFFF8BBD0), line: false);
        }, rot: r + p.wave(.6, x) * .1 + (p.happy ? p.wave(3) * .2 : 0));
      }
    },
    outfit: () {
      k.rect(36, 66, 28, 22, 6, const Color(0xFF66BB6A));
      for (final x in <double>[40, 60]) {
        k.stroke([Offset(x, 66), Offset(x, 56)], const Color(0xFF43A047), 3);
        k.circle(x, 66, 1.8, const Color(0xFFFFEB3B), line: false);
      }
    },
  ),
  'squirrel': (k, p) => critter(
    k,
    p,
    fur: const Color(0xFFB0703C),
    muzzle: const Color(0xFFF1D3B3),
    back: () => k.at(72, 80, () {
      k.poly(
        [
          const Offset(0, 0),
          const Offset(14, -10),
          const Offset(22, -34),
          const Offset(16, -58),
          const Offset(2, -62),
          const Offset(8, -44),
          const Offset(4, -22),
        ],
        const Color(0xFFC07A40),
        smooth: true,
      );
    }, rot: p.wave(.7) * .12),
    ears: () {
      for (final x in <double>[33, 67]) {
        k.poly([Offset(x - 6, 24), Offset(x, 8), Offset(x + 6, 24)], const Color(0xFFB0703C));
      }
    },
    outfit: () => k.rect(37, 62, 26, 26, 6, const Color(0xFF42A5F5)),
    hat: () {
      k.rect(30, 18, 40, 6, 3, const Color(0xFF6D4C41));
      for (final x in <double>[40, 60]) {
        k.circle(x, 20, 6, const Color(0xFF90CAF9));
        k.shine(x - 2, 18, 2, 1.2);
      }
    },
  ),
  'parrot': (k, p) {
    final flap = p.act || p.happy ? p.wave(4) * .6 : p.wave(.5) * .08;
    k.alive(p, () {
      k.poly([const Offset(44, 82), const Offset(50, 98), const Offset(56, 82)], const Color(0xFF1E88E5));
      for (final side in <double>[-1, 1]) {
        k.at(
          50 + side * 18,
          62,
          () => k.oval(0, 10, 7, 16, side < 0 ? const Color(0xFF43A047) : const Color(0xFFFFB300)),
          rot: side * (.3 + flap),
        );
      }
      k.oval(50, 68, 18, 20, const Color(0xFFE53935));
      k.oval(50, 74, 10, 11, const Color(0xFFFFCDD2), line: false);
      k.oval(42, 90, 4, 3, const Color(0xFFFFB300));
      k.oval(58, 90, 4, 3, const Color(0xFFFFB300));
      k.circle(50, 38, 20, const Color(0xFFE53935));
      k.eyes(50, 34, 16, 5.4, p);
      // منقار که با حرف زدن باز و بسته می‌شود
      final open = p.act || p.happy ? (p.wave(3) + 1) * 1.6 : 0.0;
      k.poly([const Offset(44, 42), const Offset(56, 42), const Offset(50, 50)], const Color(0xFFFFB300));
      k.poly([Offset(46, 44 + open), Offset(54, 44 + open), Offset(50, 48 + open)], const Color(0xFFF57F17));
      k.at(44, 20, () => k.oval(0, 0, 14, 5, const Color(0xFFC62828)), rot: -.25);
      k.circle(36, 18, 2.5, const Color(0xFFC62828));
    }, shadowW: 46);
  },
  'owl': (k, p) => k.alive(p, () {
    final flap = p.happy ? p.wave(3) * .5 : p.wave(.4) * .05;
    for (final side in <double>[-1, 1]) {
      k.at(50 + side * 22, 58, () => k.oval(0, 12, 7, 18, const Color(0xFF8D6E63)), rot: side * (.25 + flap));
    }
    k.oval(50, 62, 26, 30, const Color(0xFFA1887F));
    k.oval(50, 70, 16, 18, const Color(0xFFD7CCC8), line: false);
    for (var i = 0; i < 6; i++) {
      k.stroke(
        [Offset(42 + (i % 3) * 8.0, 64 + (i ~/ 3) * 8.0), Offset(45 + (i % 3) * 8.0, 67 + (i ~/ 3) * 8.0)],
        const Color(0xFFA1887F),
        1.6,
      );
    }
    // شال بنفش
    k.poly(
      [const Offset(26, 52), const Offset(74, 52), const Offset(70, 62), const Offset(50, 72), const Offset(30, 62)],
      const Color(0xFF7E57C2),
      smooth: true,
    );
    for (final x in <double>[30, 70]) {
      k.poly([Offset(x - 6, 24), Offset(x + (x < 50 ? -4 : 4), 10), Offset(x + 6, 24)], const Color(0xFF8D6E63));
    }
    k.oval(50, 36, 26, 18, const Color(0xFF8D6E63));
    k.eyes(50, 36, 22, 7.5, p);
    for (final x in <double>[39, 61]) {
      k.c.drawCircle(
        Offset(x, 36),
        9.5,
        Paint()
          ..color = const Color(0xFF5D4037)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    k.stroke([const Offset(48.5, 36), const Offset(51.5, 36)], const Color(0xFF5D4037), 2);
    k.poly([const Offset(46, 44), const Offset(54, 44), const Offset(50, 50)], const Color(0xFFFFB300));
    k.oval(42, 92, 5, 3, const Color(0xFFFFB300));
    k.oval(58, 92, 5, 3, const Color(0xFFFFB300));
  }, shadowW: 56),
  'cat': (k, p) => critter(
    k,
    p,
    fur: const Color(0xFFB0BEC5),
    muzzle: const Color(0xFFECEFF1),
    nose: const Color(0xFFF48FB1),
    back: () => k.at(70, 84, () {
      k.stroke([Offset.zero, const Offset(12, -6), const Offset(16, -22), const Offset(10, -32)], const Color(0xFF90A4AE), 7);
    }, rot: p.wave(.8) * .25),
    ears: () {
      for (final (x, s) in [(32.0, -1.0), (68.0, 1.0)]) {
        k.poly([Offset(x - 8, 28), Offset(x + s * 2, 10), Offset(x + 8, 26)], const Color(0xFFB0BEC5));
        k.poly([Offset(x - 4, 25), Offset(x + s * 1.5, 15), Offset(x + 4, 24)], const Color(0xFFF8BBD0), line: false);
      }
    },
    snout: () {
      for (final s in <double>[-1, 1]) {
        k.stroke([Offset(50 + s * 8, 46), Offset(50 + s * 20, 44)], const Color(0xFF78909C), 1.2);
        k.stroke([Offset(50 + s * 8, 48), Offset(50 + s * 20, 50)], const Color(0xFF78909C), 1.2);
      }
    },
    outfit: () {
      k.poly([const Offset(40, 56), const Offset(50, 61), const Offset(40, 66)], const Color(0xFFFFD54F));
      k.poly([const Offset(60, 56), const Offset(50, 61), const Offset(60, 66)], const Color(0xFFFFD54F));
      k.circle(50, 61, 3, const Color(0xFFFFB300));
    },
  ),
  'turtle': (k, p) {
    final peek = p.sad ? -4.0 : (p.act ? p.wave(1) * 2 : 0.0);
    k.alive(p, () {
      for (final x in <double>[30, 70]) {
        k.oval(x, 88, 8, 5, const Color(0xFF7CB342));
      }
      // سر از لاک بیرون می‌آید
      k.at(78 + peek, 56, () {
        k.oval(0, 0, 16, 14, const Color(0xFF8BC34A));
        k.eyes(2, -3, 12, 4, p);
        k.mouth(4, 5, 6, p);
        k.rect(-12, -16, 24, 6, 3, const Color(0xFF1E88E5));
        k.oval(0, -15, 12, 5, const Color(0xFF42A5F5));
        k.rect(8, -12, 10, 3, 1.5, const Color(0xFF1565C0));
      });
      final shell = Path()
        ..moveTo(16, 82)
        ..quadraticBezierTo(18, 40, 50, 38)
        ..quadraticBezierTo(80, 40, 82, 82)
        ..close();
      k.blob(shell, const Color(0xFF558B2F));
      for (final o in const [Offset(36, 64), Offset(50, 52), Offset(64, 64), Offset(50, 72)]) {
        k.poly(
          [for (var i = 0; i < 6; i++) o + Offset(math.cos(i * math.pi / 3), math.sin(i * math.pi / 3)) * 7],
          const Color(0xFF7CB342),
          line: false,
        );
      }
      k.rect(14, 80, 70, 6, 3, const Color(0xFFC5E1A5));
    }, shadowW: 76);
  },

  // ── حیوان‌های مزرعه و جنگل ──
  'hen': (k, p) {
    final peck = p.act ? math.max(0.0, p.wave(1.6)) : 0.0;
    k.alive(p, () {
      k.stroke([const Offset(44, 80), const Offset(44, 92)], const Color(0xFFFFB300), 2.4);
      k.stroke([const Offset(56, 80), const Offset(56, 92)], const Color(0xFFFFB300), 2.4);
      k.at(50, 70, () {
        k.c.translate(-50, -70);
        k.poly([
          const Offset(78, 52),
          const Offset(90, 44),
          const Offset(86, 62),
          const Offset(92, 66),
          const Offset(80, 74),
        ], Colors.white);
        k.oval(54, 66, 26, 18, Colors.white);
        k.at(56, 66, () => k.oval(0, 0, 12, 8, const Color(0xFFEEEEEE)), rot: p.happy ? p.wave(4) * .5 : 0);
        k.circle(34, 46, 13, Colors.white);
        for (final (x, y) in [(28.0, 33.0), (33.0, 30.0), (38.0, 33.0)]) {
          k.circle(x, y, 3.6, const Color(0xFFE53935));
        }
        k.poly([const Offset(20, 46), const Offset(24, 42), const Offset(24, 50)], const Color(0xFFFFB300));
        k.oval(25, 54, 2.6, 4, const Color(0xFFE53935));
        k.eyes(34, 43, 10, 3.4, p);
      }, rot: -peck * .5);
      if (peck > .8) k.c.drawCircle(const Offset(22, 92), 1.6, Paint()..color = const Color(0xFF8D6E63));
    }, shadowW: 56);
  },
  'cow': (k, p) => k.alive(p, () {
    for (final x in <double>[28, 40, 62, 74]) {
      k.rect(x - 4, 70, 8, 22, 3, Colors.white);
      k.rect(x - 4, 88, 8, 5, 2, const Color(0xFF5D4037));
    }
    k.at(
      84,
      56,
      () => k.stroke([Offset.zero, const Offset(6, 10), const Offset(4, 22)], const Color(0xFF9E9E9E), 2.4),
      rot: p.wave(1) * .3,
    );
    k.oval(52, 62, 34, 18, Colors.white);
    for (final (x, y, r) in [(40.0, 56.0, 7.0), (62.0, 64.0, 6.0), (70.0, 54.0, 4.0)]) {
      k.oval(x, y, r * 1.3, r, const Color(0xFF3E3E3E), line: false);
    }
    k.oval(48, 78, 7, 4, const Color(0xFFF8BBD0));
    final chew = p.wave(1.5) * 1.2;
    k.at(22, 42, () {
      for (final s in <double>[-1, 1]) {
        k.oval(s * 13, -9, 6, 3, Colors.white);
        k.poly([Offset(s * 6, -12), Offset(s * 10, -20), Offset(s * 8, -11)], const Color(0xFFFFE082));
      }
      k.oval(0, 0, 14, 15, Colors.white);
      k.oval(0, 9 + chew * .3, 11, 7, const Color(0xFFF8BBD0));
      k.c.drawCircle(const Offset(-4, 9), 1.4, Paint()..color = const Color(0xFF8D6E63));
      k.c.drawCircle(const Offset(4, 9), 1.4, Paint()..color = const Color(0xFF8D6E63));
      k.eyes(0, -3, 12, 4, p);
    }, rot: p.wave(.4) * .06);
  }, shadowW: 80),
  'bee': (k, p) => k.alive(p, () {
    final flap = p.wave(16).abs();
    k.at(50 + p.wave(.5) * 6, 50 + p.wave(.9) * 6, () {
      for (final s in <double>[-1, 1]) {
        k.oval(s * 10, -16, 9, 12 * flap + 2, Colors.white.withValues(alpha: .75));
      }
      k.oval(0, 0, 24, 18, const Color(0xFFFFD54F));
      for (final x in <double>[-6, 6]) {
        k.stroke([Offset(x, -16), Offset(x, 16)], const Color(0xFF3E2723), 5);
      }
      k.poly([const Offset(22, -3), const Offset(30, 0), const Offset(22, 3)], const Color(0xFF3E2723));
      k.eyes(-12, -2, 10, 3.6, p);
      k.mouth(-12, 6, 5, p);
      for (final s in <double>[-1, 1]) {
        k.stroke([Offset(-14 + s * 3, -16), Offset(-16 + s * 5, -24)], const Color(0xFF3E2723), 1.4);
      }
    });
  }, shadowW: 30),
  'ladybug': (k, p) => k.alive(p, () {
    final open = p.act ? (p.wave(2) + 1) * .2 : 0.0;
    for (var i = 0; i < 3; i++) {
      for (final s in <double>[-1, 1]) {
        k.stroke([Offset(50 + s * 18, 66 + i * 8.0), Offset(50 + s * 28, 70 + i * 8.0 + p.wave(3, i / 3) * 2)], const Color(0xFF3E2723), 2);
      }
    }
    k.circle(50, 46, 12, const Color(0xFF3E2723));
    for (final s in <double>[-1, 1]) {
      k.at(50, 52, () {
        final w = Path()
          ..moveTo(0, 0)
          ..arcTo(Rect.fromCenter(center: const Offset(0, 18), width: 52, height: 44), -math.pi / 2, s * math.pi, false)
          ..close();
        k.blob(w, const Color(0xFFE53935));
        for (final o in [Offset(s * 10, 12), Offset(s * 16, 26), Offset(s * 7, 30)]) {
          k.c.drawCircle(o, 3.4, Paint()..color = const Color(0xFF3E2723));
        }
      }, rot: s * open);
    }
    k.eyes(50, 44, 9, 3, p);
  }, shadowW: 50),
  'fish': (k, p) => k.alive(p, () {
    final sw = p.wave(1.4);
    k.at(50 + sw * 3, 56, () {
      k.at(
        24,
        0,
        () => k.poly([Offset.zero, const Offset(16, -14), const Offset(12, 0), const Offset(16, 14)], const Color(0xFFFF7043)),
        rot: sw * .3,
      );
      k.poly([const Offset(-4, -16), const Offset(8, -26), const Offset(14, -14)], const Color(0xFFFF7043));
      k.oval(0, 0, 26, 18, const Color(0xFFFF9800));
      for (final x in <double>[-2, 8]) {
        k.stroke([Offset(x, -12), Offset(x + 4, 0), Offset(x, 12)], const Color(0xFFFFB74D), 1.6);
      }
      k.eyes(-12, -4, 4, 4.6, p);
      k.mouth(-20, 4, 5, p);
      k.shine(-6, -10, 6, 2.5, rot: 0);
    }, rot: sw * .05);
    for (var i = 0; i < 2; i++) {
      final b = p.cycle(.7, i / 2);
      k.c.drawCircle(
        Offset(24 - b * 6, 44 - b * 30),
        2 + b * 2,
        Paint()
          ..color = const Color(0x8890CAF9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }, shadowW: 40),
  'firefly': (k, p) => k.alive(p, () {
    final glow = .5 + (p.wave(1.2) + 1) * .25;
    k.at(50 + p.wave(.4) * 8, 50 + p.wave(.7) * 6, () {
      k.glow(0, 12, 26, const Color(0xFFEEFF41), glow);
      final flap = p.wave(14).abs();
      for (final s in <double>[-1, 1]) {
        k.oval(s * 8, -10, 7, 9 * flap + 2, Colors.white.withValues(alpha: .7));
      }
      k.oval(0, 10, 9, 11, Color.lerp(const Color(0xFFC6FF00), const Color(0xFFFFFF8D), glow)!);
      k.oval(0, -2, 10, 9, const Color(0xFF5D4037));
      k.eyes(0, -3, 8, 3, p);
      for (final s in <double>[-1, 1]) {
        k.stroke([Offset(s * 3, -10), Offset(s * 6, -18)], const Color(0xFF3E2723), 1.4);
      }
    });
  }, shadowW: 24),
  'baby_owl': (k, p) => k.alive(p, () {
    k.oval(50, 64, 26, 28, const Color(0xFFD7CCC8));
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2;
      k.c.drawCircle(Offset(50 + math.cos(a) * 24, 64 + math.sin(a) * 26), 4, Paint()..color = const Color(0xFFD7CCC8));
    }
    k.oval(50, 72, 14, 14, Colors.white, line: false);
    k.eyes(50, 52, 20, 7.6, p);
    k.poly([const Offset(47, 60), const Offset(53, 60), const Offset(50, 65)], const Color(0xFFFFB300));
    for (final s in <double>[-1, 1]) {
      k.at(50 + s * 24, 66, () => k.oval(0, 0, 5, 11, const Color(0xFFBCAAA4)), rot: s * (.3 + (p.happy ? p.wave(4) * .4 : 0)));
    }
  }, shadowW: 50),

  // ── باغ ──
  'watering_can': (k, p) {
    final tilt = p.act ? -.45 : p.wave(.4) * .04;
    k.alive(p, () {
      k.at(50, 90, () {
        k.c.translate(-50, -90);
        k.poly([const Offset(64, 64), const Offset(90, 36), const Offset(94, 40), const Offset(70, 74)], const Color(0xFF26C6DA));
        k.oval(92, 38, 5, 3, const Color(0xFF00ACC1));
        k.rect(24, 50, 44, 40, 12, const Color(0xFF26C6DA));
        k.stroke([const Offset(28, 52), const Offset(32, 30), const Offset(56, 28), const Offset(62, 50)], const Color(0xFF0097A7), 5);
        k.shine(32, 64, 3, 10, rot: 0);
        k.face(46, 70, 14, p);
      }, rot: tilt);
      if (p.act) {
        for (var i = 0; i < 8; i++) {
          final d = p.cycle(2.2, i / 8);
          k.c.drawCircle(Offset(88 + (i % 3) * 3 - d * 6, 24 + d * 64), 1.8, Paint()..color = const Color(0xCC4FC3F7));
        }
      }
    });
  },
  'can_body': (k, p) => k.alive(p, () {
    k.rect(26, 46, 48, 44, 12, const Color(0xFF26C6DA));
    k.shine(34, 60, 3, 10, rot: 0);
    k.face(50, 68, 15, p);
  }),
  'can_spout': (k, p) => k.alive(p, () {
    k.at(50, 60, () {
      k.rect(-34, -5, 64, 10, 5, const Color(0xFF26C6DA));
      k.oval(32, 0, 6, 9, const Color(0xFF00ACC1));
    }, rot: -.5 + p.wave(.4) * .05);
  }),
  'can_handle': (k, p) => k.alive(p, () {
    k.stroke([const Offset(24, 84), const Offset(30, 40), const Offset(70, 40), const Offset(76, 84)], const Color(0xFF0097A7), 9);
    k.stroke([const Offset(26, 82), const Offset(32, 44), const Offset(68, 44), const Offset(74, 82)], const Color(0xFF26C6DA), 5);
  }),
  'well': (k, p) => k.alive(p, () {
    final crank = p.act ? p.t * 4 : 0.0;
    k.rect(18, 22, 6, 50, 2, const Color(0xFF8D6E63));
    k.rect(76, 22, 6, 50, 2, const Color(0xFF8D6E63));
    k.poly([const Offset(10, 26), const Offset(50, 6), const Offset(90, 26)], const Color(0xFFD84315));
    k.rect(22, 34, 56, 5, 2, const Color(0xFF6D4C41));
    k.at(82, 36, () => k.stroke([Offset.zero, Offset(math.cos(crank) * 9, math.sin(crank) * 9)], const Color(0xFF5D4037), 3));
    final rope = p.act ? 6 + p.cycle(.4) * 18 : 12.0;
    k.stroke([const Offset(50, 38), Offset(50, 38 + rope)], const Color(0xFFBCAAA4), 1.6);
    k.rect(44, 38 + rope, 12, 9, 2, const Color(0xFF90A4AE));
    k.rect(14, 62, 72, 30, 6, const Color(0xFF9E9E9E));
    for (var r = 0; r < 2; r++) {
      for (var i = 0; i < 4; i++) {
        k.rect(16 + i * 17.0 + (r.isOdd ? 8 : 0), 64 + r * 13.0, 15, 11, 3, const Color(0xFFBDBDBD));
      }
    }
    k.face(50, 76, 14, p);
  }),
  'seed': (k, p) => k.alive(p, () {
    k.at(50, 66, () => k.oval(0, 0, 14, 20, const Color(0xFF8D6E63)), rot: .3 + p.wave(.5) * .08);
    k.shine(44, 58, 3, 6);
    k.face(50, 68, 11, p);
  }, shadowW: 30),
  'sprout': (k, p) => k.alive(p, () {
    k.oval(50, 88, 26, 6, const Color(0xFF6D4C41));
    final sway = p.wave(.6) * .1;
    k.at(
      50,
      88,
      () {
        k.stroke([Offset.zero, const Offset(0, -34)], const Color(0xFF43A047), 4);
        k.at(0, -32, () => k.oval(-10, 0, 11, 6, const Color(0xFF66BB6A)), rot: -.4);
        k.at(0, -34, () => k.oval(10, 0, 11, 6, const Color(0xFF66BB6A)), rot: .3);
      },
      rot: sway,
      sy: p.act ? 1 + p.cycle(.5) * .4 : 1,
    );
    k.face(50, 76, 10, p);
  }),
  'flower_pot': (k, p) => k.alive(p, () {
    final sway = p.wave(.5) * .08;
    k.at(50, 58, () {
      k.stroke([Offset.zero, const Offset(0, -26)], const Color(0xFF43A047), 3.4);
      k.at(0, -10, () => k.oval(-8, 0, 9, 4, const Color(0xFF66BB6A)), rot: -.3);
      final bloom = p.act ? .8 + p.cycle(.5) * .4 : 1.0;
      k.at(
        0,
        -32,
        () {
          for (final r in <double>[-.5, 0, .5]) {
            k.at(0, 0, () => k.oval(0, -8, 7, 12, const Color(0xFFF06292)), rot: r);
          }
          k.c.drawCircle(const Offset(0, -2), 3, Paint()..color = const Color(0xFFFFEB3B));
        },
        sx: bloom,
        sy: bloom,
      );
    }, rot: sway);
    k.poly([const Offset(28, 58), const Offset(72, 58), const Offset(66, 92), const Offset(34, 92)], const Color(0xFFD9774B));
    k.rect(24, 54, 52, 9, 3, const Color(0xFFE08A5C));
    k.face(50, 74, 14, p);
  }),
  'empty_pot': (k, p) => k.alive(p, () {
    k.poly([const Offset(26, 52), const Offset(74, 52), const Offset(68, 92), const Offset(32, 92)], const Color(0xFFD9774B));
    k.oval(50, 52, 26, 6, const Color(0xFF6D4C41));
    k.rect(22, 46, 56, 9, 3, const Color(0xFFE08A5C));
    if (p.act) {
      for (var i = 0; i < 4; i++) {
        final d = p.cycle(1.5, i / 4);
        k.c.drawCircle(Offset(40 + i * 7.0, 44 - math.sin(d * math.pi) * 14), 2, Paint()..color = const Color(0xFF6D4C41));
      }
    }
    k.face(50, 72, 15, p);
  }),
  'hay': (k, p) => k.alive(p, () {
    for (var i = 0; i < 14; i++) {
      final x = 24 + i * 4.0;
      k.stroke(
        [Offset(x, 90), Offset(x + (i - 7) * 1.5 + p.wave(.6, i / 14) * 2, 44 + (i % 3) * 4.0)],
        i.isEven ? const Color(0xFFFFD54F) : const Color(0xFFFFB300),
        3.4,
      );
    }
    k.rect(22, 64, 56, 7, 3, const Color(0xFFA1887F));
    k.face(50, 80, 12, p);
  }),
  'nest': (k, p) => k.alive(p, () {
    k.oval(50, 74, 38, 16, const Color(0xFFC9A44C));
    k.oval(50, 68, 28, 8, const Color(0xFF8D6E3C), line: false);
    for (var i = 0; i < 12; i++) {
      k.stroke([Offset(14 + i * 6.0, 68 + (i % 2) * 6), Offset(22 + i * 6.0, 84 - (i % 3) * 3)], const Color(0xFFB8860B), 1.6);
    }
    k.face(50, 78, 11, p);
  }),
  'bucket': (k, p) => k.alive(p, () {
    k.stroke([const Offset(26, 46), Offset(50, 16 + p.wave(.6) * 2), const Offset(74, 46)], const Color(0xFF78909C), 2.4);
    k.poly([const Offset(24, 44), const Offset(76, 44), const Offset(70, 92), const Offset(30, 92)], const Color(0xFFB0BEC5));
    k.oval(50, 44, 26, 6, p.act ? Colors.white : const Color(0xFF78909C));
    k.shine(32, 60, 3, 12, rot: .1);
    k.face(50, 68, 15, p);
  }),
  'bird_house': (k, p) => k.alive(p, () {
    k.rect(46, 70, 8, 22, 2, const Color(0xFF8D6E63));
    k.rect(26, 38, 48, 38, 6, const Color(0xFFBCAAA4));
    k.poly([const Offset(18, 42), const Offset(50, 16), const Offset(82, 42)], const Color(0xFFE57373));
    k.circle(50, 56, 9, const Color(0xFF4E342E));
    // پرنده‌ی کوچک که سرک می‌کشد
    final peek = math.max(0.0, p.wave(.4)) * 6;
    if (peek > 0) {
      k.circle(50, 58 - peek, 6, const Color(0xFF64B5F6));
      k.c.drawCircle(Offset(48, 56 - peek), 1.2, Paint()..color = Colors.black);
      k.c.drawCircle(Offset(52, 56 - peek), 1.2, Paint()..color = Colors.black);
      k.poly([Offset(48.5, 59 - peek), Offset(51.5, 59 - peek), Offset(50, 62 - peek)], const Color(0xFFFFB300));
    }
  }),
};
