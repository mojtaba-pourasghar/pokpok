import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'toon.dart';

/// پس‌زمینه‌های زنده‌ی هر فصل، با کد: ابرها می‌روند، علف تاب می‌خورد، آسیاب می‌چرخد، ستاره‌ها
/// چشمک می‌زنند، نورهای صحنه می‌چرخند و ماشین‌ها از خیابان رد می‌شوند. وسط صحنه خلوت می‌ماند تا
/// بازی روی آن دیده شود.
typedef BackdropPainter = void Function(Pen k, Size s, double t);

const _palette = [Color(0xFFF44336), Color(0xFFFF9800), Color(0xFFFFEB3B), Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFF9C27B0)];

void _sky(Pen k, Size s, List<Color> colors) => k.c.drawRect(
  Offset.zero & s,
  Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors).createShader(Offset.zero & s),
);

void _cloud(Pen k, double x, double y, double u, [double a = .95]) {
  final p = Paint()..color = Colors.white.withValues(alpha: a);
  k.c.drawCircle(Offset(x, y), u, p);
  k.c.drawCircle(Offset(x + u * 1.1, y + u * .25), u * .8, p);
  k.c.drawCircle(Offset(x - u * 1.1, y + u * .3), u * .7, p);
  k.c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - u * 1.8, y, u * 3.6, u * .9), Radius.circular(u * .45)), p);
}

/// ابرهایی که آرام از یک طرف به طرف دیگر می‌روند و دوباره برمی‌گردند.
void _clouds(Pen k, Size s, double t, {int n = 4, double top = .04, double band = .22}) {
  final u = s.shortestSide * .055;
  for (var i = 0; i < n; i++) {
    final speed = 6 + i * 3.0;
    final span = s.width + u * 8;
    final x = (i * span / n + t * speed) % span - u * 4;
    _cloud(k, x, s.height * (top + band * ((i * .37) % 1)), u * (.7 + (i % 3) * .2));
  }
}

void _sun(Pen k, Size s, double t, Offset at) {
  final r = s.shortestSide * .07;
  k.c.save();
  k.c.translate(at.dx, at.dy);
  k.c.rotate(t * .15);
  final ray = Paint()..color = const Color(0x55FFE082);
  for (var i = 0; i < 12; i++) {
    k.c.rotate(math.pi / 6);
    k.c.drawPath(
      Path()
        ..moveTo(-r * .18, r * 1.2)
        ..lineTo(r * .18, r * 1.2)
        ..lineTo(0, r * (2 + math.sin(t * 2 + i) * .2))
        ..close(),
      ray,
    );
  }
  k.c.restore();
  k.glow(at.dx, at.dy, r * 2.2, const Color(0xFFFFE082), .5);
  k.c.drawCircle(at, r, Paint()..color = const Color(0xFFFFD43B));
}

/// تپه‌های سبز با علف‌هایی که در باد خم می‌شوند.
void _hills(Pen k, Size s, double t, {double y = .72, Color far = const Color(0xFFA5D6A7), Color near = const Color(0xFF81C784)}) {
  final w = s.width, h = s.height;
  final back = Path()..moveTo(0, h * (y - .06));
  for (var x = 0.0; x <= w; x += w / 24) {
    back.lineTo(x, h * (y - .06) - math.sin(x / w * math.pi * 2.2 + .8) * h * .035);
  }
  back
    ..lineTo(w, h)
    ..lineTo(0, h)
    ..close();
  k.c.drawPath(back, Paint()..color = far);
  final front = Path()..moveTo(0, h * y);
  for (var x = 0.0; x <= w; x += w / 24) {
    front.lineTo(x, h * y - math.sin(x / w * math.pi * 1.6) * h * .03);
  }
  front
    ..lineTo(w, h)
    ..lineTo(0, h)
    ..close();
  k.c.drawPath(front, Paint()..color = near);
  _grass(k, s, t, h * y + h * .01, shade(near, .15));
}

