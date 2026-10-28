import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../ui/clay.dart';
import '../../ui/fx.dart';

/// وسایل صحنه که با کد کشیده می‌شوند و در چند بازی تکرار می‌شوند: درخت، سبد، سطل، نوار نقاله، قابلمه.

/// تاج درخت (یا بوته) با تنه؛ چیزهای چیدنی رویش می‌نشینند.
class TreeProp extends StatelessWidget {
  const TreeProp({super.key, required this.size, this.bush = false});

  final Size size;
  final bool bush;

  @override
  Widget build(BuildContext context) => CustomPaint(size: size, painter: _TreePainter(bush));
}

class _TreePainter extends CustomPainter {
  _TreePainter(this.bush);

  final bool bush;

  @override
  void paint(Canvas canvas, Size s) {
    if (!bush) {
      final trunk = RRect.fromRectAndRadius(Rect.fromLTWH(s.width * .44, s.height * .55, s.width * .12, s.height * .45), const Radius.circular(12));
      canvas.drawRRect(trunk, Paint()..color = const Color(0xFF8D6E63));
      canvas.drawRRect(trunk.deflate(4), Paint()..color = const Color(0xFFA1887F));
    }
    final dark = Paint()..color = const Color(0xFF43A047);
    final mid = Paint()..color = const Color(0xFF66BB6A);
    final light = Paint()..color = const Color(0xFF9CCC65);
    final cy = bush ? s.height * .62 : s.height * .36;
    final ry = bush ? s.height * .36 : s.height * .34;
    for (final (dx, dy, r, p) in [
      (-.32, .1, .28, dark),
      (.32, .1, .28, dark),
      (0.0, -.1, .34, mid),
      (-.2, -.05, .26, mid),
      (.2, -.05, .26, mid),
      (-.12, -.22, .2, light),
      (.14, -.2, .18, light),
    ]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(s.width * (.5 + dx), cy + ry * dy * 2), width: s.width * r * 2, height: ry * r * 4.2), p);
    }
  }

  @override
  bool shouldRepaint(_TreePainter old) => false;
}

/// سبد حصیری که چیزهای جمع‌شده رویش روی هم می‌نشینند و با هر دانه‌ی تازه کمی له و کش می‌شود.
class BasketProp extends StatelessWidget {
  const BasketProp({super.key, required this.width, required this.items, this.bump = 0, this.label});

  final double width;
  final List<String> items;
  final int bump;
  final String? label;

  @override
  Widget build(BuildContext context) => Squash(
    trigger: bump,
    child: SizedBox(
      width: width,
      height: width * .78,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // دانه‌ها روی هم، کمی بالاتر از لبه
          for (final (i, id) in items.indexed)
            Positioned(
              bottom: width * .32 + (i ~/ 4) * width * .12,
              left: width * (.12 + (i % 4) * .17) + ((i ~/ 4).isOdd ? width * .08 : 0),
              child: GameArt(id, size: width * .26),
            ),
          CustomPaint(size: Size(width, width * .5), painter: _BasketPainter()),
          if (label != null)
            Positioned(
              bottom: width * .14,
              child: Text(label!, style: PText.title.copyWith(color: Colors.white, fontSize: width * .16)),
            ),
        ],
      ),
    ),
  );
}

class _BasketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final body = Path()
      ..moveTo(0, s.height * .1)
      ..lineTo(s.width, s.height * .1)
      ..lineTo(s.width * .88, s.height)
      ..lineTo(s.width * .12, s.height)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFC68B4E));
    final weave = Paint()
      ..color = const Color(0xFFA86F38)
      ..strokeWidth = 4;
    for (var y = s.height * .3; y < s.height; y += s.height * .22) {
      canvas.drawLine(Offset(s.width * .06, y), Offset(s.width * .94, y), weave);
    }
    for (var x = s.width * .15; x < s.width * .9; x += s.width * .12) {
      canvas.drawLine(Offset(x, s.height * .12), Offset(x + (x - s.width / 2) * -.1, s.height), weave..strokeWidth = 3);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-4, 0, s.width + 8, s.height * .2), const Radius.circular(10)),
      Paint()..color = const Color(0xFFD9A35B),
    );
  }

  @override
  bool shouldRepaint(_BasketPainter old) => false;
}

/// سطل/سبد مقصد برای جدا کردن، با رنگ و نماد.
class BinProp extends StatelessWidget {
  const BinProp({super.key, required this.label, required this.color, required this.icon, this.bump = 0, this.highlight = false, this.glow = false});

  final String label;
  final Color color;
  final IconData icon;
  final int bump;
  final bool highlight;
  final bool glow;

  @override
  Widget build(BuildContext context) => Squash(
    trigger: bump,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 140,
      height: 118,
      decoration: BoxDecoration(
        color: highlight ? G.tint(color, .3) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(34)),
        border: Border.all(color: color, width: 6),
        boxShadow: [...G.soft(), if (glow) const BoxShadow(color: Color(0xEEFFE066), blurRadius: 26, spreadRadius: 6)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 46),
          Text(label, style: PText.heading.copyWith(color: color)),
        ],
      ),
    ),
  );
}

/// قفسه‌ی چوبی پایین صحنه برای چیزهایی که کودک برمی‌دارد.
class ShelfProp extends StatelessWidget {
  const ShelfProp({super.key, required this.child, this.height = 112});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE0B07A), Color(0xFFC68B4E)]),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFA86F38), width: 4),
      boxShadow: G.soft(),
    ),
    child: child,
  );
}

/// مایع با سطح موج‌دار (لیوان، کاسه، باک) که با [level] بالا می‌آید.
class LiquidPainter extends CustomPainter {
  LiquidPainter({required this.level, required this.color, required this.phase, this.radius = 24});

  final double level;
  final Color color;
  final double phase;
  final double radius;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndCorners(Offset.zero & s, bottomLeft: Radius.circular(radius), bottomRight: Radius.circular(radius), topLeft: const Radius.circular(8), topRight: const Radius.circular(8)));
    final top = s.height * (1 - level);
    final p = Path()..moveTo(0, s.height);
    for (var x = 0.0; x <= s.width; x += 6) {
      p.lineTo(x, top + math.sin(x / s.width * math.pi * 3 + phase) * 4 * (level > .02 ? 1 : 0));
    }
    p
      ..lineTo(s.width, s.height)
      ..close();
    canvas.drawPath(p, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [G.tint(color, .12), color]).createShader(Offset.zero & s));
    // برق سطح
    canvas.drawLine(
      Offset(s.width * .15, top + 6),
      Offset(s.width * .4, top + 6),
      Paint()
        ..color = Colors.white.withValues(alpha: .5)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(LiquidPainter old) => old.level != level || old.phase != phase;
}

/// گرداب درون قابلمه یا کاسه هنگام هم زدن.
class SwirlPainter extends CustomPainter {
  SwirlPainter({required this.angle, required this.color, required this.strength});

  final double angle;
  final Color color;
  final double strength;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final p = Paint()
      ..color = color.withValues(alpha: .55 * strength)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 3; k++) {
      final path = Path();
      for (var t = 0.0; t < 1; t += .02) {
        final a = angle + k * math.pi * 2 / 3 + t * math.pi * 2.2;
        final r = s.width * .42 * t;
        final o = c + Offset(math.cos(a) * r, math.sin(a) * r * .55);
        t == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(SwirlPainter old) => old.angle != angle || old.strength != strength;
}
