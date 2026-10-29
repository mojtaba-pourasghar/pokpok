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
  bool lashes = false,
  bool tuft = false,
  Color? pads,
}) {
  final paw = pads ?? tint(fur, .45);
  k.alive(
    p,
    () {
      back?.call();
      // پاها با کف پنجه‌ی صورتی
      final step = p.act ? p.wave(2) * 3 : 0.0;
      for (final (x, lift) in [(40.0, math.max(0.0, step)), (60.0, math.max(0.0, -step))]) {
        k.oval(x, 88 - lift, 8.5, 5.5, shade(fur, .06));
        k.oval(x, 89.5 - lift, 4.2, 2.4, paw, line: false);
      }
      // دست‌ها: کشیده و گرد، نوک روشن‌تر
      double arm(double side) {
        if (p.happy) return side * (2.2 + p.wave(3, side) * .3);
        if (p.act) return side > 0 ? 2.4 + p.wave(2.5) * .5 : .5;
        if (p.sad) return side * .15;
        return side * (.45 + p.wave(.4, side) * .08);
      }

      for (final side in <double>[-1, 1]) {
        k.at(50 + side * 18, 63, () {
          k.rect(-5.5, -2, 11, 22, 5.5, fur);
          k.oval(0, 17, 4, 3, paw, line: false);
        }, rot: arm(side));
      }
      k.oval(50, 73, 21, 18, fur);
      if (belly != null) k.oval(50, 76, 12.5, 11, belly, line: false);
      outfit?.call();
      // سر کمی تاب می‌خورد
      k.at(50, 38, () {
        k.c.translate(-50, -38);
        ears?.call();
        k.oval(50, 38, headR + 1.5, headR, fur);
        // دسته‌ی موی بالای سر
        if (tuft) {
          k.poly(
            [const Offset(45, 17), const Offset(49, 10), const Offset(51, 16), const Offset(55, 11), const Offset(55, 18)],
            fur,
            line: false,
          );
        }
        if (muzzle != null) k.oval(50, 47, 11.5, 8.5, muzzle, line: false);
        snout?.call();
        if (muzzle != null) {
          // بینی قلبی براق
          k.c.drawPath(
            Path()
              ..moveTo(50, 46)
              ..cubicTo(45, 43.5, 45.5, 40, 50, 41)
              ..cubicTo(54.5, 40, 55, 43.5, 50, 46)
              ..close(),
            Paint()..color = nose,
          );
          k.c.drawCircle(const Offset(48.6, 42), .9, Paint()..color = Colors.white.withValues(alpha: .8));
        }
        k.eyes(50, 33, 18, 6.2, p);
        if (lashes && !p.happy) {
          for (final s in <double>[-1, 1]) {
            final x = 50 + s * 9;
            for (var i = 0; i < 3; i++) {
              k.stroke(
                [Offset(x + s * (3 + i * 1.6), 28.2 - i * .3), Offset(x + s * (5 + i * 2.2), 26 - i * .8)],
                const Color(0xFF2A2250),
                1,
              );
            }
          }
        }
        // ابروها
        for (final s in <double>[-1, 1]) {
          final up = p.happy ? -1.5 : (p.sad ? 1 : 0);
          k.stroke([Offset(50 + s * 6, 25 + up + (p.sad ? -s * 1.2 : 0)), Offset(50 + s * 12, 24.5 + up)], shade(fur, .5), 1.4);
        }
        k.cheeks(50, 44.5, 30, 3.6);
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
    tuft: true,
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
    lashes: true,
    pads: const Color(0xFFF8BBD0),
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
    tuft: true,
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
    final flap = p.act || p.happy ? p.wave(4) * .7 : p.wave(.5) * .08;
    k.alive(p, () {
      // دم بلند رنگی
      for (final (i, c) in [(0, const Color(0xFF1E88E5)), (1, const Color(0xFFFFB300)), (2, const Color(0xFF43A047))].indexed) {
        k.at(50, 80, () => k.rect(-3.5, 0, 7, 20, 3.5, c.$2), rot: (i - 1) * .22 + p.wave(.8) * .05);
      }
      // پاهای روی میله
      k.rect(26, 88, 48, 5, 2.5, const Color(0xFF8D6E63));
      for (final x in <double>[44, 56]) {
        k.oval(x, 87, 4, 3, const Color(0xFF9E9E9E));
      }
      // بال‌ها
      for (final side in <double>[-1, 1]) {
        k.at(50 + side * 15, 58, () {
          final wing = Path()
            ..moveTo(0, -4)
            ..quadraticBezierTo(side * 14, 4, side * 8, 26)
            ..quadraticBezierTo(side * 2, 22, 0, 12)
            ..close();
          k.blob(wing, const Color(0xFF43A047));
          k.stroke([Offset(side * 3, 14), Offset(side * 8, 22)], const Color(0xFF1E88E5), 3);
        }, rot: side * (.15 + flap));
      }
      k.oval(50, 66, 17, 21, const Color(0xFFE53935));
      k.oval(50, 72, 10, 12, const Color(0xFFFFCDD2), line: false);
      // سر با تاج پر
      for (final (i, r) in [-.4, 0.0, .4].indexed) {
        k.at(
          50,
          22,
          () => k.oval(0, -6, 3.5, 8, i == 1 ? const Color(0xFFFFB300) : const Color(0xFFE53935)),
          rot: r + p.wave(1, i / 3) * .08,
        );
      }
      k.circle(50, 38, 18, const Color(0xFFE53935));
      k.oval(50, 40, 12, 10, const Color(0xFFFFF3E0), line: false);
      k.eyes(50, 35, 15, 5.2, p);
      final open = p.act || p.happy ? (p.wave(3) + 1) * 1.4 : 0.0;
      final beak = Path()
        ..moveTo(44, 42)
        ..quadraticBezierTo(50, 38, 56, 42)
        ..quadraticBezierTo(56, 50, 50, 53)
        ..quadraticBezierTo(49, 47, 44, 42)
        ..close();
      k.blob(beak, const Color(0xFFFFB300));
      k.at(50, 47 + open, () => k.oval(0, 0, 4, 2.4, const Color(0xFFF57F17)));
      k.cheeks(50, 42, 26, 3);
      // کلاه بره
      k.at(42, 22, () {
        k.oval(0, 0, 14, 5, const Color(0xFFC62828));
        k.circle(-11, -3, 2.4, const Color(0xFFC62828));
      }, rot: -.25);
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
    lashes: true,
    pads: const Color(0xFFF8BBD0),
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
    final flap = p.happy ? p.wave(4) * .5 : p.wave(.5) * .05;
    k.alive(p, () {
      // پاها با سه انگشت
      for (final x in <double>[44, 58]) {
        k.stroke([Offset(x, 78), Offset(x, 90)], const Color(0xFFFFA000), 2.6);
        for (final d in <double>[-4, 0, 4]) {
          k.stroke([Offset(x, 90), Offset(x + d, 92.5)], const Color(0xFFFFA000), 2);
        }
      }
      k.at(50, 72, () {
        k.c.translate(-50, -72);
        // دم: سه پر گرد رو به بالا
        for (final (i, r) in [(0, -.5), (1, -.15), (2, .2)].indexed) {
          k.at(76, 58, () => k.oval(0, -10, 6, 13, i == 1 ? const Color(0xFFFFF8E1) : Colors.white), rot: r.$2 + p.wave(.8, i / 3) * .05);
        }
        // بدن چاق
        final body = Path()
          ..moveTo(30, 50)
          ..cubicTo(26, 70, 36, 84, 54, 84)
          ..cubicTo(74, 84, 84, 72, 80, 56)
          ..cubicTo(76, 46, 60, 46, 48, 52)
          ..cubicTo(42, 44, 34, 42, 30, 50)
          ..close();
        k.blob(body, Colors.white);
        // بال با لبه‌ی پرپر
        k.at(58, 64, () {
          final wing = Path()
            ..moveTo(-12, -6)
            ..quadraticBezierTo(4, -12, 14, -2)
            ..quadraticBezierTo(14, 6, 8, 8)
            ..quadraticBezierTo(5, 12, 0, 9)
            ..quadraticBezierTo(-4, 13, -8, 8)
            ..quadraticBezierTo(-14, 6, -12, -6)
            ..close();
          k.blob(wing, const Color(0xFFF3EEE6));
        }, rot: -flap);
        // سر
        k.circle(34, 42, 13, Colors.white);
        for (final (x, y, r) in [(27.0, 29.0, 4.0), (32.5, 26.5, 4.6), (38.0, 29.0, 4.0)]) {
          k.circle(x, y, r, const Color(0xFFE53935));
        }
        k.poly([const Offset(21, 41), const Offset(14, 44), const Offset(21, 46)], const Color(0xFFFFB300));
        k.poly([const Offset(21, 45), const Offset(16, 45), const Offset(21, 48)], const Color(0xFFF57F17));
        k.oval(23, 52, 3, 4.6, const Color(0xFFE53935));
        k.eyes(33, 40, 9, 3.8, p);
        k.cheeks(33, 46, 13, 2.2);
      }, rot: -peck * .45);
      if (peck > .8) k.c.drawCircle(const Offset(20, 92), 1.6, Paint()..color = const Color(0xFF8D6E63));
    }, shadowW: 56);
  },
  'cow': (k, p) => k.alive(p, () {
    const white = Color(0xFFFAFAFA);
    // پاها با سم
    for (final x in <double>[30, 42, 60, 72]) {
      k.rect(x - 4.5, 70, 9, 20, 4, white);
      k.rect(x - 4.5, 86, 9, 6, 2.5, const Color(0xFF5D4037));
    }
    k.at(86, 56, () {
      k.stroke([Offset.zero, const Offset(5, 10), const Offset(4, 22)], const Color(0xFFBDBDBD), 2.4);
      k.oval(4, 24, 3, 4, const Color(0xFF424242));
    }, rot: p.wave(1) * .3);
    final body = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 44, 66, 34), const Radius.circular(17)));
    k.blob(body, white);
    for (final (x, y, rx, ry) in [(44.0, 54.0, 8.0, 6.0), (66.0, 64.0, 7.0, 5.0), (74.0, 50.0, 5.0, 4.0), (32.0, 68.0, 4.0, 3.0)]) {
      k.oval(x, y, rx, ry, const Color(0xFF3E3E3E), line: false);
    }
    k.oval(56, 78, 7, 4, const Color(0xFFF8BBD0));
    for (final x in <double>[53, 59]) {
      k.c.drawCircle(Offset(x, 81), 1.2, Paint()..color = const Color(0xFFF48FB1));
    }
    final chew = p.wave(1.5) * 1.2;
    k.at(22, 44, () {
      for (final s in <double>[-1, 1]) {
        k.at(s * 13, -10, () => k.oval(s * 4, 0, 7, 3.6, white), rot: s * (.3 + p.wave(.7, s) * .1));
        k.poly([Offset(s * 5, -13), Offset(s * 9, -22), Offset(s * 9.5, -12)], const Color(0xFFFFE082));
      }
      k.oval(0, 0, 15, 16, white);
      k.oval(3, -6, 5, 4, const Color(0xFF3E3E3E), line: false);
      k.oval(0, 10 + chew * .3, 12, 8, const Color(0xFFF8BBD0));
      for (final x in <double>[-4.0, 4.0]) {
        k.oval(x, 10, 1.6, 2.2, const Color(0xFFAD5A6F), line: false);
      }
      k.eyes(0, -3, 13, 4.4, p);
      k.cheeks(0, 3, 22, 2.4);
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
    k.at(50 + p.wave(.4) * 6, 50 + p.wave(.7) * 4, () {
      k.glow(0, 14, 40, const Color(0xFFEEFF41), glow);
      final flap = p.wave(14).abs();
      for (final s in <double>[-1, 1]) {
        k.oval(s * 13, -14, 11, 14 * flap + 3, Colors.white.withValues(alpha: .7));
      }
      k.oval(0, 16, 14, 17, Color.lerp(const Color(0xFFC6FF00), const Color(0xFFFFFF8D), glow)!);
      k.oval(0, -4, 16, 14, const Color(0xFF6D4C41));
      k.eyes(0, -5, 13, 4.6, p);
      k.mouth(0, 3, 5, p);
      for (final s in <double>[-1, 1]) {
        k.stroke([Offset(s * 5, -16), Offset(s * 10, -28)], const Color(0xFF3E2723), 1.8);
        k.c.drawCircle(Offset(s * 10, -28), 2, Paint()..color = const Color(0xFF3E2723));
      }
    });
  }, shadowW: 30),
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
    k.at(50, 62, () {
      final seed = Path()
        ..moveTo(0, -28)
        ..cubicTo(20, -18, 20, 18, 0, 26)
        ..cubicTo(-20, 18, -20, -18, 0, -28)
        ..close();
      k.blob(seed, const Color(0xFFA1704A));
      k.stroke([const Offset(0, -24), const Offset(-2, 0), const Offset(0, 22)], const Color(0xFF8D5524), 1.6);
    }, rot: .25 + p.wave(.5) * .08);
    if (p.act) k.at(52, 34, () => k.oval(6, -4, 7, 4, const Color(0xFF66BB6A)), rot: -.5);
    k.face(50, 62, 14, p);
  }, shadowW: 36),
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
    final bale = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16, 46, 68, 44), const Radius.circular(10)));
    k.blob(bale, const Color(0xFFFFCA28));
    k.c.save();
    k.c.clipPath(bale);
    for (var i = 0; i < 18; i++) {
      final y = 50 + (i * 7) % 38.0;
      final x = 18 + (i * 13) % 60.0;
      k.stroke([Offset(x, y), Offset(x + 12, y + 2)], const Color(0xFFE0A100), 1.4);
    }
    k.c.restore();
    for (final x in <double>[32, 68]) {
      k.rect(x - 2, 46, 4, 44, 1, const Color(0xFFB71C1C));
    }
    // ساقه‌های بیرون‌زده که در باد تکان می‌خورند
    for (var i = 0; i < 6; i++) {
      final x = 24 + i * 10.0;
      k.stroke([Offset(x, 48), Offset(x - 2 + p.wave(.7, i / 6) * 2, 38 - (i % 2) * 4.0)], const Color(0xFFFFB300), 2);
    }
    k.face(50, 66, 14, p);
  }),
  'nest': (k, p) => k.alive(p, () {
    final bowl = Path()
      ..moveTo(12, 62)
      ..quadraticBezierTo(16, 92, 50, 92)
      ..quadraticBezierTo(84, 92, 88, 62)
      ..close();
    k.oval(50, 62, 38, 11, const Color(0xFF6D4C41));
    k.blob(bowl, const Color(0xFFC9A44C));
    for (var i = 0; i < 16; i++) {
      final x = 14 + i * 4.6;
      k.stroke([Offset(x, 62 + (i % 3) * 6.0), Offset(x + 10, 70 + (i % 4) * 5.0)], const Color(0xFF9E7A2E), 1.6);
    }
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * math.pi;
      k.stroke(
        [Offset(50 + math.cos(a) * 38, 62 - math.sin(a) * 3), Offset(50 + math.cos(a + .3) * 34, 58 - math.sin(a) * 5)],
        const Color(0xFFD7B66A),
        1.6,
      );
    }
    k.face(50, 78, 13, p);
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