void _grass(Pen k, Size s, double t, double y, Color c) {
  final rnd = math.Random(4);
  final p = Paint()
    ..color = c
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 40; i++) {
    final x = rnd.nextDouble() * s.width;
    final yy = y + rnd.nextDouble() * s.height * .2;
    final sway = math.sin(t * 1.6 + x * .02) * 4;
    final hh = 8 + rnd.nextDouble() * 8;
    k.c.drawLine(Offset(x, yy), Offset(x + sway, yy - hh), p);
    k.c.drawLine(Offset(x + 3, yy), Offset(x + 3 + sway * .8, yy - hh * .7), p);
  }
}

void _flowers(Pen k, Size s, double t, double y, {int n = 9}) {
  final rnd = math.Random(9);
  for (var i = 0; i < n; i++) {
    final x = (i + .5) / n * s.width + (rnd.nextDouble() - .5) * 30;
    final yy = y + rnd.nextDouble() * s.height * .12;
    final sway = math.sin(t * 1.3 + i) * .12;
    k.at(x, yy, () {
      k.stroke([Offset.zero, const Offset(0, -18)], const Color(0xFF558B2F), 2.4);
      for (var j = 0; j < 5; j++) {
        final a = j / 5 * math.pi * 2;
        k.c.drawCircle(Offset(math.cos(a) * 5, -18 + math.sin(a) * 5), 4, Paint()..color = _palette[i % 6]);
      }
      k.c.drawCircle(const Offset(0, -18), 3, Paint()..color = const Color(0xFFFFF59D));
    }, rot: sway);
  }
}

void _butterflies(Pen k, Size s, double t, {int n = 2}) {
  for (var i = 0; i < n; i++) {
    final x = s.width * (.2 + .6 * ((math.sin(t * .17 + i * 2) + 1) / 2));
    final y = s.height * (.45 + .12 * math.sin(t * .4 + i * 3));
    final flap = math.sin(t * 14 + i).abs();
    final c = _palette[(i * 2 + 1) % 6];
    k.at(x, y, () {
      for (final sx in <double>[-1, 1]) {
        k.c.drawOval(
          Rect.fromCenter(center: Offset(sx * 6 * flap, -3), width: 11 * flap + 1, height: 12),
          Paint()..color = c.withValues(alpha: .9),
        );
        k.c.drawOval(Rect.fromCenter(center: Offset(sx * 4 * flap, 5), width: 8 * flap + 1, height: 8), Paint()..color = tint(c, .2));
      }
      k.c.drawOval(Rect.fromCenter(center: Offset.zero, width: 3, height: 12), Paint()..color = const Color(0xFF3E2723));
    });
  }
}

void _birds(Pen k, Size s, double t, {int n = 3, Color color = const Color(0xFF455A64)}) {
  for (var i = 0; i < n; i++) {
    final span = s.width + 80;
    final x = (t * (24 + i * 6) + i * span / n) % span - 40;
    final y = s.height * (.12 + i * .05) + math.sin(t * 2 + i) * 6;
    final f = math.sin(t * 8 + i) * 5;
    k.stroke([Offset(x - 9, y - f), Offset(x, y), Offset(x + 9, y - f)], color, 2.2, smooth: false);
  }
}

void _stars(Pen k, Size s, double t, {int n = 50, double band = .55}) {
  final rnd = math.Random(7);
  for (var i = 0; i < n; i++) {
    final o = Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * band);
    final tw = (math.sin(t * (1 + rnd.nextDouble() * 2) + i) + 1) / 2;
    k.c.drawCircle(o, .6 + tw * 1.8, Paint()..color = Colors.white.withValues(alpha: .4 + tw * .6));
  }
}

void _fireflies(Pen k, Size s, double t, {int n = 12}) {
  for (var i = 0; i < n; i++) {
    final x = s.width * ((i * .618 + math.sin(t * .2 + i) * .06) % 1);
    final y = s.height * (.45 + .4 * ((i * .37 + math.cos(t * .25 + i * 1.3) * .05) % 1));
    final g = (math.sin(t * 2 + i * 1.7) + 1) / 2;
    k.glow(x, y, 10 + g * 6, const Color(0xFFEEFF41), .25 + g * .45);
    k.c.drawCircle(Offset(x, y), 1.6, Paint()..color = const Color(0xFFF4FF81));
  }
}

/// دیوار داخلی با کاغذ دیواری راه‌راه و قرنیز.
void _room(Pen k, Size s, Color wall, Color stripe, Color floor) {
  k.c.drawRect(Offset.zero & s, Paint()..color = wall);
  final p = Paint()..color = stripe;
  for (var x = 0.0; x < s.width; x += 46) {
    k.c.drawRect(Rect.fromLTWH(x, 0, 18, s.height * .72), p);
  }
  k.c.drawRect(Rect.fromLTWH(0, s.height * .72, s.width, s.height * .28), Paint()..color = floor);
  k.c.drawRect(Rect.fromLTWH(0, s.height * .7, s.width, s.height * .025), Paint()..color = shade(floor, .2));
  final board = Paint()..color = shade(floor, .08);
  for (var x = 0.0; x < s.width; x += 70) {
    k.c.drawLine(Offset(x, s.height * .725), Offset(x - 30, s.height), board..strokeWidth = 2);
  }
}

/// پنجره با آسمان زنده و ابرهای رونده.
void _window(Pen k, Size s, double t, Rect r, {bool night = false}) {
  k.c.save();
  k.c.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)));
  k.c.drawRect(
    r,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: night ? const [Color(0xFF1A237E), Color(0xFF3949AB)] : const [Color(0xFF81D4FA), Color(0xFFE1F5FE)],
      ).createShader(r),
  );
  if (night) {
    final rnd = math.Random(2);
    for (var i = 0; i < 12; i++) {
      final tw = (math.sin(t * 2 + i) + 1) / 2;
      k.c.drawCircle(
        r.topLeft + Offset(rnd.nextDouble() * r.width, rnd.nextDouble() * r.height * .7),
        .8 + tw * 1.4,
        Paint()..color = Colors.white,
      );
    }
    k.c.drawCircle(r.topLeft + Offset(r.width * .72, r.height * .3), r.shortestSide * .12, Paint()..color = const Color(0xFFFFE082));
  } else {
    for (var i = 0; i < 2; i++) {
      final x = r.left + (t * (10 + i * 5) + i * r.width * .6) % (r.width + 80) - 40;
      _cloud(k, x, r.top + r.height * (.25 + i * .25), r.shortestSide * .09);
    }
    k.c.drawOval(
      Rect.fromLTWH(r.left - 20, r.bottom - r.height * .25, r.width + 40, r.height * .5),
      Paint()..color = const Color(0xFF9CCC65),
    );
  }
  k.c.restore();
  final frame = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8;
  k.c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), frame);
  k.c.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom), frame..strokeWidth = 5);
  k.c.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.center.dy), frame);
  // پرده‌هایی که آرام تکان می‌خورند
  for (final side in <double>[-1, 1]) {
    final x = side < 0 ? r.left - 14 : r.right + 14;
    final sway = math.sin(t * .8 + side) * 4;
    k.c.drawPath(
      Path()
        ..moveTo(x - 16, r.top - 10)
        ..lineTo(x + 16, r.top - 10)
        ..quadraticBezierTo(x + 10 + sway, r.center.dy, x + 14 + sway * 1.5, r.bottom + 14)
        ..lineTo(x - 14 + sway * 1.5, r.bottom + 14)
        ..quadraticBezierTo(x - 10 + sway, r.center.dy, x - 16, r.top - 10)
        ..close(),
      Paint()..color = const Color(0xFFF48FB1),
    );
  }
}

void _shelf(Pen k, double x, double y, double w, List<Color> jars, double t) {
  k.rect(x, y, w, 10, 3, const Color(0xFFA1704A));
  for (var i = 0; i < jars.length; i++) {
    final jx = x + 10 + i * (w - 20) / jars.length;
    k.rect(jx, y - 30, 22, 30, 6, jars[i]);
    k.rect(jx + 2, y - 36, 18, 7, 3, const Color(0xFFA1704A));
  }
}

void _bunting(Pen k, Size s, double t, double y) {
  final sag = s.height * .04;
  k.stroke([Offset(0, y), Offset(s.width / 2, y + sag + math.sin(t) * 3), Offset(s.width, y)], const Color(0xFF8D6E63), 2);
  final n = (s.width / 34).floor();
  for (var i = 0; i < n; i++) {
    final x = (i + .5) * s.width / n;
    final yy = y + math.sin(x / s.width * math.pi) * (sag + math.sin(t) * 3);
    final f = math.sin(t * 2 + i) * 3;
    k.poly([Offset(x - 11, yy), Offset(x + 11, yy), Offset(x + f, yy + 22)], _palette[i % 6]);
  }
}

void _house(Pen k, double x, double y, double w, Color c, Color roof, double t, int seed) {
  final h = w * 1.1;
  k.rect(x, y - h, w, h, 4, c);
  k.poly([Offset(x - 6, y - h + 2), Offset(x + w / 2, y - h - w * .55), Offset(x + w + 6, y - h + 2)], roof);
  final lit = (math.sin(t * .4 + seed) + 1) / 2 > .5;
  for (var r = 0; r < 2; r++) {
    for (var col = 0; col < 2; col++) {
      k.rect(
        x + w * (.14 + col * .44),
        y - h + h * (.14 + r * .36),
        w * .3,
        h * .22,
        2,
        lit && (r + col + seed).isEven ? const Color(0xFFFFF59D) : const Color(0xFF81D4FA),
      );
    }
  }
}

void _tree(Pen k, double x, double y, double s, double t, {Color c = const Color(0xFF66BB6A)}) {
  k.rect(x - s * .08, y - s * .5, s * .16, s * .5, 3, const Color(0xFF8D6E63));
  k.at(x, y - s * .5, () {
    k.circle(0, -s * .2, s * .32, c);
    k.circle(-s * .22, s * .02, s * .24, shade(c, .08));
    k.circle(s * .22, s * .02, s * .24, shade(c, .04));
    k.shine(-s * .12, -s * .32, s * .08, s * .05);
  }, rot: math.sin(t * .9 + x) * .04);
}

void _windmill(Pen k, double x, double y, double s, double t) {
  k.poly([
    Offset(x - s * .18, y),
    Offset(x - s * .1, y - s * .8),
    Offset(x + s * .1, y - s * .8),
    Offset(x + s * .18, y),
  ], const Color(0xFFFFF3E0));
  k.at(x, y - s * .8, () {
    for (var i = 0; i < 4; i++) {
      k.at(0, 0, () => k.rect(-s * .05, -s * .55, s * .1, s * .5, 3, const Color(0xFFD7CCC8)), rot: i * math.pi / 2);
    }
    k.circle(0, 0, s * .06, const Color(0xFF8D6E63));
  }, rot: t * 1.2);
}

final Map<String, BackdropPainter> backdrops = {
  'meadow': (k, s, t) {
    _sky(k, s, const [Color(0xFF7CC8FF), Color(0xFFB9E3FF), Color(0xFFE8F6FF)]);
    _sun(k, s, t, Offset(s.width * .16, s.height * .1));
    _clouds(k, s, t);
    _birds(k, s, t, n: 2);
    _hills(k, s, t);
    _tree(k, s.width * .1, s.height * .72, s.shortestSide * .3, t);
    _windmill(k, s.width * .88, s.height * .68, s.shortestSide * .3, t);
    _flowers(k, s, t, s.height * .78);
    _butterflies(k, s, t);
  },
  'farm': (k, s, t) {
    _sky(k, s, const [Color(0xFF7CC8FF), Color(0xFFCDEBFF)]);
    _sun(k, s, t, Offset(s.width * .84, s.height * .09));
    _clouds(k, s, t, n: 3);
    _hills(k, s, t, y: .7, far: const Color(0xFFC5E1A5), near: const Color(0xFF9CCC65));
    // انبار قرمز
    final bx = s.width * .06, by = s.height * .7, bw = s.shortestSide * .3;
    k.rect(bx, by - bw * .8, bw, bw * .8, 4, const Color(0xFFE53935));
    k.poly([
      Offset(bx - 8, by - bw * .78),
      Offset(bx + bw / 2, by - bw * 1.25),
      Offset(bx + bw + 8, by - bw * .78),
    ], const Color(0xFFB71C1C));
    k.rect(bx + bw * .32, by - bw * .45, bw * .36, bw * .45, 2, Colors.white);
    _windmill(k, s.width * .9, s.height * .68, s.shortestSide * .32, t);
    // نرده
    for (var x = 0.0; x < s.width; x += 26) {
      k.rect(x, s.height * .8, 8, s.height * .07, 2, const Color(0xFFFFF8E1));
    }
    k.rect(0, s.height * .815, s.width, 6, 2, const Color(0xFFFFF8E1));
    _flowers(k, s, t, s.height * .86, n: 6);
    _butterflies(k, s, t, n: 2);
    _birds(k, s, t, n: 2);
  },
  'kitchen': (k, s, t) {
    _room(k, s, const Color(0xFFFFF3E0), const Color(0xFFFFE8CC), const Color(0xFFD7A86E));
    _window(k, s, t, Rect.fromCenter(center: Offset(s.width * .5, s.height * .2), width: s.width * .42, height: s.height * .2));
    _shelf(k, s.width * .04, s.height * .4, s.width * .26, const [Color(0xFFFFB74D), Color(0xFF81C784), Color(0xFFE57373)], t);
    _shelf(k, s.width * .7, s.height * .4, s.width * .26, const [Color(0xFF64B5F6), Color(0xFFFFD54F)], t);
    // ملاقه‌های آویزان که تاب می‌خورند
    for (var i = 0; i < 3; i++) {
      final x = s.width * (.08 + i * .07);
      k.at(x, s.height * .08, () {
        k.stroke([Offset.zero, const Offset(0, 40)], const Color(0xFF8D6E63), 3);
        k.oval(0, 48, 9, 9, const Color(0xFFB0BEC5));
      }, rot: math.sin(t * 1.2 + i) * .08);
    }
    // کتری روی قفسه‌ی راست، بالای سر شخصیت‌ها، که بخار می‌کند
    final kx = s.width * .9, ky = s.height * .4;
    k.circle(kx, ky - 14, 14, const Color(0xFFE53935));
    k.rect(kx - 4, ky - 32, 8, 6, 3, const Color(0xFF424242));
    k.stroke([Offset(kx + 12, ky - 18), Offset(kx + 22, ky - 26)], const Color(0xFFE53935), 4);
    k.steam(kx + 22, ky - 30, ToonPose(t), h: 30);
  },
  'workshop': (k, s, t) {
    _room(k, s, const Color(0xFFD7B98E), const Color(0xFFCBA978), const Color(0xFF8D6E63));
    // تخته‌ی ابزار با ابزارهای آویزان
    final board = Rect.fromLTWH(s.width * .06, s.height * .08, s.width * .36, s.height * .24);
    k.rect(board.left, board.top, board.width, board.height, 8, const Color(0xFFBCAAA4));
    for (var i = 0; i < 4; i++) {
      final x = board.left + board.width * (.15 + i * .23);
      k.at(x, board.top + 14, () {
        k.c.drawCircle(Offset.zero, 3, Paint()..color = const Color(0xFF5D4037));
        if (i.isEven) {
          k.rect(-3, 4, 6, 40, 3, const Color(0xFFC68B4E));
          k.rect(-12, 40, 24, 10, 3, const Color(0xFF78909C));
        } else {
          k.rect(-3, 4, 6, 44, 3, const Color(0xFFB0BEC5));
          k.circle(0, 50, 8, const Color(0xFFB0BEC5));
        }
      }, rot: math.sin(t * 1.1 + i * 1.7) * .07);
    }
    // چرخ‌دنده‌های چرخان
    for (final (i, (x, y, r)) in [(s.width * .8, s.height * .16, 34.0), (s.width * .8 + 50, s.height * .16 + 34, 22.0)].indexed) {
      k.at(x, y, () {
        for (var j = 0; j < 10; j++) {
          k.at(0, 0, () => k.rect(-5, -r - 6, 10, 12, 2, const Color(0xFF90A4AE)), rot: j * math.pi / 5);
        }
        k.circle(0, 0, r, const Color(0xFFB0BEC5));
        k.circle(0, 0, r * .3, const Color(0xFF78909C));
      }, rot: t * (i.isEven ? .6 : -.6 * 34 / 22));
    }
    _window(k, s, t, Rect.fromLTWH(s.width * .56, s.height * .34, s.width * .3, s.height * .14));
    k.rect(s.width * .02, s.height * .62, s.width * .4, s.height * .03, 4, const Color(0xFFA1704A));
  },
  'studio': (k, s, t) {
    _room(k, s, const Color(0xFFF3E5F5), const Color(0xFFEDE0F2), const Color(0xFFBCAAA4));
    final rnd = math.Random(5);
    for (var i = 0; i < 9; i++) {
      final o = Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * .6);
      final r = 10 + rnd.nextDouble() * 16 + math.sin(t + i) * 1.5;
      k.c.drawCircle(o, r, Paint()..color = _palette[i % 6].withValues(alpha: .35));
    }
    _window(k, s, t, Rect.fromCenter(center: Offset(s.width * .5, s.height * .18), width: s.width * .36, height: s.height * .18));
    // سه‌پایه‌ی نقاشی
    final ex = s.width * .86, ey = s.height * .7;
    k.stroke([Offset(ex - 30, ey), Offset(ex, ey - 120)], const Color(0xFF8D6E63), 5);
    k.stroke([Offset(ex + 30, ey), Offset(ex, ey - 120)], const Color(0xFF8D6E63), 5);
    k.rect(ex - 36, ey - 110, 72, 60, 4, Colors.white);
    for (var i = 0; i < 3; i++) {
      final g = ((t * .5 + i * .33) % 1);
      k.c.drawCircle(Offset(ex - 18 + i * 18, ey - 80), 8 * math.min(1, g * 3), Paint()..color = _palette[i * 2]);
    }
    _bunting(k, s, t, s.height * .03);
  },
  'night_forest': (k, s, t) {
    _sky(k, s, const [Color(0xFF0D1333), Color(0xFF1B2470), Color(0xFF3549B8)]);
    _stars(k, s, t);
    final m = Offset(s.width * .8, s.height * .12);
    final r = s.shortestSide * .08;
    k.glow(m.dx, m.dy, r * 3, const Color(0xFFFFF59D), .35);
    k.c.drawCircle(m, r, Paint()..color = const Color(0xFFFFE27A));
    k.c.drawCircle(m + Offset(r * .45, -r * .2), r * .85, Paint()..color = const Color(0xFF1B2470));
    _hills(k, s, t, y: .74, far: const Color(0xFF1B5E20), near: const Color(0xFF2E7D32));
    for (var i = 0; i < 6; i++) {
      final x = s.width * (i / 5);
      final h = s.shortestSide * (.35 + (i % 3) * .08);
      k.at(x, s.height * .76, () {
        for (var j = 0; j < 3; j++) {
          k.poly([
            Offset(-h * .3 + j * h * .05, -j * h * .25),
            Offset(0, -h * .45 - j * h * .25),
            Offset(h * .3 - j * h * .05, -j * h * .25),
          ], const Color(0xFF1B5E20));
        }
      }, rot: math.sin(t * .6 + i) * .02);
    }
    _fireflies(k, s, t);
  },
  'stage': (k, s, t) {
    k.c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF311B92));
    for (var i = 0; i < 4; i++) {
      final sweep = math.sin(t * .7 + i * 1.3) * .35;
      final top = Offset(s.width * (.2 + i * .2), 0);
      k.c.save();
      k.c.translate(top.dx, top.dy);
      k.c.rotate(sweep);
      k.c.drawPath(
        Path()
          ..moveTo(-8, 0)
          ..lineTo(8, 0)
          ..lineTo(s.width * .14, s.height * .75)
          ..lineTo(-s.width * .14, s.height * .75)
          ..close(),
        Paint()..color = _palette[(i * 2 + 1) % 6].withValues(alpha: .18),
      );
      k.c.restore();
    }
    // پرده‌ها
    for (final side in <double>[-1, 1]) {
      final x = side < 0 ? 0.0 : s.width;
      final sway = math.sin(t * .6) * 6;
      k.c.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo(x - side * s.width * .2, 0)
          ..quadraticBezierTo(x - side * (s.width * .12 + sway), s.height * .35, x - side * s.width * .08, s.height * .72)
          ..lineTo(x, s.height * .72)
          ..close(),
        Paint()..color = const Color(0xFFC2185B),
      );
    }
    k.c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height * .05), Paint()..color = const Color(0xFFAD1457));
    k.rect(-10, s.height * .72, s.width + 20, s.height * .3, 0, const Color(0xFFA1704A), line: false);
    for (var i = 0; i < 14; i++) {
      final d = (t * .25 + i * .07) % 1;
      final x = s.width * ((i * .37) % 1);
      k.at(x + math.sin(d * 9 + i) * 10, d * s.height * .7, () => k.rect(-3, -1.5, 6, 3, 1, _palette[i % 6], line: false), rot: d * 12 + i);
    }
  },
  'city': (k, s, t) {
    _sky(k, s, const [Color(0xFF7CC8FF), Color(0xFFE1F5FE)]);
    _sun(k, s, t, Offset(s.width * .14, s.height * .09));
    _clouds(k, s, t, n: 3);
    final base = s.height * .62;
    final w = s.width / 6;
    for (var i = 0; i < 6; i++) {
      _house(k, i * w + 4, base, w - 8, _palette[(i * 5) % 6].withValues(alpha: 1), const Color(0xFFD84315), t, i);
    }
    k.rect(-4, base, s.width + 8, s.height * .06, 0, const Color(0xFF9CCC65), line: false);
    // رودخانه با موج
    final ry = base + s.height * .06;
    final river = Path()..moveTo(0, ry);
    for (var x = 0.0; x <= s.width; x += 10) {
      river.lineTo(x, ry + math.sin(x / 30 + t * 2) * 3);
    }
    river
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    k.c.drawPath(river, Paint()..color = const Color(0xFF4FC3F7));
    for (var i = 0; i < 6; i++) {
      final x = (i * s.width / 6 + t * 18) % s.width;
      k.stroke([Offset(x, ry + 30 + (i % 3) * 22.0), Offset(x + 18, ry + 30 + (i % 3) * 22.0)], Colors.white.withValues(alpha: .6), 2);
    }
    // ماشینی که از خیابان بالای رود رد می‌شود
    final cx = (t * 60) % (s.width + 120) - 60;
    k.at(cx, base - 4, () {
      k.rect(-24, -18, 48, 14, 6, const Color(0xFFE53935));
      k.rect(-14, -28, 26, 12, 5, const Color(0xFFE53935));
      k.wheel(-14, -4, 6, t * 8);
      k.wheel(14, -4, 6, t * 8);
    });
    _birds(k, s, t, n: 2);
  },
  'festival': (k, s, t) {
    _sky(k, s, const [Color(0xFFFF8A65), Color(0xFFFFCC80), Color(0xFFFFF3E0)]);
    _bunting(k, s, t, s.height * .05);
    _bunting(k, s, t + 1, s.height * .16);
    // بادکنک‌هایی که بالا می‌روند
    for (var i = 0; i < 6; i++) {
      final d = (t * .05 + i / 6) % 1;
      final x = s.width * ((i * .29 + .1) % 1) + math.sin(t + i) * 10;
      final y = s.height * (1.05 - d * 1.2);
      k.stroke([Offset(x, y + 18), Offset(x + math.sin(t * 2 + i) * 4, y + 40)], const Color(0xFF9E9E9E), 1);
      k.oval(x, y, 13, 16, _palette[i % 6]);
      k.shine(x - 5, y - 6, 3, 5);
    }
    _hills(k, s, t, y: .76, far: const Color(0xFFAED581), near: const Color(0xFF8BC34A));
    for (var i = 0; i < 4; i++) {
      final x = s.width * (.1 + i * .27);
      k.at(x, s.height * .3, () {
        k.stroke([const Offset(0, -20), Offset.zero], const Color(0xFF5D4037), 1.4);
        k.glow(0, 16, 26, const Color(0xFFFFCC80), .5 + math.sin(t * 2 + i) * .1);
        k.oval(0, 16, 14, 16, _palette[(i * 2) % 6]);
      }, rot: math.sin(t + i) * .1);
    }
  },
  'playroom': (k, s, t) {
    _room(k, s, const Color(0xFFE3F2FD), const Color(0xFFD6EAFB), const Color(0xFFFFCC80));
    _window(k, s, t, Rect.fromCenter(center: Offset(s.width * .5, s.height * .18), width: s.width * .4, height: s.height * .18));
    // قفسه‌ی اسباب‌بازی با توپی که می‌پرد
    k.rect(s.width * .04, s.height * .44, s.width * .3, 10, 3, const Color(0xFFA1704A));
    final bounce = (math.sin(t * 3)).abs() * 20;
    k.circle(s.width * .12, s.height * .44 - 14 - bounce, 13, const Color(0xFFE53935));
    k.rect(s.width * .2, s.height * .44 - 30, 26, 30, 4, const Color(0xFF42A5F5));
    _bunting(k, s, t, s.height * .02);
  },
  'shop': (k, s, t) {
    _room(k, s, const Color(0xFFFFF8E1), const Color(0xFFFFF0C2), const Color(0xFFBCAAA4));
    // سایبان راه‌راه که تاب می‌خورد
    final n = (s.width / 40).ceil();
    for (var i = 0; i < n; i++) {
      final f = math.sin(t * 1.4 + i * .5) * 3;
      k.c.drawPath(
        Path()
          ..moveTo(i * 40.0, 0)
          ..lineTo(i * 40.0 + 40, 0)
          ..lineTo(i * 40.0 + 40, s.height * .07)
          ..quadraticBezierTo(i * 40.0 + 20, s.height * .1 + f, i * 40.0, s.height * .07)
          ..close(),
        Paint()..color = i.isEven ? const Color(0xFFE53935) : Colors.white,
      );
    }
    _shelf(k, s.width * .05, s.height * .32, s.width * .4, const [
      Color(0xFF81C784),
      Color(0xFFFFB74D),
      Color(0xFF64B5F6),
      Color(0xFFE57373),
    ], t);
    _shelf(k, s.width * .55, s.height * .32, s.width * .4, const [
      Color(0xFFBA68C8),
      Color(0xFFFFD54F),
      Color(0xFF4DB6AC),
      Color(0xFFF06292),
    ], t);
    final sp = (t * .7) % 1;
    k.star(s.width * (.2 + sp * .6), s.height * .18, 6 * math.sin(sp * math.pi), const Color(0xFFFFEB3B), line: false);
  },
  'star_workshop': (k, s, t) {
    _sky(k, s, const [Color(0xFF1A237E), Color(0xFF4A148C), Color(0xFF6A1B9A)]);
    _stars(k, s, t, n: 70, band: .8);
    for (var i = 0; i < 2; i++) {
      final d = (t * .12 + i * .5) % 1;
      final o = Offset(s.width * (1.1 - d * 1.3), s.height * (.05 + d * .3 + i * .1));
      k.stroke([o, o + const Offset(40, -14)], Colors.white.withValues(alpha: .6 * (1 - d)), 2);
      k.star(o.dx, o.dy, 5, const Color(0xFFFFF59D), line: false);
    }
    k.rect(-10, s.height * .74, s.width + 20, s.height * .3, 0, const Color(0xFF4527A0), line: false);
    final glow = (math.sin(t * 1.5) + 1) / 2;
    k.glow(s.width * .5, s.height * .74, s.width * .4, const Color(0xFFFFE082), .15 + glow * .1);
  },
};

/// پس‌زمینه‌ی زنده‌ی [id] که تمام صفحه را پر می‌کند.
class LiveBackdrop extends StatefulWidget {
  const LiveBackdrop(this.id, {super.key});

  final String id;

  @override
  State<LiveBackdrop> createState() => _LiveBackdropState();
}

class _LiveBackdropState extends State<LiveBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 120));
  int _laps = 0;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _laps++;
        _c.forward(from: 0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(painter: _BackdropCanvas(backdrops[widget.id]!, () => (_laps + _c.value) * 120, _c), size: Size.infinite),
  );
}

class _BackdropCanvas extends CustomPainter {
  _BackdropCanvas(this.painter, this.time, Listenable repaint) : super(repaint: repaint);

  final BackdropPainter painter;
  final double Function() time;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    painter(Pen(canvas), size, time());
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BackdropCanvas old) => old.painter != painter;
}
